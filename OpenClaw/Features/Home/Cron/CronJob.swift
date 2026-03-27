import Foundation

struct CronJob: Sendable, Identifiable {
    let id: String
    let name: String
    let enabled: Bool
    let scheduleExpr: String
    let scheduleKind: String
    let timeZone: String?
    let nextRun: Date?
    let lastRun: Date?
    let status: RunStatus
    let consecutiveErrors: Int

    enum RunStatus: Sendable {
        case succeeded, failed, unknown, never
    }

    var nextRunFormatted: String {
        guard let nextRun else { return "\u{2014}" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: nextRun, relativeTo: Date())
    }

    var lastRunFormatted: String {
        guard let lastRun else { return "\u{2014}" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: lastRun, relativeTo: Date())
    }

    /// Human-readable schedule description from cron expression.
    var scheduleDescription: String {
        let parts = scheduleExpr.split(separator: " ")
        guard parts.count >= 5 else { return scheduleExpr }

        let minute = String(parts[0])
        let hour = String(parts[1])
        let dom = String(parts[2])
        let dow = String(parts[4])

        // Every minute
        if minute == "*" && hour == "*" && dom == "*" && dow == "*" {
            return "Every minute"
        }

        // Every N minutes
        if minute.hasPrefix("*/"), hour == "*", dom == "*" {
            let n = minute.dropFirst(2)
            return "Every \(n) min"
        }

        // Every N hours
        if minute != "*", hour.hasPrefix("*/"), dom == "*" {
            let n = hour.dropFirst(2)
            return "Every \(n) hr"
        }

        // Hourly at :MM
        if minute != "*", !minute.contains("/"), hour == "*", dom == "*", dow == "*" {
            return "Hourly at :\(minute.padding(toLength: 2, withPad: "0", startingAt: 0))"
        }

        // Daily at HH:MM
        if minute != "*", hour != "*", !hour.contains("/"), !hour.contains(","), dom == "*", dow == "*" {
            let h = hour.padding(toLength: 2, withPad: "0", startingAt: 0)
            let m = minute.padding(toLength: 2, withPad: "0", startingAt: 0)
            return "Daily at \(h):\(m)"
        }

        // Specific weekdays
        if dom == "*" && dow != "*" {
            let dayNames = parseDaysOfWeek(dow)
            if let h = Int(hour), let m = Int(minute) {
                return "\(dayNames) at \(String(format: "%02d:%02d", h, m))"
            }
            return dayNames
        }

        return scheduleExpr
    }

    init(dto: CronJobDTO) {
        id = dto.id
        name = dto.name
        enabled = dto.enabled
        scheduleExpr = dto.schedule.expr
        scheduleKind = dto.schedule.kind
        timeZone = dto.schedule.tz
        nextRun = dto.state.nextRunAtMs.map { Date(timeIntervalSince1970: Double($0) / 1000) }
        lastRun = dto.state.lastRunAtMs.map { Date(timeIntervalSince1970: Double($0) / 1000) }
        consecutiveErrors = dto.state.consecutiveErrors ?? 0

        switch dto.state.lastRunStatus {
        case "ok":    status = .succeeded
        case "error": status = .failed
        case .some:   status = .unknown
        case nil:     status = .never
        }
    }
}

private func parseDaysOfWeek(_ expr: String) -> String {
    let map = ["0": "Sun", "1": "Mon", "2": "Tue", "3": "Wed", "4": "Thu", "5": "Fri", "6": "Sat", "7": "Sun"]
    let days = expr.split(separator: ",").compactMap { map[String($0)] }
    if days.isEmpty { return expr }
    return days.joined(separator: ", ")
}
