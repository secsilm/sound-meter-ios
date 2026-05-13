import Foundation

struct CSVExporter {
    func export(session: RecordingSession) throws -> URL {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var lines = ["timestamp,decibel"]
        for sample in session.samples {
            let ts = formatter.string(from: sample.timestamp)
            let db = String(format: "%.2f", sample.decibel)
            lines.append("\(ts),\(db)")
        }

        let csv = lines.joined(separator: "\n")
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("noise-session-\(session.id.uuidString).csv")
        try csv.write(to: output, atomically: true, encoding: .utf8)
        return output
    }
}
