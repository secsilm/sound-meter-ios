import Foundation
import SwiftUI

@MainActor
final class MonitorViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var currentDecibel: Double = 0
    @Published var sampleInterval: Double = 1.0
    @Published var shouldRecordAudio = false
    @Published var includeAudioInExport = false
    @Published private(set) var session = RecordingSession(sampleInterval: 1.0, includesAudio: false)
    @Published private(set) var exportItems: [URL] = []
    @Published var statusMessage: String?

    private let service: AudioMonitorServiceProtocol
    private let exporter = CSVExporter()

    var canExport: Bool { !session.samples.isEmpty && !isRecording }
    var hasAudioFile: Bool {
        guard let url = session.audioFileURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    init(service: AudioMonitorServiceProtocol = AudioMonitorService()) {
        self.service = service
        service.onSample = { [weak self] sample in
            Task { @MainActor in
                guard let self else { return }
                self.currentDecibel = sample.decibel
                self.session.samples.append(sample)
            }
        }
        service.onInterruption = { [weak self] began in
            Task { @MainActor in
                self?.statusMessage = began ? "录音被打断，等待系统恢复…" : nil
            }
        }
    }

    func toggleRecording() {
        isRecording ? stop() : start()
    }

    func start() {
        guard !isRecording else { return }
        exportItems = []
        statusMessage = nil
        session = RecordingSession(
            startedAt: .now,
            sampleInterval: sampleInterval,
            includesAudio: shouldRecordAudio
        )

        Task {
            do {
                let audioURL = try await service.startMonitoring(
                    sampleInterval: sampleInterval,
                    recordAudio: shouldRecordAudio
                )
                await MainActor.run {
                    session.audioFileURL = audioURL
                    isRecording = true
                }
            } catch {
                await MainActor.run {
                    statusMessage = "无法开始录制：\(error.localizedDescription)"
                }
            }
        }
    }

    func stop() {
        guard isRecording else { return }
        session.endedAt = .now
        let url = service.stopMonitoring()
        session.audioFileURL = shouldRecordAudio ? url : nil
        isRecording = false
    }

    func prepareExport() {
        guard canExport else { return }
        do {
            var items: [URL] = []
            items.append(try exporter.export(session: session))
            if includeAudioInExport, shouldRecordAudio, hasAudioFile, let audio = session.audioFileURL {
                items.append(audio)
            }
            exportItems = items
            statusMessage = nil
        } catch {
            statusMessage = "导出失败：\(error.localizedDescription)"
        }
    }

    func clearExports() {
        exportItems = []
    }
}
