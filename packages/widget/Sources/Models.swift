import Foundation

struct NudgeTask: Codable, Identifiable, Equatable {
    let id: String
    let text: String
    let status: String
    let priority: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "task_id"
        case text = "description"
        case status
        case priority
        case createdAt = "created_at"
    }
}

struct NudgeAlarm: Codable, Identifiable, Equatable {
    let id: String
    let time: String
    let label: String
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "alarm_id"
        case time = "fire_at"
        case label = "description"
        case createdAt = "created_at"
    }

    var displayTime: String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallback = ISO8601DateFormatter()

        guard let date = isoFormatter.date(from: time) ?? fallback.date(from: time) else {
            return time
        }
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        return fmt.string(from: date)
    }
}

struct APINote: Codable, Identifiable, Equatable {
    let content: String
    let timestamp: String?
    let file: String?

    enum CodingKeys: String, CodingKey {
        case content
        case timestamp = "created_at"
        case file
    }

    var id: String {
        file ?? (timestamp.map { "\(content.hashValue)-\($0)" }
            ?? "\(content.hashValue)-\(content.count)")
    }

    var displayText: String {
        String(content.prefix(80)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var timeAgo: String {
        guard let ts = timestamp else { return "" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: ts) {
            return Self.relativeTime(from: date)
        }
        let fallback = ISO8601DateFormatter()
        if let date = fallback.date(from: ts) {
            return Self.relativeTime(from: date)
        }
        return ""
    }

    private static func relativeTime(from date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 60 { return "now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        if seconds < 86400 { return "\(seconds / 3600)h ago" }
        return "\(seconds / 86400)d ago"
    }
}

struct SessionResult: Codable, Equatable {
    let text: String
    let intent: String
    let confidence: Double
    let response: String
    let error: String
    let duration_ms: Int
    let stt_ms: Int
    let intent_ms: Int
    let agent_ms: Int
    let error_type: String
    let error_source: String
    let provider_name: String
    let session_id: String
    let timestamp: String
}

struct SessionEntry: Codable, Identifiable, Equatable {
    let session_id: String
    let audio_bytes: Int
    let text: String
    let result: SessionResult?

    var id: String { session_id }
}

struct HealthResponse: Codable {
    let status: String
    let version: String
}

struct NudgeConfigInfo: Codable, Equatable {
    let sttProvider: String
    let llmProvider: String
    let llmTier: String
    let hotkey: String
    let version: String

    enum CodingKeys: String, CodingKey {
        case sttProvider = "stt_provider"
        case llmProvider = "llm_provider"
        case llmTier = "llm_tier"
        case hotkey
        case version
    }
}
