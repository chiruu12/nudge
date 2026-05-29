import SwiftUI

/// The app's main window: a fixed left sidebar (LM Studio / Conductor style) with
/// a Dashboard, the task/alarm/note sections, and Configure. Shows the onboarding
/// wizard instead until the user has set things up.
struct MainWindowView: View {
    @EnvironmentObject var env: AppEnvironment
    @State private var section: Section = .dashboard
    @State private var selectedTaskID: String?

    enum Section: String, CaseIterable, Identifiable {
        case dashboard, tasks, alarms, notes, links, configure
        var id: String { rawValue }
        var title: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .tasks: return "Tasks"
            case .alarms: return "Alarms"
            case .notes: return "Notes"
            case .links: return "Links"
            case .configure: return "Configure"
            }
        }
        var icon: String {
            switch self {
            case .dashboard: return "chart.bar.fill"
            case .tasks: return "checklist"
            case .alarms: return "alarm.fill"
            case .notes: return "note.text"
            case .links: return "link"
            case .configure: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        Group {
            if env.didOnboard {
                HStack(spacing: 0) {
                    sidebar
                    Rectangle().fill(NudgeTheme.cardBorder).frame(width: 1)
                    detail
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(NudgeTheme.bg)
                }
            } else {
                OnboardingView()
            }
        }
        .onAppear { env.viewModel?.startPolling() }
    }

    // MARK: - Sidebar (fixed, non-collapsing)

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill").font(.system(size: 16))
                    .foregroundColor(NudgeTheme.accent)
                Text("Nudge").font(.system(size: 16, weight: .bold))
                    .foregroundColor(NudgeTheme.textPrimary)
            }
            .padding(.horizontal, 14).padding(.top, 18).padding(.bottom, 16)

            VStack(spacing: 2) {
                ForEach(Section.allCases) { item in
                    SidebarRow(
                        title: item.title,
                        icon: item.icon,
                        selected: section == item
                    ) { section = item }
                }
            }
            .padding(.horizontal, 8)

            Spacer()

            if let vm = env.viewModel {
                StatusDot(online: vm.isBackendOnline)
                    .padding(.horizontal, 16).padding(.bottom, 14)
            }
        }
        .frame(width: 210)
        .frame(maxHeight: .infinity)
        .background(NudgeTheme.sidebar)
    }

    // MARK: - Detail

    @ViewBuilder
    private var detail: some View {
        if let vm = env.viewModel {
            ScrollView {
                Group {
                    switch section {
                    case .dashboard: DashboardStatsView(vm: vm)
                    case .tasks:
                        sectionPage("Tasks", "Everything on your plate.") {
                            TasksSectionView(vm: vm, selectedTaskID: $selectedTaskID)
                        }
                    case .alarms:
                        sectionPage("Alarms", "Timed reminders.") { AlarmsSectionView(vm: vm) }
                    case .notes:
                        sectionPage("Notes", "Your saved knowledge.") { NotesSectionView(vm: vm) }
                    case .links:
                        sectionPage("Links", "Your saved URLs.") { LinksSectionView(vm: vm) }
                    case .configure:
                        if let app = env.appController { ConfigureView(vm: vm, app: app) }
                    }
                }
            }
        }
    }

    private func sectionPage<Content: View>(
        _ title: String,
        _ subtitle: String,
        @ViewBuilder _ content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            PageHeader(title: title, subtitle: subtitle)
            content()
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
