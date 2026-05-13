import Foundation

struct RecordingSession: Identifiable {
    let id: UUID
    let startedAt: Date
    var endedAt: Date?
    var sampleInterval: TimeInterval
    var includesAudio: Bool
    var audioFileURL: URL?
    var samples: [NoiseSample]

    init(
        id: UUID = UUID(),
        startedAt: Date = .now,
        endedAt: Date? = nil,
        sampleInterval: TimeInterval,
        includesAudio: Bool,
        audioFileURL: URL? = nil,
        samples: [NoiseSample] = []
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.sampleInterval = sampleInterval
        self.includesAudio = includesAudio
        self.audioFileURL = audioFileURL
        self.samples = samples
    }
}
