import AppKit
import Foundation
@preconcurrency import UserNotifications

/// Locates the pip-installed `nudge` CLI and auto-starts `nudge serve` if the
/// backend isn't already running. Only stops the server if this app spawned it.
@MainActor
final class ServerManager {
    /// Set if THIS app launched the server process (so we can stop it on quit).
    private(set) var spawnedProcess: Process?

    private let pollInterval: TimeInterval = 0.5
    private let bringUpTimeout: TimeInterval = 10.0

    /// The single in-flight bring-up. Guards against concurrent
    /// `ensureServerRunning`/`restartServer` calls spawning duplicate servers.
    private var bringUpTask: Task<Void, Never>?

    /// Common install locations for the `nudge` console script. A GUI app
    /// launched from /Applications has a minimal PATH, so probe these first.
    private static func candidatePaths() -> [String] {
        let home = NSHomeDirectory()
        return [
            "\(home)/.local/bin/nudge",  // pip --user / pipx default shims
            "\(home)/.local/pipx/venvs/nudge-ai/bin/nudge",
            "/opt/homebrew/bin/nudge",  // Apple Silicon Homebrew
            "/usr/local/bin/nudge",  // Intel Homebrew / system
            "\(home)/Library/Application Support/uv/tools/nudge-ai/bin/nudge",
            // conda / miniforge / miniconda / anaconda base envs
            "/opt/homebrew/Caskroom/miniforge/base/bin/nudge",
            "\(home)/miniforge3/bin/nudge",
            "\(home)/miniconda3/bin/nudge",
            "\(home)/anaconda3/bin/nudge",
            "/opt/miniconda3/bin/nudge",
            "/opt/anaconda3/bin/nudge",
        ]
    }

    /// Called from applicationDidFinishLaunching. Non-blocking. Concurrent calls
    /// are coalesced into the single in-flight bring-up so we never spawn two
    /// `nudge serve` processes (which would orphan one past app quit).
    func ensureServerRunning(updateOnline: @escaping @MainActor (Bool) -> Void) {
        // Check-and-set is synchronous on the main actor → atomic, no race.
        guard bringUpTask == nil else {
            NSLog("[Nudge Server] bring-up already in progress; coalescing request")
            return
        }
        bringUpTask = Task { [weak self] in
            await self?.bringUp(updateOnline: updateOnline)
            self?.bringUpTask = nil
        }
    }

    private func bringUp(updateOnline: @escaping @MainActor (Bool) -> Void) async {
        if await APIClient.shared.health() {
            NSLog("[Nudge Server] already running")
            updateOnline(true)
            return
        }

        guard let nudgePath = await Self.locateNudge() else {
            NSLog("[Nudge Server] nudge binary not found")
            updateOnline(false)
            notifyMissingPackage()
            return
        }

        NSLog("[Nudge Server] launching: \(nudgePath) serve")
        do {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: nudgePath)
            proc.arguments = ["serve", "--host", "127.0.0.1", "--port", "8000"]
            // Give the child a sane PATH so it can find python/uvicorn deps.
            var env = ProcessInfo.processInfo.environment
            let extra = "\(NSHomeDirectory())/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
            env["PATH"] = env["PATH"].map { "\(extra):\($0)" } ?? extra
            proc.environment = env
            try proc.run()
            spawnedProcess = proc
        } catch {
            NSLog("[Nudge Server] failed to launch: \(error.localizedDescription)")
            updateOnline(false)
            return
        }

        // Poll /health until up or timeout.
        let deadline = Date().addingTimeInterval(bringUpTimeout)
        while Date() < deadline {
            if await APIClient.shared.health() {
                NSLog("[Nudge Server] up")
                updateOnline(true)
                return
            }
            try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }
        NSLog("[Nudge Server] timed out waiting for /health")
        updateOnline(false)
    }

    /// Stop the server only if we started it.
    func stopServerIfSpawned() {
        guard let proc = spawnedProcess, proc.isRunning else { return }
        NSLog("[Nudge Server] terminating spawned server")
        proc.terminate()
        spawnedProcess = nil
    }

    /// Stop the server we manage (if any), then bring it back up. A pre-existing
    /// server we didn't spawn is left untouched — `bringUp` re-adopts it via the
    /// health check. If a bring-up is already running, this coalesces into it
    /// (claiming the same guard synchronously) so restarts never race.
    func restartServer(updateOnline: @escaping @MainActor (Bool) -> Void) {
        guard bringUpTask == nil else {
            NSLog("[Nudge Server] restart ignored; bring-up already in progress")
            return
        }
        NSLog("[Nudge Server] restart requested")
        stopServerIfSpawned()
        bringUpTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            await self?.bringUp(updateOnline: updateOnline)
            self?.bringUpTask = nil
        }
    }

    // MARK: - Lookup

    private static func locateNudge() async -> String? {
        let fm = FileManager.default
        for path in candidatePaths() where fm.isExecutableFile(atPath: path) {
            return path
        }
        // Fall back to a login shell so we inherit the user's full PATH.
        return await withCheckedContinuation { cont in
            DispatchQueue.global().async {
                let p = Process()
                p.executableURL = URL(fileURLWithPath: "/bin/zsh")
                p.arguments = ["-lc", "command -v nudge"]
                let pipe = Pipe()
                p.standardOutput = pipe
                p.standardError = Pipe()
                do {
                    try p.run()
                    p.waitUntilExit()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let out = String(data: data, encoding: .utf8)?
                        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    cont.resume(returning: (p.terminationStatus == 0 && !out.isEmpty) ? out : nil)
                } catch {
                    cont.resume(returning: nil)
                }
            }
        }
    }

    // MARK: - Notifications

    private func notifyMissingPackage() {
        let title = "Nudge needs the Python package"
        let body = "Install it with:  pip install nudge-ai"

        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert]) { granted, _ in
            guard granted else {
                Task { @MainActor in self.showAlertFallback(title: title, body: body) }
                return
            }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            let req = UNNotificationRequest(
                identifier: "nudge.missing-package",
                content: content,
                trigger: nil
            )
            center.add(req) { error in
                if error != nil {
                    Task { @MainActor in self.showAlertFallback(title: title, body: body) }
                }
            }
        }
    }

    private func showAlertFallback(title: String, body: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = body
        alert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
