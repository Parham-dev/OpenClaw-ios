import Foundation

struct CronRunsResponseDTO: Decodable, Sendable {
    let entries: [CronRunDTO]
}

struct CronRunDTO: Decodable, Sendable {
    let ts: Int
    let jobId: String
    let action: String
    let status: String
    let summary: String?
    let runAtMs: Int
    let durationMs: Int
    let nextRunAtMs: Int?
    let model: String?
    let usage: Usage?
    let delivered: Bool?
    let sessionId: String?
    let sessionKey: String?

    struct Usage: Decodable, Sendable {
        let inputTokens: Int
        let outputTokens: Int
        let totalTokens: Int

        enum CodingKeys: String, CodingKey {
            case inputTokens = "input_tokens"
            case outputTokens = "output_tokens"
            case totalTokens = "total_tokens"
        }
    }
}
