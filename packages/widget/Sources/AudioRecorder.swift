import AVFoundation
import Foundation

@MainActor
class AudioRecorder: ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var permissionGranted = false
    @Published var permissionDenied = false
    @Published var errorMessage: String?

    private(set) var actualSampleRate: Int = 16000
    private var audioEngine: AVAudioEngine?
    private var audioBuffer = Data()
    private var startTime: Date?
    private var timer: Timer?

    func requestPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        NSLog("[Nudge Audio] permission status: \(status.rawValue)")
        switch status {
        case .authorized:
            permissionGranted = true
            permissionDenied = false
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    NSLog("[Nudge Audio] permission request result: \(granted)")
                    self?.permissionGranted = granted
                    self?.permissionDenied = !granted
                }
            }
        case .denied, .restricted:
            permissionGranted = false
            permissionDenied = true
        @unknown default:
            permissionGranted = false
            permissionDenied = true
        }
    }

    @discardableResult
    func startRecording() -> Bool {
        errorMessage = nil
        NSLog("[Nudge Audio] startRecording granted=\(permissionGranted) denied=\(permissionDenied)")

        guard permissionGranted else {
            requestPermission()
            return false
        }

        audioBuffer = Data()
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let hwFormat = inputNode.outputFormat(forBus: 0)
        NSLog("[Nudge Audio] hardware format rate=\(hwFormat.sampleRate) channels=\(hwFormat.channelCount)")

        guard hwFormat.sampleRate > 0, hwFormat.channelCount > 0 else {
            errorMessage = "No microphone detected"
            NSLog("[Nudge Audio] no microphone detected")
            return false
        }

        actualSampleRate = Int(hwFormat.sampleRate)

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: hwFormat) { [weak self] buffer, _ in
            guard let floatData = buffer.floatChannelData else { return }
            let frameCount = Int(buffer.frameLength)

            var int16Samples = [Int16](repeating: 0, count: frameCount)
            for i in 0..<frameCount {
                let clamped = max(-1.0, min(1.0, floatData[0][i]))
                int16Samples[i] = Int16(clamped * Float(Int16.max))
            }

            let data = int16Samples.withUnsafeBufferPointer { Data(buffer: $0) }
            DispatchQueue.main.async { self?.audioBuffer.append(data) }
        }

        do {
            try engine.start()
            audioEngine = engine
            isRecording = true
            startTime = Date()
            NSLog("[Nudge Audio] recording started sampleRate=\(actualSampleRate)")

            let capturedStart = Date()
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.recordingDuration = Date().timeIntervalSince(capturedStart)
                }
            }
            return true
        } catch {
            errorMessage = "Mic error: \(error.localizedDescription)"
            NSLog("[Nudge Audio] mic error: \(error.localizedDescription)")
            engine.inputNode.removeTap(onBus: 0)
            return false
        }
    }

    @discardableResult
    func stopRecording() -> Data? {
        timer?.invalidate()
        timer = nil
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        isRecording = false

        let data = audioBuffer
        audioBuffer = Data()
        recordingDuration = 0
        startTime = nil

        let minBytes = actualSampleRate / 5 * 2
        NSLog("[Nudge Audio] recording stopped bytes=\(data.count) sampleRate=\(actualSampleRate)")
        guard data.count > minBytes else {
            errorMessage = "Too short — hold longer"
            NSLog("[Nudge Audio] recording discarded as too short")
            return nil
        }
        return data
    }

    func discardRecording(reason: String) {
        timer?.invalidate()
        timer = nil
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        isRecording = false
        audioBuffer = Data()
        recordingDuration = 0
        startTime = nil
        errorMessage = nil
        NSLog("[Nudge Audio] recording discarded reason=\(reason)")
    }
}
