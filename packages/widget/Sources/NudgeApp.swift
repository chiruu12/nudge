import Carbon
import SwiftUI

@main
struct NudgeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var hotkeyManager = HotkeyManager()
    var recorder = AudioRecorder()
    var viewModel = DashboardViewModel()
    var voiceController: VoiceController!
    var serverManager = ServerManager()
    var appController: AppController!
    var mainWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Proper desktop app: show a Dock icon and a main window, while the
        // menu-bar widget (status item + popover) remains available.
        NSApp.setActivationPolicy(.regular)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "mic.fill",
                accessibilityDescription: "Nudge"
            )
            button.image?.isTemplate = true
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        voiceController = VoiceController(
            recorder: recorder,
            viewModel: viewModel
        ) { [weak self] recording in
            self?.updateIcon(recording: recording)
        }

        appController = AppController(serverManager: serverManager, viewModel: viewModel)

        // Share one view model / polling loop / APIClient across both surfaces.
        let env = AppEnvironment.shared
        env.viewModel = viewModel
        env.voiceController = voiceController
        env.appController = appController
        env.recorder = recorder

        let dashboard = DashboardView(
            recorder: recorder,
            viewModel: viewModel,
            voiceController: voiceController,
            appController: appController
        )
        popover = NSPopover()
        popover.contentSize = NSSize(width: 640, height: 480)
        popover.behavior = .semitransient
        popover.contentViewController = NSHostingController(rootView: dashboard)
        popover.delegate = self

        recorder.requestPermission()

        hotkeyManager.register(
            id: 1,
            modifiers: UInt32(cmdKey | shiftKey),
            keyCode: UInt32(kVK_ANSI_Period)
        ) { [weak self] in
            DispatchQueue.main.async {
                NSLog("[Nudge] Command hotkey received")
                self?.voiceController.toggleVoiceCommand(source: "hotkey")
            }
        }

        hotkeyManager.register(
            id: 2,
            modifiers: UInt32(cmdKey | shiftKey),
            keyCode: UInt32(kVK_ANSI_Comma)
        ) { [weak self] in
            DispatchQueue.main.async {
                NSLog("[Nudge] Dictation hotkey received")
                self?.voiceController.toggleDictation(source: "hotkey")
            }
        }

        // Auto-start the Python backend if it isn't already up, then reflect status.
        serverManager.ensureServerRunning { [weak self] online in
            self?.viewModel.isBackendOnline = online
            Task {
                await self?.viewModel.refresh()
                // Existing users with a configured key skip onboarding.
                AppEnvironment.shared.adoptExistingConfigIfNeeded(self?.viewModel.configFull)
            }
        }

        // Open the main window as the app's home base.
        showMainWindow()
    }

    func applicationWillTerminate(_ notification: Notification) {
        serverManager.stopServerIfSpawned()
    }

    // Closing the main window keeps the menu-bar app alive.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // Clicking the Dock icon re-opens the main window.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        showMainWindow()
        return true
    }

    /// Create-or-raise the main window (hosts MainWindowView via SwiftUI).
    func showMainWindow() {
        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let root = MainWindowView().environmentObject(AppEnvironment.shared)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Nudge"
        window.contentViewController = NSHostingController(rootView: root)
        window.contentMinSize = NSSize(width: 900, height: 600)
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("NudgeMainWindow")
        mainWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // Left-click toggles the popover; right-click (or Control-click) opens a menu.
    @objc func statusItemClicked() {
        let event = NSApp.currentEvent
        let isRightClick = event?.type == .rightMouseUp
            || event?.modifierFlags.contains(.control) == true
        if isRightClick {
            showStatusMenu()
        } else {
            togglePopover()
        }
    }

    func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func showStatusMenu() {
        guard let button = statusItem.button else { return }
        let menu = NSMenu()

        menu.addItem(withTitle: "Open Nudge", action: #selector(openFromMenu), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Restart Backend",
            action: #selector(restartBackendFromMenu),
            keyEquivalent: ""
        )
        let launchItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLoginFromMenu),
            keyEquivalent: ""
        )
        launchItem.state = appController.launchAtLogin ? .on : .off
        menu.addItem(launchItem)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Nudge", action: #selector(quitFromMenu), keyEquivalent: "q")

        menu.items.forEach { $0.target = self }
        menu.popUp(
            positioning: nil,
            at: NSPoint(x: 0, y: button.bounds.height + 4),
            in: button
        )
    }

    @objc private func openFromMenu() {
        showMainWindow()
    }

    @objc private func restartBackendFromMenu() {
        appController.restartBackend()
    }

    @objc private func toggleLaunchAtLoginFromMenu() {
        appController.setLaunchAtLogin(!appController.launchAtLogin)
    }

    @objc private func quitFromMenu() {
        appController.quit()
    }

    func updateIcon(recording: Bool) {
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "mic.fill",
                accessibilityDescription: "Nudge"
            )
            button.image?.isTemplate = !recording
            button.contentTintColor = recording ? .systemRed : nil
        }
    }
}

extension AppDelegate: NSPopoverDelegate {
    func popoverWillClose(_ notification: Notification) {
        voiceController.cancelRecording(reason: "popover closed")
    }
}
