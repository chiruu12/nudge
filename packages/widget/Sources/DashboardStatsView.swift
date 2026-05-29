import SwiftUI

/// The Dashboard: lifetime usage stats pulled from GET /api/stats.
struct DashboardStatsView: View {
    @ObservedObject var vm: DashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PageHeader(title: "Dashboard", subtitle: "Your voice, by the numbers.")

            if let stats = vm.stats, stats.total_commands > 0 {
                content(stats)
            } else if !vm.isBackendOnline {
                StatsEmptyState(
                    icon: "wifi.slash",
                    title: "Backend offline",
                    subtitle: "Start the Nudge server to see your stats."
                )
            } else {
                StatsEmptyState(
                    icon: "waveform",
                    title: "No commands yet",
                    subtitle: "Press \u{2318}\u{21E7}. and speak — your stats will show up here."
                )
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func content(_ stats: NudgeStats) -> some View {
        // Headline: time saved.
        CardView {
            VStack(alignment: .leading, spacing: 4) {
                Text("TIME SAVED").font(.system(size: 11, weight: .semibold))
                    .foregroundColor(NudgeTheme.textSecondary).tracking(1)
                Text(Self.formatDuration(stats.time_saved_seconds))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(NudgeTheme.accent)
                Text("across \(stats.total_commands) commands")
                    .font(.system(size: 12)).foregroundColor(NudgeTheme.textDim)
            }
        }

        // Primary metrics.
        HStack(spacing: 12) {
            StatTile(label: "Commands", value: "\(stats.total_commands)", icon: "terminal")
            StatTile(
                label: "Success",
                value: "\(Int((stats.success_rate * 100).rounded()))%",
                icon: "checkmark.seal",
                color: NudgeTheme.intentTask
            )
            StatTile(
                label: "Avg latency",
                value: "\(stats.avg_duration_ms)ms",
                icon: "bolt",
                color: NudgeTheme.intentAnswer
            )
        }

        // Counts.
        HStack(spacing: 12) {
            StatTile(label: "Tasks", value: "\(stats.task_count)", icon: "checklist")
            StatTile(label: "Alarms", value: "\(stats.alarm_count)", icon: "alarm")
            StatTile(label: "Notes", value: "\(stats.note_count)", icon: "note.text",
                     color: NudgeTheme.intentNote)
        }

        if !stats.commands_by_intent.isEmpty {
            CardView {
                Text("commands by intent").font(.system(size: 12, weight: .medium))
                    .foregroundColor(NudgeTheme.textSecondary)
                let pairs = stats.commands_by_intent.sorted { $0.value > $1.value }
                let maxCount = pairs.first?.value ?? 1
                ForEach(pairs, id: \.key) { intent, count in
                    BarRow(label: intent, count: count, total: maxCount,
                           color: Self.intentColor(intent))
                }
            }
        }

        // Latency breakdown.
        CardView {
            Text("latency breakdown").font(.system(size: 12, weight: .medium))
                .foregroundColor(NudgeTheme.textSecondary)
            SettingsRow(label: "Speech-to-text", value: "\(stats.avg_stt_ms)ms")
            SettingsRow(label: "Intent routing", value: "\(stats.avg_intent_ms)ms")
            SettingsRow(label: "Agent", value: "\(stats.avg_agent_ms)ms")
        }
    }

    static func formatDuration(_ seconds: Double) -> String {
        let total = Int(seconds.rounded())
        if total < 60 { return "\(total)s" }
        if total < 3600 {
            let m = total / 60, s = total % 60
            return s == 0 ? "\(m)m" : "\(m)m \(s)s"
        }
        let h = total / 3600, m = (total % 3600) / 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    static func intentColor(_ intent: String) -> Color {
        switch intent {
        case "alarm": return NudgeTheme.intentAlarm
        case "task": return NudgeTheme.intentTask
        case "note": return NudgeTheme.intentNote
        default: return NudgeTheme.intentAnswer
        }
    }
}

struct StatTile: View {
    let label: String
    let value: String
    let icon: String
    var color: Color = NudgeTheme.accent

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon).font(.system(size: 14)).foregroundColor(color)
                Text(value).font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(NudgeTheme.textPrimary)
                Text(label).font(.system(size: 11)).foregroundColor(NudgeTheme.textSecondary)
            }
        }
    }
}

struct BarRow: View {
    let label: String
    let count: Int
    let total: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label).font(.system(size: 11)).foregroundColor(NudgeTheme.textSecondary)
                Spacer()
                Text("\(count)").font(.system(size: 11, design: .monospaced))
                    .foregroundColor(NudgeTheme.textPrimary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(NudgeTheme.cardBorder)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3).fill(color)
                        .frame(
                            width: geo.size.width * CGFloat(count) / CGFloat(max(total, 1)),
                            height: 6
                        )
                }
            }.frame(height: 6)
        }
    }
}

struct StatsEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 32)).foregroundColor(NudgeTheme.textDim)
            Text(title).font(.system(size: 15, weight: .semibold))
                .foregroundColor(NudgeTheme.textPrimary)
            Text(subtitle).font(.system(size: 12)).foregroundColor(NudgeTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 60)
    }
}
