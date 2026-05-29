import SwiftUI

// Shared, polished UI building blocks for the main window.

enum NudgeButtonKind {
    case primary, secondary, ghost
}

/// A consistent button with hover feedback, used across the window UI.
struct NudgeButton: View {
    let title: String
    var icon: String?
    var kind: NudgeButtonKind = .secondary
    var fill: Bool = false
    var disabled: Bool = false
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon).font(.system(size: 11, weight: .semibold)) }
                Text(title).font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(foreground)
            .frame(maxWidth: fill ? .infinity : nil)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(border, lineWidth: kind == .secondary ? 1 : 0)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .opacity(disabled ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .onHover { hovering = $0 && !disabled }
    }

    private var foreground: Color {
        switch kind {
        case .primary: return .white
        case .secondary: return NudgeTheme.textPrimary
        case .ghost: return hovering ? NudgeTheme.textPrimary : NudgeTheme.textSecondary
        }
    }

    private var background: Color {
        switch kind {
        case .primary: return hovering ? NudgeTheme.accentHover : NudgeTheme.accent
        case .secondary: return hovering ? NudgeTheme.surfaceHover : NudgeTheme.cardBg
        case .ghost: return hovering ? NudgeTheme.surfaceHover : .clear
        }
    }

    private var border: Color {
        hovering ? NudgeTheme.borderStrong : NudgeTheme.cardBorder
    }
}

/// A titled content card with generous padding for the window (vs the dense popover CardView).
struct WindowCard<Content: View>: View {
    var title: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let title {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold)).tracking(0.8)
                    .foregroundColor(NudgeTheme.textSecondary)
            }
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NudgeTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: NudgeTheme.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: NudgeTheme.cardRadius)
                .stroke(NudgeTheme.cardBorder, lineWidth: 1)
        )
    }
}

/// Page heading used at the top of each window section.
struct PageHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 22, weight: .bold))
                .foregroundColor(NudgeTheme.textPrimary)
            if let subtitle {
                Text(subtitle).font(.system(size: 13)).foregroundColor(NudgeTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Small colored status dot + label.
struct StatusDot: View {
    let online: Bool
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(online ? NudgeTheme.success : NudgeTheme.textDim)
                .frame(width: 7, height: 7)
            Text(online ? "Connected" : "Offline")
                .font(.system(size: 11)).foregroundColor(NudgeTheme.textSecondary)
        }
    }
}

/// A sidebar navigation row with selected + hover states.
struct SidebarRow: View {
    let title: String
    let icon: String
    let selected: Bool
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 13, weight: .medium))
                    .frame(width: 18)
                Text(title).font(.system(size: 13, weight: selected ? .semibold : .medium))
                Spacer()
            }
            .foregroundColor(selected ? NudgeTheme.accent : NudgeTheme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(rowBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }

    private var rowBackground: Color {
        if selected { return NudgeTheme.accent.opacity(0.14) }
        return hovering ? NudgeTheme.surfaceHover : .clear
    }
}
