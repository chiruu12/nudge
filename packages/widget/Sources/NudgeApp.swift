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

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "mic.fill",
                accessibilityDescription: "Nudge"
            )
            button.image?.isTemplate = true
            button.action = #selector(togglePopover)
        }

        voiceController = VoiceController(
            recorder: recorder,
            viewModel: viewModel
        ) { [weak self] recording in
            self?.updateIcon(recording: recording)
        }

        let dashboard = DashboardView(
            recorder: recorder,
            viewModel: viewModel,
            voiceController: voiceController
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
    }

    @objc func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
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
