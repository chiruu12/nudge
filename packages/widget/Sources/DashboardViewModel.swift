import Combine
import Foundation
import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var tasks: [NudgeTask] = []
    @Published var doneTasks: [NudgeTask] = []
    @Published var alarms: [NudgeAlarm] = []
    @Published var notes: [APINote] = []
    @Published var recentActivity: [SessionEntry] = []
    @Published var isBackendOnline = false
    @Published var searchText = ""
    @Published var isProcessing = false
    @Published var lastResult: SessionResult?
    @Published var lastDictation: String?
    @Published var backendConfig: NudgeConfigInfo?
    @Published var isFirstLoad = true
    @Published var lastRefresh: Date?

    private var pollTask: Task<Void, Never>?

    var filteredActivity: [SessionEntry] {
        let valid = recentActivity.filter { entry in
            guard let result = entry.result else { return false }
            return !result.text.isEmpty
        }
        guard !searchText.isEmpty else { return valid }
        let query = searchText.lowercased()
        return valid.filter { entry in
            guard let result = entry.result else { return false }
            return result.text.lowercased().contains(query)
                || result.response.lowercased().contains(query)
                || result.intent.lowercased().contains(query)
        }
    }

    func startPolling() {
        pollTask?.cancel()
        pollTask = Task {
            while !Task.isCancelled {
                await refresh()
                try? await Task.sleep(nanoseconds: 5_000_000_000)
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    func refresh() async {
        let online = await APIClient.shared.health()

        if online {
            async let t = APIClient.shared.tasks()
            async let dt = APIClient.shared.doneTasks()
            async let a = APIClient.shared.alarms()
            async let n = APIClient.shared.notes()
            async let h = APIClient.shared.history()
            async let c = APIClient.shared.config()

            let newTasks = await t
            let newDoneTasks = await dt
            let newAlarms = await a
            let newNotes = await n
            let newActivity = await h
            let newConfig = await c

            withAnimation(.easeInOut(duration: 0.2)) {
                if isBackendOnline != online { isBackendOnline = online }
                if tasks != newTasks { tasks = newTasks }
                if doneTasks != newDoneTasks { doneTasks = newDoneTasks }
                if alarms != newAlarms { alarms = newAlarms }
                if notes != newNotes { notes = newNotes }
                if recentActivity != newActivity { recentActivity = newActivity }
                if backendConfig != newConfig { backendConfig = newConfig }
                isFirstLoad = false
                lastRefresh = Date()
            }
        } else {
            withAnimation {
                if isBackendOnline != online { isBackendOnline = online }
                if isFirstLoad && tasks.isEmpty { loadPlaceholders() }
                isFirstLoad = false
            }
        }
    }

    func sendCommand(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isProcessing = true
        lastResult = await APIClient.shared.processText(text)
        isProcessing = false
        await refresh()
    }

    func completeTask(_ task: NudgeTask) async {
        let ok = await APIClient.shared.completeTask(task.id)
        NSLog("[Nudge VM] complete task id=\(task.id) ok=\(ok)")
        await refresh()
    }

    func uncompleteTask(_ task: NudgeTask) async {
        let ok = await APIClient.shared.uncompleteTask(task.id)
        NSLog("[Nudge VM] uncomplete task id=\(task.id) ok=\(ok)")
        await refresh()
    }

    func toggleTask(_ task: NudgeTask) async {
        if task.status == "done" {
            await uncompleteTask(task)
        } else {
            await completeTask(task)
        }
    }

    func deleteTask(_ task: NudgeTask) async {
        _ = await APIClient.shared.deleteTask(task.id)
        await refresh()
    }

    func cancelAlarm(_ alarm: NudgeAlarm) async {
        _ = await APIClient.shared.cancelAlarm(alarm.id)
        await refresh()
    }

    func deleteNote(_ note: APINote) async {
        _ = await APIClient.shared.deleteNote(note.id)
        await refresh()
    }

    private func loadPlaceholders() {
        tasks = [
            NudgeTask(id: "1", text: "Morning standup", status: "done", priority: "medium", createdAt: nil),
            NudgeTask(id: "2", text: "Review the PR", status: "pending", priority: "high", createdAt: nil),
            NudgeTask(id: "3", text: "Email design team", status: "pending", priority: "medium", createdAt: nil),
            NudgeTask(id: "4", text: "Fix API bug", status: "pending", priority: "low", createdAt: nil),
        ]
        alarms = [
            NudgeAlarm(id: "1", time: "3:00 PM", label: "Call dentist", createdAt: nil),
            NudgeAlarm(id: "2", time: "5:30 PM", label: "Team sync", createdAt: nil),
            NudgeAlarm(id: "3", time: "9:00 AM", label: "Standup", createdAt: nil),
        ]
        notes = []
        recentActivity = []
    }
}
