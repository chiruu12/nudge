import Foundation
import ServiceManagement

/// Thin wrapper over SMAppService for "Launch at Login" (macOS 13+).
/// Registration requires a real .app bundle, so calls are no-ops (and log)
/// when running the bare executable via `swift run`.
enum LoginItem {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            NSLog("[Nudge LoginItem] toggle failed: \(error.localizedDescription)")
        }
    }
}
