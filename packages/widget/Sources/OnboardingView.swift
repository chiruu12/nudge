import AppKit
import SwiftUI

/// First-run wizard: welcome → how it works → choose mode → configure → soul → done.
/// On finish it writes config + keys + soul, restarts the backend, and marks onboarded.
struct OnboardingView: View {
    @EnvironmentObject var env: AppEnvironment
    @State private var step = 0
    @State private var mode: Mode = .cloud
    @State private var soul = defaultSoulTemplate
    @State private var applying = false

    enum Mode: String, CaseIterable {
        case cloud, local, custom
        var preset: String? {
            switch self {
            case .cloud: return "default"
            case .local: return "offline"
            case .custom: return nil
            }
        }
    }

    private let lastStep = 6

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                content
                    .frame(maxWidth: 540)
                    .frame(maxWidth: .infinity)
                    .padding(40)
            }
            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NudgeTheme.bg)
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case 0: welcome
        case 1: howItWorks
        case 2: chooseMode
        case 3: configure
        case 4: soulStep
        case 5: linksStep
        default: done
        }
    }

    // MARK: - Steps

    private var welcome: some View {
        VStack(spacing: 16) {
            Image(systemName: "bolt.fill").font(.system(size: 48)).foregroundColor(NudgeTheme.accent)
            Text("Welcome to Nudge").font(.system(size: 28, weight: .bold))
                .foregroundColor(NudgeTheme.textPrimary)
            Text("Your voice assistant that actually gets things done.\nPress a hotkey. Speak. Done.")
                .font(.system(size: 14)).foregroundColor(NudgeTheme.textSecondary)
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 6) {
                bullet("Tasks, alarms & reminders by voice")
                bullet("Notes & a searchable knowledge base")
                bullet("Learns your language — open source")
            }.padding(.top, 8)
        }
    }

    private var howItWorks: some View {
        VStack(spacing: 16) {
            Text("How Nudge works").font(.system(size: 22, weight: .bold))
                .foregroundColor(NudgeTheme.textPrimary)
            VStack(alignment: .leading, spacing: 14) {
                stepRow("1", "Press \u{2318}\u{21E7}.", "The mic starts listening from anywhere.")
                stepRow("2", "Speak your command", "\u{201C}Remind me to call mom at 3pm\u{201D}")
                stepRow("3", "Nudge acts", "Transcribe \u{2192} understand \u{2192} done, in about a second.")
            }
        }
    }

    private var chooseMode: some View {
        VStack(spacing: 14) {
            Text("How do you want to run Nudge?").font(.system(size: 20, weight: .bold))
                .foregroundColor(NudgeTheme.textPrimary)

            // Managed offering — pitched first, not yet live.
            cloudWaitlistCard

            Text("Or set it up yourself").font(.system(size: 11, weight: .semibold))
                .foregroundColor(NudgeTheme.textDim)
                .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 4)

            modeCard(.cloud, "Bring your own cloud", "key.fill",
                     "Fast & free via Groq. ~200ms. Needs a free API key.")
            modeCard(.local, "Local", "desktopcomputer",
                     "Fully offline via Ollama + Whisper. Private, ~2s.")
            modeCard(.custom, "Custom", "slider.horizontal.3",
                     "Pick your own providers — OpenAI, Anthropic, and more.")
        }
    }

    private var cloudWaitlistCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "cloud.fill").font(.system(size: 18))
                    .foregroundColor(NudgeTheme.accent)
                Text("Nudge Cloud").font(.system(size: 15, weight: .semibold))
                    .foregroundColor(NudgeTheme.textPrimary)
                Text("COMING SOON").font(.system(size: 9, weight: .bold)).tracking(0.5)
                    .foregroundColor(NudgeTheme.accent)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(NudgeTheme.accent.opacity(0.15)).cornerRadius(4)
                Spacer()
            }
            Text("The easiest way: we host the models and manage the subscription. "
                + "No keys, no setup — just sign in and talk.")
                .font(.system(size: 12)).foregroundColor(NudgeTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            NudgeButton(title: "Join the waitlist", icon: "envelope", kind: .secondary) {
                if let url = URL(string: "https://nudge-ai.org") { NSWorkspace.shared.open(url) }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NudgeTheme.accent.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: NudgeTheme.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: NudgeTheme.cardRadius)
            .stroke(NudgeTheme.accent.opacity(0.4), lineWidth: 1))
    }

    @ViewBuilder
    private var configure: some View {
        VStack(alignment: .leading, spacing: 14) {
            switch mode {
            case .cloud:
                Text("Connect Groq").font(.system(size: 20, weight: .bold))
                    .foregroundColor(NudgeTheme.textPrimary)
                NudgeButton(title: "Get a free key at console.groq.com", icon: "arrow.up.right.square",
                            kind: .ghost) {
                    if let url = URL(string: "https://console.groq.com/keys") {
                        NSWorkspace.shared.open(url)
                    }
                }
                WindowCard { ProviderKeyField(provider: "groq", alreadyConfigured: keyPresent("groq")) }
            case .local:
                Text("Local setup").font(.system(size: 20, weight: .bold))
                    .foregroundColor(NudgeTheme.textPrimary)
                WindowCard {
                    Text("No API key needed. Make sure these are installed:")
                        .font(.system(size: 12)).foregroundColor(NudgeTheme.textSecondary)
                    bullet("Ollama — ollama.com/download, then: ollama pull llama3.2")
                    bullet("Whisper — pip install mlx-whisper")
                }
            case .custom:
                Text("Configure providers").font(.system(size: 20, weight: .bold))
                    .foregroundColor(NudgeTheme.textPrimary)
                WindowCard {
                    ForEach(keyProviders, id: \.self) { provider in
                        ProviderKeyField(provider: provider, alreadyConfigured: keyPresent(provider))
                    }
                }
            }
        }
    }

    private var soulStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shape your assistant").font(.system(size: 20, weight: .bold))
                .foregroundColor(NudgeTheme.textPrimary)
            Text("This is your “soul” — plain-language instructions for how Nudge should "
                + "behave. It reads this before every command. Optional: edit the starter "
                + "below or skip and tweak it later in Configure.")
                .font(.system(size: 12)).foregroundColor(NudgeTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 5) {
                Text("Good things to specify").font(.system(size: 11, weight: .semibold))
                    .foregroundColor(NudgeTheme.textDim)
                bullet("Tone — terse and direct, or warm and detailed?")
                bullet("Thoroughness — one-line answers, or step-by-step?")
                bullet("Conventions — your team's terms, how to title tasks, default due dates")
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(NudgeTheme.accent.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            TextEditor(text: $soul)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(NudgeTheme.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(minHeight: 200)
                .background(NudgeTheme.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(NudgeTheme.cardBorder, lineWidth: 1))
            NudgeButton(title: "Reset to template", icon: "arrow.uturn.backward", kind: .ghost) {
                soul = defaultSoulTemplate
            }
        }
    }

    private var linksStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Save your key links").font(.system(size: 20, weight: .bold))
                .foregroundColor(NudgeTheme.textPrimary)
            Text("Add the links you reach for most. Later, just say “open my linkedin” — "
                + "or copy any URL and say “save this link”. Optional; you can skip.")
                .font(.system(size: 12)).foregroundColor(NudgeTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if let vm = env.viewModel {
                LinksSectionView(vm: vm)
            }
        }
    }

    private var done: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 48))
                .foregroundColor(NudgeTheme.success)
            Text("You're all set").font(.system(size: 24, weight: .bold))
                .foregroundColor(NudgeTheme.textPrimary)
            Text("Press \u{2318}\u{21E7}. anywhere and say:\n\u{201C}Add a task to review the PR\u{201D}")
                .font(.system(size: 14)).foregroundColor(NudgeTheme.textSecondary)
                .multilineTextAlignment(.center)
            Text("Nudge lives in your menu bar and this window.")
                .font(.system(size: 11)).foregroundColor(NudgeTheme.textDim)
        }
    }

    // MARK: - Footer / nav

    private var footer: some View {
        HStack {
            if step > 0 {
                NudgeButton(title: "Back", kind: .ghost) { step -= 1 }
            }
            Spacer()
            HStack(spacing: 6) {
                ForEach(0...lastStep, id: \.self) { i in
                    Circle().fill(i == step ? NudgeTheme.accent : NudgeTheme.cardBorder)
                        .frame(width: 6, height: 6)
                }
            }
            Spacer()
            NudgeButton(
                title: step == lastStep ? (applying ? "Finishing…" : "Start using Nudge") : "Next",
                icon: step == lastStep ? "checkmark" : "arrow.right",
                kind: .primary,
                disabled: applying
            ) {
                if step == lastStep { Task { await finish() } } else { step += 1 }
            }
        }
        .padding(20)
        .background(NudgeTheme.sidebar)
        .overlay(Rectangle().fill(NudgeTheme.cardBorder).frame(height: 1), alignment: .top)
    }

    // MARK: - Helpers

    private func keyPresent(_ provider: String) -> Bool {
        env.viewModel?.configFull?.keys_present[provider] ?? false
    }

    private func finish() async {
        applying = true
        if !soul.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            _ = await APIClient.shared.saveSoul(soul)
        }
        if let preset = mode.preset {
            _ = await APIClient.shared.saveConfig(["preset": preset])
        }
        env.appController?.restartBackend()
        await env.viewModel?.refresh()
        applying = false
        env.markOnboarded()
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().fill(NudgeTheme.accent).frame(width: 5, height: 5).padding(.top, 6)
            Text(text).font(.system(size: 12)).foregroundColor(NudgeTheme.textSecondary)
        }
    }

    private func stepRow(_ num: String, _ title: String, _ subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(num).font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                .frame(width: 26, height: 26).background(NudgeTheme.accent).clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 14, weight: .semibold))
                    .foregroundColor(NudgeTheme.textPrimary)
                Text(subtitle).font(.system(size: 12)).foregroundColor(NudgeTheme.textSecondary)
            }
            Spacer()
        }
    }

    private func modeCard(_ m: Mode, _ title: String, _ icon: String, _ desc: String) -> some View {
        Button { mode = m } label: {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 20))
                    .foregroundColor(mode == m ? NudgeTheme.accent : NudgeTheme.textSecondary)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 14, weight: .semibold))
                        .foregroundColor(NudgeTheme.textPrimary)
                    Text(desc).font(.system(size: 11)).foregroundColor(NudgeTheme.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                if mode == m {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(NudgeTheme.accent)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(NudgeTheme.cardBg).cornerRadius(NudgeTheme.cardRadius)
            .overlay(RoundedRectangle(cornerRadius: NudgeTheme.cardRadius)
                .stroke(mode == m ? NudgeTheme.accent : NudgeTheme.cardBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
