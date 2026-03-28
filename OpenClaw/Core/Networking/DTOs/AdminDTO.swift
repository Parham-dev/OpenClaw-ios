import Foundation

// MARK: - Models Status

struct ModelsStatusDTO: Decodable, Sendable {
    let defaultModel: String?
    let resolvedDefault: String?
    let fallbacks: [String]?
    let imageModel: String?
    let aliases: [String: String]?
}

// MARK: - Agents List

struct AgentDTO: Decodable, Sendable {
    let id: String
    let name: String?
    let identityName: String?
    let identityEmoji: String?
    let model: String?
    let isDefault: Bool?
}

// MARK: - Channels List

struct ChannelsListDTO: Decodable, Sendable {
    let chat: [String: [String]]?
    let usage: UsageInfo?

    struct UsageInfo: Decodable, Sendable {
        let updatedAt: Int?
        let providers: [ProviderUsage]?
    }

    struct ProviderUsage: Decodable, Sendable {
        let provider: String
        let displayName: String?
        let plan: String?
        let windows: [UsageWindow]?
    }

    struct UsageWindow: Decodable, Sendable {
        let label: String
        let usedPercent: Double
    }
}
