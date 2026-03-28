import Foundation

struct SessionEntry: Sendable, Identifiable {
    let id: String
    let kind: Kind
    let displayName: String
    let model: String?
    let status: SessionStatus
    let updatedAt: Date?
    let startedAt: Date?
    let totalTokens: Int
    let contextTokens: Int
    let costUsd: Double
    let childSessionCount: Int

    /// How full the context window is (0.0–1.0).
    var contextUsage: Double {
        guard contextTokens > 0 else { return 0 }
        return min(Double(totalTokens) / Double(contextTokens), 1.0)
    }

    enum Kind: Sendable {
        case main
        case cron(jobId: String)
        case subagent
    }

    enum SessionStatus: Sendable {
        case running, done, unknown
    }

    var updatedAtFormatted: String {
        guard let updatedAt else { return "\u{2014}" }
        return Formatters.relativeString(for: updatedAt)
    }

    var startedAtFormatted: String {
        guard let startedAt else { return "\u{2014}" }
        return Formatters.absoluteString(for: startedAt)
    }

    init(dto: SessionListDTO) {
        id = dto.key
        displayName = dto.displayName ?? dto.label ?? dto.key
        model = dto.model
        totalTokens = dto.totalTokens ?? 0
        contextTokens = dto.contextTokens ?? 0
        costUsd = dto.estimatedCostUsd ?? 0
        childSessionCount = dto.childSessions?.count ?? 0
        updatedAt = dto.updatedAt.map { Date(timeIntervalSince1970: Double($0) / 1000) }
        startedAt = dto.startedAt.map { Date(timeIntervalSince1970: Double($0) / 1000) }

        switch dto.status {
        case "running": status = .running
        case "done":    status = .done
        default:        status = .unknown
        }

        if id == "agent:orchestrator:main" {
            kind = .main
        } else if id.hasPrefix("agent:orchestrator:cron:") && !id.contains(":run:") {
            let jobId = String(id.dropFirst("agent:orchestrator:cron:".count))
            kind = .cron(jobId: jobId)
        } else {
            kind = .subagent
        }
    }
}
