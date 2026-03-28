import Foundation

struct ModelsConfig: Sendable {
    let defaultModel: String
    let fallbacks: [String]
    let imageModel: String?
    let aliases: [(name: String, model: String)]

    init(dto: ModelsStatusDTO) {
        defaultModel = dto.resolvedDefault ?? dto.defaultModel ?? "unknown"
        fallbacks = dto.fallbacks ?? []
        imageModel = dto.imageModel
        aliases = (dto.aliases ?? [:])
            .map { (name: $0.key, model: $0.value) }
            .sorted { $0.name < $1.name }
    }
}

struct AgentInfo: Sendable, Identifiable {
    let id: String
    let name: String
    let emoji: String
    let model: String?
    let isDefault: Bool

    init(dto: AgentDTO) {
        id = dto.id
        name = dto.identityName ?? dto.name ?? dto.id
        emoji = dto.identityEmoji ?? ""
        model = dto.model
        isDefault = dto.isDefault ?? false
    }
}

struct ChannelsStatus: Sendable {
    let channels: [Channel]
    let providers: [ProviderUsage]

    struct Channel: Sendable, Identifiable {
        let id: String
        let name: String
        let isConnected: Bool
        let accountCount: Int
    }

    struct ProviderUsage: Sendable, Identifiable {
        let id: String
        let displayName: String
        let plan: String?
        let windows: [UsageWindow]
    }

    struct UsageWindow: Sendable, Identifiable {
        let id: String
        let label: String
        let usedPercent: Double
    }

    init(dto: ChannelsListDTO) {
        // Known channels — show connected status
        let connectedKeys: Set<String> = Set(dto.chat?.keys.map { String($0) } ?? [])
        let allChannelNames = ["telegram", "whatsapp", "webchat", "discord", "slack"]
        channels = allChannelNames.map { name in
            let accounts = dto.chat?[name] ?? []
            return Channel(
                id: name,
                name: name.capitalized,
                isConnected: connectedKeys.contains(name),
                accountCount: accounts.count
            )
        }

        providers = (dto.usage?.providers ?? []).map { p in
            ProviderUsage(
                id: p.provider,
                displayName: p.displayName ?? p.provider,
                plan: p.plan?.replacingOccurrences(of: "_", with: " ").capitalized,
                windows: (p.windows ?? []).map { w in
                    UsageWindow(id: "\(p.provider)-\(w.label)", label: w.label, usedPercent: w.usedPercent)
                }
            )
        }
    }
}
