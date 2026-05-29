import SwiftUI

// Section content shared by the menu-bar popover (DashboardView tabs) and the
// main window (MainWindowView sidebar). Row components live in DashboardView.swift.

struct TasksSectionView: View {
    @ObservedObject var vm: DashboardViewModel
    @Binding var selectedTaskID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "pending", count: vm.tasks.count)
            if vm.tasks.isEmpty {
                EmptyHint(text: "No pending tasks. Say \"add task ...\"")
            } else {
                ForEach(vm.tasks) { task in
                    ExpandableTaskRow(task: task, vm: vm, selectedTaskID: $selectedTaskID)
                        .id(task.id)
                }
            }
            if !vm.doneTasks.isEmpty {
                SectionHeader(title: "completed", count: vm.doneTasks.count, color: NudgeTheme.textDim)
                ForEach(vm.doneTasks) { task in
                    ExpandableTaskRow(task: task, vm: vm, selectedTaskID: $selectedTaskID)
                        .id(task.id)
                }
            }
        }.padding(16)
    }
}

struct AlarmsSectionView: View {
    @ObservedObject var vm: DashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "pending alarms", count: vm.alarms.count)
            if vm.alarms.isEmpty {
                EmptyHint(text: "No alarms. Say \"remind me at ...\"")
            } else {
                ForEach(vm.alarms) { alarm in ExpandableAlarmRow(alarm: alarm, vm: vm) }
            }
        }.padding(16)
    }
}

struct NotesSectionView: View {
    @ObservedObject var vm: DashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "notes", count: vm.notes.count, color: NudgeTheme.intentNote)
            if vm.notes.isEmpty {
                EmptyHint(text: "No notes yet. Say \"remember ...\"")
            } else {
                ForEach(vm.notes) { note in ExpandableNoteRow(note: note, vm: vm) }
            }
        }.padding(16)
    }
}
