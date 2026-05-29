import AppKit
import Foundation

/// App-level actions shared between the status-item menu and the Settings UI:
/// quit, restart the backend, and toggle Launch at Login.
@MainActor
final class AppController: ObservableObject {
    @Published var launchAtLogin: Bool = LoginItem.isEnabled

    private let serverManager: ServerManager
    private let viewModel: DashboardViewModel

    init(serverManager: ServerManager, viewModel: DashboardViewModel) {
        self.serverManager = serverManager
        self.viewModel = viewModel
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        LoginItem.setEnabled(enabled)
        launchAtLogin = LoginItem.isEnabled
    }

    func restartBackend() {
        serverManager.restartServer { [weak self] online in
            self?.viewModel.isBackendOnline = online
            Task { await self?.viewModel.refresh() }
        }
    }

    func quit() {
        NSApp.terminate(nil)
    }
}
