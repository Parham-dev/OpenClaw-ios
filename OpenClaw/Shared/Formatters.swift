import Foundation

/// Cached formatters — never create DateFormatter/RelativeDateTimeFormatter in computed properties or view bodies.
enum Formatters {
    static let relative: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f
    }()

    static let absoluteDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    static func relativeString(for date: Date) -> String {
        relative.localizedString(for: date, relativeTo: Date())
    }

    static func absoluteString(for date: Date) -> String {
        absoluteDate.string(from: date)
    }
}
