import Foundation

/// Wrapper returned by {"tool":"cron","args":{"action":"list"}}
struct CronJobListResponse: Decodable, Sendable {
    let jobs: [CronJob]
    let total: Int
}

struct CronJob: Decodable, Sendable, Identifiable {
    let id: String
    let name: String
    let enabled: Bool
    let schedule: Schedule
    let state: State

    struct Schedule: Decodable, Sendable {
        let kind: String
        let expr: String
        let tz: String?
    }

    struct State: Decodable, Sendable {
        let nextRunAtMs: Int?
        let lastRunAtMs: Int?
        let lastRunStatus: String?
        let consecutiveErrors: Int?
    }

    var nextRunFormatted: String {
        guard let ms = state.nextRunAtMs else { return "—" }
        let date = Date(timeIntervalSince1970: Double(ms) / 1000)
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var lastRunStatus: RunStatus {
        switch state.lastRunStatus {
        case "ok":      return .succeeded
        case "error":   return .failed
        case .some:     return .unknown
        case nil:       return .never
        }
    }

    enum RunStatus {
        case succeeded, failed, unknown, never
    }
}
