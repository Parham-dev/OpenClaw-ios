import Foundation

struct CronRun: Sendable, Identifiable {
    /// Use the entry timestamp as ID — unique per run entry.
    let id: String

    let jobId: String
    let status: CronJob.RunStatus
    let summary: String?
    let runAt: Date
    let duration: TimeInterval
    let nextRun: Date?
    let model: String?
    let inputTokens: Int
    let outputTokens: Int
    let totalTokens: Int
    /// Full session key for sessions_history API (e.g. "agent:orchestrator:subagent:UUID")
    let sessionKey: String?
    /// Short session ID (UUID only)
    let sessionId: String?

    var durationFormatted: String {
        let seconds = Int(duration / 1000)
        if seconds < 60 { return "\(seconds)s" }
        let minutes = seconds / 60
        let remaining = seconds % 60
        return "\(minutes)m \(remaining)s"
    }

    var runAtFormatted: String {
        Formatters.relativeString(for: runAt)
    }

    var runAtAbsolute: String {
        Formatters.absoluteString(for: runAt)
    }

    init(dto: CronRunDTO) {
        id = "\(dto.ts)"
        jobId = dto.jobId
        summary = dto.summary
        runAt = Date(timeIntervalSince1970: Double(dto.runAtMs) / 1000)
        duration = Double(dto.durationMs)
        nextRun = dto.nextRunAtMs.map { Date(timeIntervalSince1970: Double($0) / 1000) }
        model = dto.model
        inputTokens = dto.usage?.inputTokens ?? 0
        outputTokens = dto.usage?.outputTokens ?? 0
        totalTokens = dto.usage?.totalTokens ?? 0
        sessionKey = dto.sessionKey
        sessionId = dto.sessionId

        switch dto.status {
        case "ok":    status = .succeeded
        case "error": status = .failed
        default:      status = .unknown
        }
    }
}
