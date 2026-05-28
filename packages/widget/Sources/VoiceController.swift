import AppKit
import Foundation

@MainActor
final class VoiceController: ObservableObject {
    enum RecordingMode: String {
        case voiceCommand
        case dictation

        var label: String {
            switch self {
            case .voiceCommand: return "command"
            case .dictation: return "dictation"
            }
        }
    }

    @Published private(set) var activeMode: RecordingMode?

    private let recorder: AudioRecorder
    private let viewModel: DashboardViewModel
    private let onRecordingChanged: (Bool) -> Void

    init(
        recorder: AudioRecorder,
        viewModel: DashboardViewModel,
        onRecordingChanged: @escaping (Bool) -> Void
    ) {
        self.recorder = recorder
        self.viewModel = viewModel
        self.onRecordingChanged = onRecordingChanged
    }

    func toggleVoiceCommand(source: String = "unknown") {
        toggle(.voiceCommand, source: source)
    }

    func toggleDictation(source: String = "unknown") {
        toggle(.dictation, source: source)
    }

    func cancelRecording(reason: String) {
        guard recorder.isRecording || activeMode != nil else { return }
        NSLog("[Nudge Voice] cancel recording reason=\(reason) active=\(activeMode?.label ?? "none")")
        recorder.discardRecording(reason: reason)
        activeMode = nil
        onRecordingChanged(false)
    }

    private func toggle(_ mode: RecordingMode, source: String) {
        NSLog(
            "[Nudge Voice] toggle requested source=\(source) mode=\(mode.label) active=\(activeMode?.label ?? "none") recording=\(recorder.isRecording) processing=\(viewModel.isProcessing)"
        )

        guard !viewModel.isProcessing else {
            NSLog("[Nudge Voice] ignoring \(mode.label) toggle while processing")
            return
        }

        if recorder.isRecording {
            guard activeMode == mode else {
                NSLog(
                    "[Nudge Voice] disregarded \(mode.label) toggle because \(activeMode?.label ?? "unknown") recording is active"
                )
                return
            }
            stopAndSubmit(mode)
            return
        }

        if activeMode != nil {
            NSLog("[Nudge Voice] clearing stale active mode \(activeMode?.label ?? "unknown")")
            activeMode = nil
        }
        start(mode)
    }

    private func start(_ mode: RecordingMode) {
        NSLog(
            "[Nudge Voice] start requested mode=\(mode.label) permissionGranted=\(recorder.permissionGranted) permissionDenied=\(recorder.permissionDenied)"
        )

        if recorder.permissionDenied {
            NSLog("[Nudge Voice] microphone permission denied; opening System Settings")
            openMicrophoneSettings()
            return
        }

        let started = recorder.startRecording()

        if started && recorder.isRecording {
            activeMode = mode
            onRecordingChanged(true)
            viewModel.lastDictation = nil
            viewModel.lastResult = nil
            NSLog("[Nudge Voice] recording active mode=\(mode.label) sampleRate=\(recorder.actualSampleRate)")
        } else if let error = recorder.errorMessage {
            NSLog("[Nudge Voice] recording did not start error=\(error)")
        } else {
            NSLog("[Nudge Voice] recording did not start yet; waiting for permission or hardware")
        }
    }

    private func stopAndSubmit(_ mode: RecordingMode) {
        NSLog("[Nudge Voice] stop requested mode=\(mode.label)")
        let sampleRate = recorder.actualSampleRate
        guard let audioData = recorder.stopRecording() else {
            activeMode = nil
            onRecordingChanged(false)
            NSLog("[Nudge Voice] no usable audio for mode=\(mode.label)")
            return
        }

        activeMode = nil
        onRecordingChanged(false)
        viewModel.isProcessing = true

        let byteCount = audioData.count
        NSLog("[Nudge Voice] submitting mode=\(mode.label) bytes=\(byteCount) sampleRate=\(sampleRate)")

        Task { @MainActor in
            switch mode {
            case .voiceCommand:
                await submitVoiceCommand(audioData, sampleRate: sampleRate)
            case .dictation:
                await submitDictation(audioData, sampleRate: sampleRate)
            }
        }
    }

    private func submitVoiceCommand(_ audioData: Data, sampleRate: Int) async {
        NSLog("[Nudge Voice] process-audio request started")
        let result = await APIClient.shared.processAudio(audioData, sampleRate: sampleRate)
        viewModel.isProcessing = false
        viewModel.lastResult = result
        viewModel.lastDictation = nil

        if let result {
            NSLog(
                "[Nudge Voice] process-audio completed intent=\(result.intent) error=\(result.error.isEmpty ? "none" : result.error)"
            )
        } else {
            NSLog("[Nudge Voice] process-audio failed")
        }

        await viewModel.refresh()
    }

    private func submitDictation(_ audioData: Data, sampleRate: Int) async {
        NSLog("[Nudge Voice] transcribe request started")
        let text = await APIClient.shared.transcribeAudio(audioData, sampleRate: sampleRate)
        viewModel.isProcessing = false

        guard let text, !text.isEmpty else {
            NSLog("[Nudge Voice] transcribe failed or returned empty text")
            return
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        viewModel.lastDictation = text
        viewModel.lastResult = nil
        NSLog("[Nudge Voice] transcribe completed and copied chars=\(text.count)")
    }

    private func openMicrophoneSettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
        ) else { return }
        NSWorkspace.shared.open(url)
    }
}
