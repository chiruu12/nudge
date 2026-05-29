import SwiftUI

struct DashboardView: View {
    @ObservedObject var recorder: AudioRecorder
    @ObservedObject var vm: DashboardViewModel
    @ObservedObject var voice: VoiceController
    @ObservedObject var app: AppController
    @State private var selectedTab: Tab = .nudge
    @State private var selectedTaskID: String?
    @State private var commandText = ""
    @State private var showCommandInput = false
    @FocusState private var commandFocused: Bool

    init(
        recorder: AudioRecorder,
        viewModel: DashboardViewModel,
        voiceController: VoiceController,
        appController: AppController
    ) {
        self.recorder = recorder
        self.vm = viewModel
        self.voice = voiceController
        self.app = appController
    }

    enum Tab: String, CaseIterable {
        case nudge, tasks, alarms, notes, settings
    }

    var body: some View {
        VStack(spacing: 0) {
            connectionBar

            if vm.isFirstLoad {
                Spacer()
                ProgressView("connecting...")
                    .font(.system(size: 12))
                    .foregroundColor(NudgeTheme.textSecondary)
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: true) {
                        Group {
                            switch selectedTab {
                            case .nudge: nudgeDashboard
                            case .tasks: tasksFullView
                            case .alarms: alarmsFullView
                            case .notes: notesFullView
                            case .settings: settingsView
                            }
                        }
                        .animation(.easeInOut(duration: 0.15), value: selectedTab)
                    }
                    .onChange(of: selectedTaskID) { taskID in
                        scrollToSelectedTask(taskID, proxy: proxy)
                    }
                    .onChange(of: selectedTab) { tab in
                        if tab == .tasks { scrollToSelectedTask(selectedTaskID, proxy: proxy) }
                    }
                }
            }

            if showCommandInput { commandBar }
            tabBar
        }
        .background(NudgeTheme.bg)
        .onAppear { vm.startPolling() }
        .onDisappear {
            vm.stopPolling()
            voice.cancelRecording(reason: "dashboard disappeared")
        }
    }

    // MARK: - Connection Bar

    private var connectionBar: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(vm.isBackendOnline ? Color.green : Color.red.opacity(0.8))
                .frame(width: 6, height: 6)
            if vm.isBackendOnline {
                Text("connected")
                    .font(.system(size: 10)).foregroundColor(NudgeTheme.textDim)
            } else {
                Text("offline")
                    .font(.system(size: 10)).foregroundColor(NudgeTheme.textDim)
                if let last = vm.lastRefresh {
                    Text("— updated \(timeAgo(last))")
                        .font(.system(size: 10)).foregroundColor(NudgeTheme.textDim)
                }
            }
            Spacer()
            Button { Task { await vm.refresh() } } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 10)).foregroundColor(NudgeTheme.textDim)
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 16).padding(.vertical, 4)
        .background(NudgeTheme.cardBg)
    }

    private func timeAgo(_ date: Date) -> String {
        let s = Int(-date.timeIntervalSinceNow)
        if s < 5 { return "just now" }
        if s < 60 { return "\(s)s ago" }
        return "\(s / 60)m ago"
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Nudge Dashboard
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var nudgeDashboard: some View {
        VStack(spacing: NudgeTheme.spacing) {
            HStack(alignment: .top, spacing: NudgeTheme.spacing) {
                tasksCard
                alarmsCard
                micCard
            }.fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: NudgeTheme.spacing) {
                notesCard
                activitySection
            }
        }.padding(16)
    }

    private var tasksCard: some View {
        CardView {
            CardHeader(icon: "checkmark", title: "tasks", count: vm.tasks.count)
            if vm.tasks.isEmpty {
                Text("No tasks yet").font(.system(size: 11)).foregroundColor(NudgeTheme.textDim)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(vm.tasks.prefix(4)) { task in
                        TaskRow(task: task,
                                onCheckbox: { await vm.toggleTask(task) },
                                onText: { openTask(task) })
                    }
                }
            }
            if vm.tasks.count > 4 {
                Button { selectedTab = .tasks } label: {
                    Text("view all \(vm.tasks.count)")
                        .font(.system(size: 10)).foregroundColor(NudgeTheme.accent)
                }.buttonStyle(.plain)
            }
        }.frame(minWidth: 160, maxWidth: .infinity)
    }

    private var alarmsCard: some View {
        CardView {
            CardHeader(icon: "clock", title: "alarms", count: vm.alarms.count)
            if vm.alarms.isEmpty {
                Text("No alarms").font(.system(size: 11)).foregroundColor(NudgeTheme.textDim)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(vm.alarms.prefix(3).enumerated()), id: \.element.id) { i, alarm in
                        Button { selectedTab = .alarms } label: {
                            AlarmRow(alarm: alarm, isNext: i == 0)
                        }.buttonStyle(.plain)
                    }
                }
            }
            if vm.alarms.count > 3 {
                Button { selectedTab = .alarms } label: {
                    Text("view all \(vm.alarms.count)")
                        .font(.system(size: 10)).foregroundColor(NudgeTheme.accent)
                }.buttonStyle(.plain)
            }
        }.frame(minWidth: 160, maxWidth: .infinity)
    }

    private var micCard: some View {
        CardView {
            VStack(spacing: 8) {
                Spacer(minLength: 2)
                Button {
                    voice.toggleVoiceCommand(source: "mic-button")
                } label: {
                    ZStack {
                        Circle()
                            .fill(recorder.isRecording ? Color.red
                                : vm.isProcessing ? NudgeTheme.accent
                                : recorder.permissionDenied ? NudgeTheme.textDim
                                : NudgeTheme.accent.opacity(0.15))
                            .frame(width: 52, height: 52)
                        if recorder.isRecording {
                            Circle()
                                .stroke(Color.red.opacity(0.4), lineWidth: 2)
                                .frame(width: 60, height: 60)
                                .scaleEffect(recorder.isRecording ? 1.2 : 1)
                                .opacity(recorder.isRecording ? 0 : 1)
                                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: false),
                                           value: recorder.isRecording)
                        }
                        if vm.isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: recorder.isRecording ? "stop.fill"
                                : recorder.permissionDenied ? "mic.slash.fill" : "mic.fill")
                                .font(.system(size: recorder.isRecording ? 18 : 22))
                                .foregroundColor(recorder.isRecording ? .white
                                    : recorder.permissionDenied ? .white : NudgeTheme.accent)
                        }
                    }
                }.buttonStyle(.plain)

                if recorder.isRecording {
                    Text(String(format: "%@ recording... %.1fs",
                                voice.activeMode?.label ?? "voice",
                                recorder.recordingDuration))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.red)
                } else if vm.isProcessing {
                    Text("processing...")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(NudgeTheme.textSecondary)
                } else if recorder.permissionDenied {
                    Text("mic access denied")
                        .font(.system(size: 11, weight: .medium)).foregroundColor(.red)
                    Text("click to open Settings")
                        .font(.system(size: 9)).foregroundColor(NudgeTheme.textDim)
                } else if let err = recorder.errorMessage {
                    Text(err).font(.system(size: 10)).foregroundColor(.red.opacity(0.8))
                } else {
                    Text("press to speak")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(NudgeTheme.textSecondary)
                }

                if let dictation = vm.lastDictation, !recorder.isRecording, !vm.isProcessing {
                    Text("copied: \(dictation)")
                        .font(.system(size: 10))
                        .foregroundColor(NudgeTheme.intentNote.opacity(0.8))
                        .multilineTextAlignment(.center).lineLimit(2)
                } else if let last = vm.lastResult, !last.response.isEmpty,
                          !recorder.isRecording, !vm.isProcessing
                {
                    Text(last.response)
                        .font(.system(size: 10))
                        .foregroundColor(NudgeTheme.accent.opacity(0.7))
                        .multilineTextAlignment(.center).lineLimit(2)
                } else if !recorder.isRecording, !vm.isProcessing, !recorder.permissionDenied {
                    Text(". command  , dictate")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(NudgeTheme.textDim)
                }
                Spacer(minLength: 2)
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }.frame(minWidth: 160, maxWidth: .infinity)
    }

    private var notesCard: some View {
        CardView {
            CardHeader(icon: "doc.text", title: "notes",
                       count: vm.notes.count, color: NudgeTheme.intentNote)
            if vm.notes.isEmpty {
                Text("Say \"remember ...\"")
                    .font(.system(size: 11)).foregroundColor(NudgeTheme.textDim)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(vm.notes.prefix(3)) { note in
                        Button { selectedTab = .notes } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(note.displayText)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(NudgeTheme.textPrimary).lineLimit(1)
                                Text(note.timeAgo.isEmpty ? "—" : note.timeAgo)
                                    .font(.system(size: 10)).foregroundColor(NudgeTheme.textDim)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }.buttonStyle(.plain)
                    }
                }
            }
            if vm.notes.count > 3 {
                Button { selectedTab = .notes } label: {
                    Text("view all \(vm.notes.count)")
                        .font(.system(size: 10)).foregroundColor(NudgeTheme.intentNote)
                }.buttonStyle(.plain)
            }
        }.frame(maxWidth: .infinity)
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("recent activity")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(NudgeTheme.textSecondary)

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11)).foregroundColor(NudgeTheme.textDim)
                TextField("search...", text: $vm.searchText)
                    .font(.system(size: 11)).foregroundColor(NudgeTheme.textPrimary)
                    .textFieldStyle(.plain)
                if !vm.searchText.isEmpty {
                    Button { vm.searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11)).foregroundColor(NudgeTheme.textDim)
                            .frame(width: 22, height: 22).contentShape(Circle())
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(NudgeTheme.cardBg).cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(NudgeTheme.cardBorder, lineWidth: 1))

            let entries = Array(vm.filteredActivity.prefix(8))
            if entries.isEmpty {
                Text(vm.searchText.isEmpty ? "No activity yet" : "No matches")
                    .font(.system(size: 11)).foregroundColor(NudgeTheme.textDim)
                    .padding(.vertical, 8)
            } else {
                CardView {
                    ForEach(entries) { entry in
                        if let result = entry.result {
                            ActivityRow(result: result)
                            if entry.id != entries.last?.id {
                                Rectangle().fill(NudgeTheme.cardBorder).frame(height: 1)
                            }
                        }
                    }
                }
            }
        }.frame(maxWidth: .infinity)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Full Tab Views
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var tasksFullView: some View {
        TasksSectionView(vm: vm, selectedTaskID: $selectedTaskID)
    }

    private var alarmsFullView: some View {
        AlarmsSectionView(vm: vm)
    }

    private var notesFullView: some View {
        NotesSectionView(vm: vm)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Settings
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var settingsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "settings", count: 0, color: .clear)

            CardView {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Circle()
                            .fill(vm.isBackendOnline ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(vm.isBackendOnline ? "Backend running" : "Backend offline")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(NudgeTheme.textPrimary)
                    }
                    if let config = vm.backendConfig {
                        SettingsRow(label: "Version", value: config.version)
                    }
                }
            }

            CardView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("providers").font(.system(size: 12, weight: .medium))
                        .foregroundColor(NudgeTheme.textSecondary)
                    if let config = vm.backendConfig {
                        SettingsRow(label: "STT", value: config.sttProvider)
                        SettingsRow(label: "LLM", value: "\(config.llmProvider) (\(config.llmTier))")
                    } else {
                        Text(vm.isBackendOnline ? "loading..." : "connect to see")
                            .font(.system(size: 11)).foregroundColor(NudgeTheme.textDim)
                    }
                }
            }

            CardView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("hotkeys").font(.system(size: 12, weight: .medium))
                        .foregroundColor(NudgeTheme.textSecondary)
                    SettingsRow(label: "Voice command", value: "cmd + shift + .")
                    SettingsRow(label: "Dictation", value: "cmd + shift + ,")
                }
            }

            CardView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("data").font(.system(size: 12, weight: .medium))
                        .foregroundColor(NudgeTheme.textSecondary)
                    SettingsRow(label: "Tasks", value: "\(vm.tasks.count) pending")
                    SettingsRow(label: "Alarms", value: "\(vm.alarms.count) active")
                    SettingsRow(label: "Notes", value: "\(vm.notes.count) saved")
                }
            }

            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("app").font(.system(size: 12, weight: .medium))
                        .foregroundColor(NudgeTheme.textSecondary)
                    Toggle(isOn: Binding(
                        get: { app.launchAtLogin },
                        set: { app.setLaunchAtLogin($0) }
                    )) {
                        Text("Launch at login").font(.system(size: 12))
                            .foregroundColor(NudgeTheme.textSecondary)
                    }
                    .toggleStyle(.switch)
                    .tint(NudgeTheme.accent)

                    HStack(spacing: 8) {
                        SettingsActionButton(
                            label: "Restart backend",
                            icon: "arrow.clockwise",
                            color: NudgeTheme.accent
                        ) { app.restartBackend() }
                        SettingsActionButton(
                            label: "Quit Nudge",
                            icon: "power",
                            color: NudgeTheme.textSecondary
                        ) { app.quit() }
                    }
                }
            }
        }.padding(16)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Command Bar
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var commandBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(NudgeTheme.accent)
            TextField("Type a command...", text: $commandText)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(NudgeTheme.textPrimary)
                .textFieldStyle(.plain)
                .focused($commandFocused)
                .onSubmit {
                    let cmd = commandText
                    commandText = ""
                    Task {
                        await vm.sendCommand(cmd)
                        showCommandInput = false
                    }
                }
                .onExitCommand {
                    showCommandInput = false
                    commandText = ""
                }
            if vm.isProcessing {
                ProgressView().scaleEffect(0.6)
            }
            Button {
                showCommandInput = false
                commandText = ""
            } label: {
                Text("esc").font(.system(size: 10)).foregroundColor(NudgeTheme.textDim)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(NudgeTheme.cardBorder).cornerRadius(4)
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(NudgeTheme.cardBg)
        .overlay(Rectangle().fill(NudgeTheme.cardBorder).frame(height: 1), alignment: .top)
        .onAppear { commandFocused = true }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button { selectedTab = tab } label: {
                    VStack(spacing: 3) {
                        Image(systemName: iconFor(tab)).font(.system(size: 15))
                        Text(tab.rawValue).font(.system(size: 9, weight: .medium))
                    }
                    .foregroundColor(selectedTab == tab ? NudgeTheme.accent : NudgeTheme.textDim)
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                }.buttonStyle(.plain)
            }
            Button { showCommandInput.toggle() } label: {
                VStack(spacing: 3) {
                    Image(systemName: "keyboard").font(.system(size: 15))
                    Text("type").font(.system(size: 9, weight: .medium))
                }
                .foregroundColor(showCommandInput ? NudgeTheme.accent : NudgeTheme.textDim)
                .frame(maxWidth: .infinity).padding(.vertical, 8)
            }.buttonStyle(.plain)
        }
        .background(NudgeTheme.cardBg)
        .overlay(Rectangle().fill(NudgeTheme.cardBorder).frame(height: 1), alignment: .top)
    }

    private func iconFor(_ tab: Tab) -> String {
        switch tab {
        case .nudge: return "mic.fill"
        case .tasks: return "checkmark"
        case .alarms: return "clock"
        case .notes: return "doc.text"
        case .settings: return "gearshape"
        }
    }

    private func openTask(_ task: NudgeTask) {
        selectedTaskID = task.id
        selectedTab = .tasks
    }

    private func scrollToSelectedTask(_ taskID: String?, proxy: ScrollViewProxy) {
        guard selectedTab == .tasks, let taskID else { return }
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.2)) {
                proxy.scrollTo(taskID, anchor: .center)
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Expandable Rows with Loading States
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct ExpandableTaskRow: View {
    let task: NudgeTask
    @ObservedObject var vm: DashboardViewModel
    @Binding var selectedTaskID: String?
    @State private var expanded = false
    @State private var isActing = false

    var isDone: Bool { task.status == "done" }

    var body: some View {
        CardView {
            HStack(spacing: 10) {
                Button {
                    NSLog("[Nudge] ExpandableTaskRow checkbox: \(task.text) status=\(task.status)")
                    guard !isActing else { return }
                    isActing = true
                    Task {
                        await vm.toggleTask(task)
                        isActing = false
                    }
                } label: {
                    ZStack {
                        if isActing {
                            ProgressView().scaleEffect(0.6)
                        } else {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isDone ? NudgeTheme.accent : Color.white.opacity(0.001))
                                .frame(width: 22, height: 22)
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(isDone ? NudgeTheme.accent : NudgeTheme.textDim, lineWidth: 1.5)
                                .frame(width: 22, height: 22)
                            if isDone {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                            }
                        }
                    }
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button { withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() } } label: {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.text)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(isDone ? NudgeTheme.textSecondary : NudgeTheme.textPrimary)
                                .strikethrough(isDone, color: NudgeTheme.textDim)
                                .lineLimit(2)
                            if let priority = task.priority, !isDone {
                                Text(priority).font(.system(size: 10))
                                    .foregroundColor(priority == "high" ? NudgeTheme.intentAlarm : NudgeTheme.textDim)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10)).foregroundColor(NudgeTheme.textDim)
                            .rotationEffect(.degrees(expanded ? 90 : 0))
                    }
                }.buttonStyle(.plain)
            }

            if expanded {
                Divider().background(NudgeTheme.cardBorder)
                ActionButton(label: "Delete", icon: "trash", color: .red, isLoading: false) {
                    Task { await vm.deleteTask(task) }
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: NudgeTheme.cardRadius)
                .stroke(selectedTaskID == task.id ? NudgeTheme.accent.opacity(0.6) : Color.clear,
                        lineWidth: 1)
        )
        .onAppear {
            if selectedTaskID == task.id { expanded = true }
        }
        .onChange(of: selectedTaskID) { taskID in
            if taskID == task.id {
                withAnimation(.easeInOut(duration: 0.2)) { expanded = true }
            }
        }
    }
}

struct ExpandableAlarmRow: View {
    let alarm: NudgeAlarm
    @ObservedObject var vm: DashboardViewModel
    @State private var expanded = false

    var body: some View {
        CardView {
            Button { withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() } } label: {
                HStack(spacing: 10) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 14)).foregroundColor(NudgeTheme.intentAlarm)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(alarm.label)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(NudgeTheme.textPrimary).lineLimit(1)
                        Text(alarm.displayTime)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(NudgeTheme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10)).foregroundColor(NudgeTheme.textDim)
                        .rotationEffect(.degrees(expanded ? 90 : 0))
                }
            }.buttonStyle(.plain)

            if expanded {
                Divider().background(NudgeTheme.cardBorder)
                ActionButton(label: "Cancel alarm", icon: "xmark", color: .red, isLoading: false) {
                    Task { await vm.cancelAlarm(alarm) }
                }
            }
        }
    }
}

struct ExpandableNoteRow: View {
    let note: APINote
    @ObservedObject var vm: DashboardViewModel
    @State private var expanded = false

    var title: String {
        String((note.content.components(separatedBy: .newlines).first ?? note.content).prefix(60))
    }

    var body: some View {
        CardView {
            Button { withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() } } label: {
                HStack(spacing: 10) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 14)).foregroundColor(NudgeTheme.intentNote)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(NudgeTheme.textPrimary).lineLimit(1)
                        Text(note.timeAgo.isEmpty ? "—" : note.timeAgo)
                            .font(.system(size: 10)).foregroundColor(NudgeTheme.textDim)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10)).foregroundColor(NudgeTheme.textDim)
                        .rotationEffect(.degrees(expanded ? 90 : 0))
                }
            }.buttonStyle(.plain)

            if expanded {
                Divider().background(NudgeTheme.cardBorder)
                ScrollView {
                    Text(note.content)
                        .font(.system(size: 12))
                        .foregroundColor(NudgeTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }.frame(maxHeight: 150)

                ActionButton(label: "Delete", icon: "trash", color: .red, isLoading: false) {
                    Task { await vm.deleteNote(note) }
                }
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Shared Components
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct TaskRow: View {
    let task: NudgeTask
    var onCheckbox: (() async -> Void)?
    var onText: (() -> Void)?
    @State private var isActing = false
    var isDone: Bool { task.status == "done" }

    var body: some View {
        HStack(spacing: 8) {
            Button {
                NSLog("[Nudge] TaskRow checkbox tapped: \(task.text) status=\(task.status)")
                guard !isActing else { return }
                isActing = true
                Task {
                    await onCheckbox?()
                    isActing = false
                }
            } label: {
                ZStack {
                    if isActing {
                        ProgressView().scaleEffect(0.55)
                    } else {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isDone ? NudgeTheme.accent : Color.white.opacity(0.001))
                            .frame(width: 20, height: 20)
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isDone ? NudgeTheme.accent : NudgeTheme.textDim, lineWidth: 1.5)
                            .frame(width: 20, height: 20)
                        if isDone {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                        }
                    }
                }
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button { onText?() } label: {
                Text(task.text).font(.system(size: 12))
                    .foregroundColor(isDone ? NudgeTheme.textSecondary : NudgeTheme.textPrimary)
                    .strikethrough(isDone, color: NudgeTheme.textDim).lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.buttonStyle(.plain)
        }
    }
}

struct AlarmRow: View {
    let alarm: NudgeAlarm
    let isNext: Bool
    var body: some View {
        HStack(spacing: 6) {
            Text(alarm.displayTime)
                .font(.system(size: isNext ? 15 : 12,
                              weight: isNext ? .bold : .regular, design: .monospaced))
                .foregroundColor(NudgeTheme.textPrimary).fixedSize()
            if isNext {
                Circle().fill(NudgeTheme.accent).frame(width: 6, height: 6)
            }
            Text(alarm.label).font(.system(size: 12))
                .foregroundColor(isNext ? NudgeTheme.textPrimary : NudgeTheme.textSecondary)
                .lineLimit(1)
        }
    }
}

struct ActionButton: View {
    let label: String
    let icon: String
    let color: Color
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isLoading {
                    ProgressView().scaleEffect(0.5)
                } else {
                    Image(systemName: icon).font(.system(size: 10))
                }
                Text(label).font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(color)
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(color.opacity(0.1)).cornerRadius(6)
        }.buttonStyle(.plain).disabled(isLoading)
    }
}

struct SectionHeader: View {
    let title: String
    let count: Int
    var color: Color = NudgeTheme.textSecondary
    var body: some View {
        HStack {
            Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(color)
            Spacer()
            if count > 0 { Badge(count: count, color: color) }
        }
    }
}

struct EmptyHint: View {
    let text: String
    var body: some View {
        Text(text).font(.system(size: 11)).foregroundColor(NudgeTheme.textDim)
    }
}

struct SettingsRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).font(.system(size: 12)).foregroundColor(NudgeTheme.textSecondary)
            Spacer()
            Text(value).font(.system(size: 12, design: .monospaced))
                .foregroundColor(NudgeTheme.textPrimary)
        }
    }
}

struct SettingsActionButton: View {
    let label: String
    let icon: String
    var color: Color = NudgeTheme.accent
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 10, weight: .semibold))
                Text(label).font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(color.opacity(0.12))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.35), lineWidth: 1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct CardView<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) { content }
            .padding(12).frame(maxWidth: .infinity, alignment: .leading)
            .background(NudgeTheme.cardBg).cornerRadius(NudgeTheme.cardRadius)
            .overlay(RoundedRectangle(cornerRadius: NudgeTheme.cardRadius)
                .stroke(NudgeTheme.cardBorder, lineWidth: 1))
    }
}

struct CardHeader: View {
    let icon: String
    let title: String
    let count: Int
    var color: Color = NudgeTheme.textSecondary
    var body: some View {
        HStack {
            Image(systemName: icon).font(.system(size: 11)).foregroundColor(color)
            Text(title).font(.system(size: 12, weight: .medium)).foregroundColor(color)
            Spacer()
            Badge(count: count, color: color)
        }
    }
}

struct Badge: View {
    let count: Int
    var color: Color = NudgeTheme.textDim
    var body: some View {
        Text("\(count)").font(.system(size: 10, weight: .medium)).foregroundColor(color)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(color.opacity(0.12)).cornerRadius(8)
    }
}

struct IntentBadge: View {
    let intent: String
    var color: Color {
        switch intent {
        case "alarm": return NudgeTheme.intentAlarm
        case "task": return NudgeTheme.intentTask
        case "note": return NudgeTheme.intentNote
        case "query": return NudgeTheme.intentAnswer
        default: return NudgeTheme.textDim
        }
    }
    var label: String { intent == "query" ? "answer" : intent }
    var body: some View {
        Text(label).font(.system(size: 10, weight: .semibold)).foregroundColor(color)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(color.opacity(0.12)).cornerRadius(6).fixedSize()
    }
}

struct ActivityRow: View {
    let result: SessionResult
    var body: some View {
        HStack(spacing: 10) {
            IntentBadge(intent: result.intent)
            Text(result.response.isEmpty ? result.text : result.response)
                .font(.system(size: 12)).foregroundColor(NudgeTheme.textPrimary)
                .lineLimit(1).truncationMode(.tail)
            Spacer(minLength: 4)
            Text(formatTime(result.timestamp))
                .font(.system(size: 10)).foregroundColor(NudgeTheme.textDim).fixedSize()
        }.padding(.vertical, 7)
    }

    private func formatTime(_ iso: String) -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = fmt.date(from: iso) { return relativeTime(d) }
        let fallback = ISO8601DateFormatter()
        if let d = fallback.date(from: iso) { return relativeTime(d) }
        return ""
    }

    private func relativeTime(_ date: Date) -> String {
        let s = Int(-date.timeIntervalSinceNow)
        if s < 60 { return "now" }
        if s < 3600 { return "\(s / 60)m" }
        if s < 86400 { return "\(s / 3600)h" }
        return "\(s / 86400)d"
    }
}
