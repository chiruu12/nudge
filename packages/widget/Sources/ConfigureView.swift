import SwiftUI

/// Known API-key providers, in a stable display order.
let keyProviders = ["groq", "openai", "anthropic", "deepgram"]

/// Which validation call a provider's key should run.
func validationKind(for provider: String) -> String {
    provider == "deepgram" ? "stt" : "llm"
}

/// A starter soul.md the user can edit or replace during setup.
let defaultSoulTemplate = """
# Soul

You are Nudge — concise, direct, and fast. Act immediately instead of asking \
clarifying questions.

## Tone
- Friendly and brief. No filler, no preamble.

## Tasks & notes
- Keep titles short and actionable.
- Capture the intent, not every word.

## How thorough to be
- Default to short. Expand only when I ask for detail.
"""

/// The Configure tab: pick providers/tier, enter & validate keys, edit the soul,
/// and manage the app. The managed "Nudge Cloud" option is previewed here too.
struct ConfigureView: View {
    @ObservedObject var vm: DashboardViewModel
    @ObservedObject var app: AppController

    @State private var sttProvider = ""
    @State private var llmProvider = ""
    @State private var llmTier = ""
    @State private var seeded = false
    @State private var saving = false
    @State private var savedNeedsRestart = false

    @State private var soul = ""
    @State private var soulLoaded = false
    @State private var savingSoul = false

    private var config: ConfigFull? { vm.configFull }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            PageHeader(title: "Configure", subtitle: "Providers, keys, and how Nudge behaves.")

            if savedNeedsRestart { restartBanner }

            cloudCard

            if let config {
                providersCard(config)
                keysCard(config)
            } else {
                WindowCard {
                    Text("Backend offline — start the Nudge server to edit providers.")
                        .font(.system(size: 12)).foregroundColor(NudgeTheme.textSecondary)
                }
            }

            soulCard
            appCard
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            seed()
            loadSoul()
        }
        .onChange(of: vm.configFull) { _ in seed() }
    }

    // MARK: - Cards

    private var cloudCard: some View {
        WindowCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "cloud.fill").font(.system(size: 18))
                    .foregroundColor(NudgeTheme.accent)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Nudge Cloud").font(.system(size: 14, weight: .semibold))
                            .foregroundColor(NudgeTheme.textPrimary)
                        Text("COMING SOON").font(.system(size: 9, weight: .bold)).tracking(0.5)
                            .foregroundColor(NudgeTheme.accent)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(NudgeTheme.accent.opacity(0.15)).cornerRadius(4)
                    }
                    Text("Skip the setup. We host the speech + language models and "
                        + "manage the subscription — just sign in and talk.")
                        .font(.system(size: 12)).foregroundColor(NudgeTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
        }
    }

    private func providersCard(_ config: ConfigFull) -> some View {
        WindowCard(title: "Providers") {
            picker("Speech-to-text", $sttProvider, config.available_stt_providers)
            picker("Language model", $llmProvider, config.available_llm_providers)
            picker("Tier", $llmTier, config.available_tiers)
            HStack {
                Spacer()
                NudgeButton(title: saving ? "Saving…" : "Save providers", icon: "tray.and.arrow.down",
                            kind: .primary, disabled: saving) {
                    Task { await saveProviders() }
                }
            }
        }
    }

    private func keysCard(_ config: ConfigFull) -> some View {
        WindowCard(title: "API keys") {
            Text("Stored in ~/.nudge/.env and never leave your Mac.")
                .font(.system(size: 11)).foregroundColor(NudgeTheme.textDim)
            ForEach(keyProviders, id: \.self) { provider in
                ProviderKeyField(provider: provider,
                                 alreadyConfigured: config.keys_present[provider] ?? false)
            }
        }
    }

    private var soulCard: some View {
        WindowCard(title: "Soul — how Nudge behaves") {
            Text("Plain instructions on tone and how thorough Nudge should be.")
                .font(.system(size: 11)).foregroundColor(NudgeTheme.textDim)
            TextEditor(text: $soul)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(NudgeTheme.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(minHeight: 160)
                .background(NudgeTheme.bg)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(NudgeTheme.cardBorder, lineWidth: 1))
            HStack {
                NudgeButton(title: "Insert template", icon: "text.badge.plus", kind: .ghost) {
                    soul = defaultSoulTemplate
                }
                Spacer()
                NudgeButton(title: savingSoul ? "Saving…" : "Save soul", icon: "sparkles",
                            kind: .primary, disabled: savingSoul) {
                    Task { await saveSoul() }
                }
            }
        }
    }

    private var appCard: some View {
        WindowCard(title: "App") {
            Toggle(isOn: Binding(get: { app.launchAtLogin },
                                 set: { app.setLaunchAtLogin($0) })) {
                Text("Launch at login").font(.system(size: 12))
                    .foregroundColor(NudgeTheme.textSecondary)
            }
            .toggleStyle(.switch).tint(NudgeTheme.accent)
            HStack(spacing: 8) {
                NudgeButton(title: "Restart backend", icon: "arrow.clockwise") {
                    app.restartBackend()
                }
                NudgeButton(title: "Quit Nudge", icon: "power", kind: .ghost) { app.quit() }
            }
        }
    }

    private var restartBanner: some View {
        WindowCard {
            HStack(spacing: 10) {
                Image(systemName: "arrow.clockwise.circle.fill").foregroundColor(NudgeTheme.accent)
                Text("Saved. Restart the backend to apply your changes.")
                    .font(.system(size: 12)).foregroundColor(NudgeTheme.textPrimary)
                Spacer()
                NudgeButton(title: "Restart Backend", icon: "arrow.clockwise", kind: .primary) {
                    app.restartBackend()
                    savedNeedsRestart = false
                }
            }
        }
    }

    // MARK: - Helpers

    private func picker(_ label: String, _ binding: Binding<String>,
                        _ options: [String]) -> some View {
        HStack {
            Text(label).font(.system(size: 12)).foregroundColor(NudgeTheme.textSecondary)
            Spacer()
            Picker(label, selection: binding) {
                ForEach(options, id: \.self) { Text($0).tag($0) }
            }
            .labelsHidden().frame(width: 180).tint(NudgeTheme.accent)
        }
    }

    private func seed() {
        guard !seeded, let c = vm.configFull else { return }
        sttProvider = c.stt_provider
        llmProvider = c.llm_provider
        llmTier = c.llm_tier
        seeded = true
    }

    private func loadSoul() {
        guard !soulLoaded else { return }
        soulLoaded = true
        Task {
            let loaded = await APIClient.shared.soul()
            if let loaded, !loaded.isEmpty { soul = loaded }
        }
    }

    private func saveProviders() async {
        guard let c = vm.configFull else { return }
        saving = true
        var fields: [String: String] = [:]
        if sttProvider != c.stt_provider { fields["stt_provider"] = sttProvider }
        if llmProvider != c.llm_provider { fields["llm_provider"] = llmProvider }
        if llmTier != c.llm_tier { fields["llm_tier"] = llmTier }
        if !fields.isEmpty { _ = await APIClient.shared.saveConfig(fields) }
        await vm.refresh()
        saving = false
        savedNeedsRestart = true
    }

    private func saveSoul() async {
        savingSoul = true
        _ = await APIClient.shared.saveSoul(soul)
        savingSoul = false
        savedNeedsRestart = true
    }
}

/// A single API-key row: secure entry + Save & Validate, or a "configured" pill.
struct ProviderKeyField: View {
    let provider: String
    let alreadyConfigured: Bool

    @State private var key = ""
    @State private var validating = false
    @State private var result: ValidateResult?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(provider).font(.system(size: 12, weight: .medium))
                    .foregroundColor(NudgeTheme.textPrimary)
                if alreadyConfigured {
                    Text("configured").font(.system(size: 9, weight: .semibold))
                        .foregroundColor(NudgeTheme.success)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(NudgeTheme.success.opacity(0.15)).cornerRadius(4)
                }
                Spacer()
                if let result {
                    Image(systemName: result.ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(result.ok ? NudgeTheme.success : NudgeTheme.error)
                        .font(.system(size: 12))
                }
            }
            HStack(spacing: 8) {
                SecureField("Paste \(provider) API key", text: $key)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, design: .monospaced))
                    .padding(.horizontal, 8).padding(.vertical, 6)
                    .background(NudgeTheme.bg).cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6)
                        .stroke(NudgeTheme.cardBorder, lineWidth: 1))
                NudgeButton(title: validating ? "…" : "Save & Validate", kind: .secondary,
                            disabled: key.isEmpty || validating) {
                    Task { await saveAndValidate() }
                }
            }
            if let result, !result.message.isEmpty {
                Text(result.message).font(.system(size: 10))
                    .foregroundColor(result.ok ? NudgeTheme.textDim : NudgeTheme.error)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func saveAndValidate() async {
        validating = true
        _ = await APIClient.shared.saveKey(provider: provider, apiKey: key)
        result = await APIClient.shared.validate(
            provider: provider,
            kind: validationKind(for: provider),
            apiKey: key
        )
        validating = false
    }
}
