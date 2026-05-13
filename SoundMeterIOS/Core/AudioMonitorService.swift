import AVFoundation
import Foundation

protocol AudioMonitorServiceProtocol {
    var onSample: ((NoiseSample) -> Void)? { get set }
    var isMonitoring: Bool { get }

    func startMonitoring(sampleInterval: TimeInterval, recordAudio: Bool) async throws -> URL?
    func stopMonitoring() -> URL?
}

final class AudioMonitorService: NSObject, AudioMonitorServiceProtocol {
    var onSample: ((NoiseSample) -> Void)?
    private(set) var isMonitoring: Bool = false

    private let session = AVAudioSession.sharedInstance()
    private var recorder: AVAudioRecorder?
    private var timer: DispatchSourceTimer?

    func startMonitoring(sampleInterval: TimeInterval, recordAudio: Bool) async throws -> URL? {
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let outputURL = try prepareRecorderIfNeeded(recordAudio: recordAudio)

        recorder?.isMeteringEnabled = true
        recorder?.record()

        startSampling(sampleInterval: sampleInterval)
        isMonitoring = true
        return outputURL
    }

    func stopMonitoring() -> URL? {
        timer?.cancel()
        timer = nil

        recorder?.stop()
        let savedURL = recorder?.url
        recorder = nil

        try? session.setActive(false)
        isMonitoring = false
        return savedURL
    }

    private func startSampling(sampleInterval: TimeInterval) {
        timer?.cancel()

        let timer = DispatchSource.makeTimerSource(queue: .global(qos: .userInitiated))
        timer.schedule(deadline: .now(), repeating: sampleInterval)
        timer.setEventHandler { [weak self] in
            guard let self, let recorder = self.recorder else { return }
            recorder.updateMeters()
            let db = recorder.averagePower(forChannel: 0)
            let normalized = Self.normalizeDecibel(db)
            self.onSample?(NoiseSample(decibel: normalized))
        }
        timer.resume()
        self.timer = timer
    }

    private func prepareRecorderIfNeeded(recordAudio: Bool) throws -> URL? {
        let url = Self.makeAudioURL()
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let recorder = try AVAudioRecorder(url: url, settings: settings)
        self.recorder = recorder

        if !recordAudio {
            try? FileManager.default.removeItem(at: url)
            return nil
        }

        return url
    }

    private static func makeAudioURL() -> URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return base.appendingPathComponent("noise-\(Int(Date().timeIntervalSince1970)).m4a")
    }

    private static func normalizeDecibel(_ db: Float) -> Double {
        let clamped = max(-80, min(0, db))
        return Double(clamped + 100)
    }
}
