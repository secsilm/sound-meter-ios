import Foundation

struct NoiseSample: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let decibel: Double

    init(id: UUID = UUID(), timestamp: Date = .now, decibel: Double) {
        self.id = id
        self.timestamp = timestamp
        self.decibel = decibel
    }
}
