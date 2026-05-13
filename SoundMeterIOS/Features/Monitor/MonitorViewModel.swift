import Foundation
import SwiftUI

@MainActor
final class MonitorViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var currentDecibel: Double = 0
    @Published var sampleInterval: Double = 1.0
    @Published var shouldRecordAudio = false
    @Published var includeAudioInExport = false
    @Published var session = RecordingSession(sampleInterval: 1.0, includesAudio: false)
    @Published var exportedCSVURL: URL?

    private let service: AudioMonitorServiceProtocol
    private let exporter = CSVExporter()

    init(service: AudioMonitorServiceProtocol = AudioMonitorService()) {
        self.service = service
        service.onSample = { [weak self] sample in
            Task { @MainActor in
                self?.currentDecibel = sample.decibel
                self?.session.samples.append(sample)
            }
        }
    }

    func toggleRecording() {
        isRecording ? stop() : start()
    }

    func start() {
        guard !isRecording else { return }

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
                print("Start monitoring failed: \(error.localizedDescription)")
            }
        }
    }

    func stop() {
        guard isRecording else { return }
        session.endedAt = .now
        if shouldRecordAudio {
            session.audioFileURL = service.stopMonitoring()
        } else {
            _ = service.stopMonitoring()
        }
        isRecording = false
    }

    func exportCSV() {
        do {
            exportedCSVURL = try exporter.export(session: session)
        } catch {
            print("CSV export failed: \(error.localizedDescription)")
        }
    }
}
