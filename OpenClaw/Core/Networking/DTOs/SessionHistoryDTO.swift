import Foundation

struct SessionHistoryDTO: Decodable, Sendable {
    let sessionKey: String
    let messages: [SessionMessageDTO]
    let truncated: Bool?
    let droppedMessages: Bool?
    let contentTruncated: Bool?
    let bytes: Int?
}

struct SessionMessageDTO: Decodable, Sendable {
    let role: String
    let content: [ContentItem]?
    let model: String?
    let provider: String?
    let stopReason: String?
    let timestamp: Int?
    let toolCallId: String?
    let toolName: String?
    let isError: Bool?

    struct ContentItem: Decodable, Sendable {
        let type: String
        // text content
        let text: String?
        // thinking content
        let thinking: String?
        // toolCall content
        let id: String?
        let name: String?
        let arguments: Arguments?
    }

    /// Tool call arguments — decoded as a flexible dictionary since args vary per tool.
    struct Arguments: Decodable, Sendable {
        let raw: [String: AnyCodable]

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            raw = (try? container.decode([String: AnyCodable].self)) ?? [:]
        }

        var summary: String {
            raw.map { "\($0.key): \($0.value.stringValue)" }
                .sorted()
                .joined(separator: ", ")
        }
    }
}

/// Type-erased Codable wrapper for flexible JSON values.
struct AnyCodable: Decodable, Sendable {
    let value: Any & Sendable

    var stringValue: String {
        switch value {
        case let s as String: return s
        case let n as Int: return "\(n)"
        case let n as Double: return "\(n)"
        case let b as Bool: return b ? "true" : "false"
        default: return "\(value)"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let s = try? container.decode(String.self) { value = s }
        else if let i = try? container.decode(Int.self) { value = i }
        else if let d = try? container.decode(Double.self) { value = d }
        else if let b = try? container.decode(Bool.self) { value = b }
        else { value = "" }
    }
}
