import AppKit
import SwiftUI

/// Saved named links — list, add, open, delete. Nudge can also grab a link from
/// the clipboard ("save this link as github").
struct LinksSectionView: View {
    @ObservedObject var vm: DashboardViewModel
    @State private var newName = ""
    @State private var newURL = ""
    @State private var saving = false

    private var canSave: Bool {
        !newName.trimmingCharacters(in: .whitespaces).isEmpty
            && newURL.trimmingCharacters(in: .whitespaces).hasPrefix("http")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            WindowCard {
                HStack(spacing: 10) {
                    Image(systemName: "doc.on.clipboard").foregroundColor(NudgeTheme.accent)
                    Text("Tip: copy a link, then say “save this link as github” — "
                        + "Nudge grabs it straight from your clipboard.")
                        .font(.system(size: 12)).foregroundColor(NudgeTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            WindowCard(title: "Add a link") {
                HStack(spacing: 8) {
                    field("Name (e.g. github)", $newName).frame(width: 160)
                    field("https://…", $newURL)
                    NudgeButton(title: saving ? "…" : "Save", icon: "plus", kind: .primary,
                                disabled: !canSave || saving) {
                        Task { await save() }
                    }
                }
            }

            if vm.links.isEmpty {
                EmptyHint(text: "No links yet. Add one above, or say “save my github as …”.")
            } else {
                WindowCard(title: "Saved") {
                    ForEach(vm.links) { link in
                        LinkRow(link: link, vm: vm)
                        if link.id != vm.links.last?.id {
                            Rectangle().fill(NudgeTheme.cardBorder).frame(height: 1)
                        }
                    }
                }
            }
        }
    }

    private func field(_ placeholder: String, _ binding: Binding<String>) -> some View {
        TextField(placeholder, text: binding)
            .textFieldStyle(.plain)
            .font(.system(size: 12))
            .padding(.horizontal, 8).padding(.vertical, 6)
            .background(NudgeTheme.bg).cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(NudgeTheme.cardBorder, lineWidth: 1))
    }

    private func save() async {
        saving = true
        await vm.saveLink(name: newName, url: newURL)
        newName = ""
        newURL = ""
        saving = false
    }
}

struct LinkRow: View {
    let link: NamedLink
    @ObservedObject var vm: DashboardViewModel
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "link").font(.system(size: 11)).foregroundColor(NudgeTheme.accent)
            VStack(alignment: .leading, spacing: 1) {
                Text(link.name).font(.system(size: 12, weight: .medium))
                    .foregroundColor(NudgeTheme.textPrimary)
                Text(link.url).font(.system(size: 10)).foregroundColor(NudgeTheme.textDim)
                    .lineLimit(1)
            }
            Spacer()
            if hovering {
                Button { open() } label: {
                    Image(systemName: "arrow.up.right.square").foregroundColor(NudgeTheme.textSecondary)
                }.buttonStyle(.plain)
                Button { Task { await vm.deleteLink(link) } } label: {
                    Image(systemName: "trash").foregroundColor(NudgeTheme.error)
                }.buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .onTapGesture { open() }
    }

    private func open() {
        if let url = URL(string: link.url) { NSWorkspace.shared.open(url) }
    }
}
