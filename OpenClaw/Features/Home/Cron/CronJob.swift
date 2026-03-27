import Foundation

struct CronJob: Sendable, Identifiable {
    let id: String
    let name: String
    let enabled: Bool
    let scheduleExpr: String  // cron expr or "every Xm/Xs" for interval jobs
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
        return Formatters.relativeString(for: nextRun)
    }

    var lastRunFormatted: String {
        guard let lastRun else { return "\u{2014}" }
        return Formatters.relativeString(for: lastRun)
    }

    /// Human-readable schedule description from cron expression.
    var scheduleDescription: String {
        // Interval-based jobs (kind: "every") already have readable expr
        if scheduleKind == "every" {
            return scheduleExpr.capitalized
        }

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
        if let m = Int(minute), hour == "*", dom == "*", dow == "*" {
            if m == 0 { return "Every hour" }
            return "Hourly at :\(String(format: "%02d", m))"
        }

        // Daily at HH:MM
        if let h = Int(hour), let m = Int(minute), dom == "*", dow == "*" {
            return "Daily at \(String(format: "%02d:%02d", h, m))"
        }

        // Multiple specific hours (e.g. 0 7,9,11 * * *)
        if minute != "*", hour.contains(","), dom == "*", dow == "*" {
            let hours = hour.split(separator: ",")
            let count = hours.count
            if let first = hours.first, let last = hours.last {
                let m = minute.padding(toLength: 2, withPad: "0", startingAt: 0)
                return "\(count)x daily (\(first):\(m)\u{2013}\(last):\(m))"
            }
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

    let lastError: String?

    init(dto: CronJobDTO) {
        id = dto.id
        name = dto.name
        enabled = dto.enabled
        scheduleKind = dto.schedule.kind
        lastError = dto.state.lastError

        // "every" jobs have everyMs instead of expr
        if let expr = dto.schedule.expr {
            scheduleExpr = expr
        } else if let ms = dto.schedule.everyMs {
            let seconds = ms / 1000
            if seconds >= 3600 {
                scheduleExpr = "every \(seconds / 3600)h"
            } else if seconds >= 60 {
                scheduleExpr = "every \(seconds / 60)m"
            } else {
                scheduleExpr = "every \(seconds)s"
            }
        } else {
            scheduleExpr = dto.schedule.kind
        }
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
