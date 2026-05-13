import AVFoundation
import Foundation

protocol AudioMonitorServiceProtocol: AnyObject {
    var onSample: ((NoiseSample) -> Void)? { get set }
    var onInterruption: ((Bool) -> Void)? { get set }
    var isMonitoring: Bool { get }

    func startMonitoring(sampleInterval: TimeInterval, recordAudio: Bool) async throws -> URL?
    func stopMonitoring() -> URL?
}

final class AudioMonitorService: NSObject, AudioMonitorServiceProtocol {
    var onSample: ((NoiseSample) -> Void)?
    var onInterruption: ((Bool) -> Void)?
    private(set) var isMonitoring: Bool = false

    private let session = AVAudioSession.sharedInstance()
    private var recorder: AVAudioRecorder?
    private var recorderURL: URL?
    private var timer: DispatchSourceTimer?
    private var currentRecordAudio = false

    override init() {
        super.init()
        registerSessionNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func startMonitoring(sampleInterval: TimeInterval, recordAudio: Bool) async throws -> URL? {
        try session.setCategory(
            .playAndRecord,
            mode: .measurement,
            options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers]
        )
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        currentRecordAudio = recordAudio
        let url = try prepareRecorder()
        recorderURL = url

        recorder?.isMeteringEnabled = true
        recorder?.record()

        startSampling(sampleInterval: sampleInterval)
        isMonitoring = true
        return recordAudio ? url : nil
    }

    func stopMonitoring() -> URL? {
        timer?.cancel()
        timer = nil

        recorder?.stop()
        let url = recorderURL
        recorder = nil

        try? session.setActive(false, options: .notifyOthersOnDeactivation)
        isMonitoring = false

        if !currentRecordAudio, let url {
            try? FileManager.default.removeItem(at: url)
            recorderURL = nil
            return nil
        }
        recorderURL = nil
        return url
    }

    private func startSampling(sampleInterval: TimeInterval) {
        timer?.cancel()

        let t = DispatchSource.makeTimerSource(queue: .global(qos: .userInitiated))
        t.schedule(deadline: .now(), repeating: sampleInterval)
        t.setEventHandler { [weak self] in
            guard let self, let recorder = self.recorder, recorder.isRecording else { return }
            recorder.updateMeters()
            let raw = recorder.averagePower(forChannel: 0)
            let normalized = Self.normalizeDecibel(raw)
            self.onSample?(NoiseSample(decibel: normalized))
        }
        t.resume()
        self.timer = t
    }

    private func prepareRecorder() throws -> URL {
        let url = Self.makeAudioURL()
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        recorder = try AVAudioRecorder(url: url, settings: settings)
        return url
    }

    private static func makeAudioURL() -> URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let ts = Int(Date().timeIntervalSince1970)
        return base.appendingPathComponent("noise-\(ts).m4a")
    }

    private static func normalizeDecibel(_ db: Float) -> Double {
        let clamped = max(-80, min(0, db))
        return Double(clamped) + 100.0
    }

    // MARK: - Session notifications

    private func registerSessionNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(handleInterruption(_:)),
                       name: AVAudioSession.interruptionNotification, object: nil)
        nc.addObserver(self, selector: #selector(handleRouteChange(_:)),
                       name: AVAudioSession.routeChangeNotification, object: nil)
        nc.addObserver(self, selector: #selector(handleMediaServicesReset(_:)),
                       name: AVAudioSession.mediaServicesWereResetNotification, object: nil)
    }

    @objc private func handleInterruption(_ note: Notification) {
        guard
            let info = note.userInfo,
            let raw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: raw)
        else { return }

        switch type {
        case .began:
            onInterruption?(true)
        case .ended:
            let opts = (info[AVAudioSessionInterruptionOptionKey] as? UInt)
                .map { AVAudioSession.InterruptionOptions(rawValue: $0) } ?? []
            guard opts.contains(.shouldResume), isMonitoring else { return }
            do {
                try session.setActive(true, options: .notifyOthersOnDeactivation)
                recorder?.record()
                onInterruption?(false)
            } catch {
                onInterruption?(true)
            }
        @unknown default:
            break
        }
    }

    @objc private func handleRouteChange(_ note: Notification) {
        guard isMonitoring, let recorder, !recorder.isRecording else { return }
        recorder.record()
    }

    @objc private func handleMediaServicesReset(_ note: Notification) {
        recorder?.stop()
        recorder = nil
        timer?.cancel()
        timer = nil
        isMonitoring = false
        onInterruption?(true)
    }
}
