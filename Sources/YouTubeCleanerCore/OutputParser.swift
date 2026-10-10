import Foundation

public enum StreamMessage: Equatable, Sendable {
    case output(String)
    case progress(ProgressEvent)
}

public struct OutputParser: Sendable {
    public static let progressPrefix = "__YOUTUBE_CLEANER_PROGRESS__:"

    private var buffer = ""
    private let decoder: JSONDecoder

    public init() {
        decoder = JSONDecoder()
    }

    public mutating func consume(_ text: String) -> [StreamMessage] {
        buffer += text
        var messages: [StreamMessage] = []

        while let newline = buffer.firstIndex(of: "\n") {
            let line = String(buffer[..<newline]).trimmingCharacters(in: CharacterSet(charactersIn: "\r"))
            buffer.removeSubrange(...newline)
            messages.append(parseLine(line))
        }
        return messages
    }

    public mutating func finish() -> [StreamMessage] {
        guard !buffer.isEmpty else { return [] }
        let line = buffer
        buffer = ""
        return [parseLine(line)]
    }

    private func parseLine(_ line: String) -> StreamMessage {
        if line.hasPrefix(Self.progressPrefix) {
            let payload = String(line.dropFirst(Self.progressPrefix.count))
            if let data = payload.data(using: .utf8),
               let event = try? decoder.decode(ProgressEvent.self, from: data) {
                return .progress(event)
            }
        }
        return .output(Self.cleanTerminalText(line) + "\n")
    }

    public static func cleanTerminalText(_ text: String) -> String {
        let escape = "\u{001B}"
        let pattern = "\(escape)\\[[0-?]*[ -/]*[@-~]"
        let withoutANSI = text.replacingOccurrences(
            of: pattern,
            with: "",
            options: .regularExpression
        )
        return withoutANSI
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\u{8}", with: "")
    }
}
