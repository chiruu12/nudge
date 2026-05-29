import Foundation
import SwiftUI

/// Shared app state bridged between the AppKit AppDelegate (menu-bar widget)
/// and the SwiftUI main window. AppDelegate populates the references once at
/// launch, so both surfaces use the SAME view model / polling loop / APIClient.
@MainActor
final class AppEnvironment: ObservableObject {
    static let shared = AppEnvironment()

    var viewModel: DashboardViewModel!
    var voiceController: VoiceController!
    var appController: AppController!
    var recorder: AudioRecorder!

    private static let onboardKey = "didOnboard"

    /// Set true once the user finishes onboarding (persisted in UserDefaults).
    @Published var didOnboard: Bool = UserDefaults.standard.bool(forKey: "didOnboard")

    func markOnboarded() {
        didOnboard = true
        UserDefaults.standard.set(true, forKey: Self.onboardKey)
    }

    /// If the user already has a working provider key configured, treat them as
    /// onboarded so existing users aren't forced through the wizard.
    func adoptExistingConfigIfNeeded(_ config: ConfigFull?) {
        guard !didOnboard, let config else { return }
        if config.keys_present[config.llm_provider] == true {
            markOnboarded()
        }
    }
}
