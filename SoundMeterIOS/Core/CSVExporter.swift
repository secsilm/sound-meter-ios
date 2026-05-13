import Foundation

struct CSVExporter {
    func export(session: RecordingSession) throws -> URL {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var lines = ["timestamp,decibel"]
        lines += session.samples.map { "\(formatter.string(from: $0.timestamp)),\(String(format: \"%.2f\", $0.decibel))" }

        let csv = lines.joined(separator: "\n")
        let output = FileManager.default.temporaryDirectory.appendingPathComponent("noise-session-\(session.id.uuidString).csv")
        try csv.write(to: output, atomically: true, encoding: .utf8)
        return output
    }
}
