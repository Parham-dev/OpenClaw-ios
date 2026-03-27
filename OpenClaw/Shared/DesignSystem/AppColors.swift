import SwiftUI

/// Semantic color palette for the app.
/// Maps intent to color — views never reference raw Color literals directly.
enum AppColors {
    // MARK: - Status
    static let success = Color.green
    static let warning = Color.orange
    static let danger = Color.red
    static let info = Color.blue
    static let neutral = Color.secondary

    // MARK: - Metrics
    static let metricPrimary = Color.blue
    static let metricSecondary = Color.indigo
    static let metricTertiary = Color.purple
    static let metricPositive = Color.green
    static let metricHighlight = Color.teal
    static let metricWarm = Color.orange

    // MARK: - Surfaces
    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let cardBorder = Color(.separator)
    static let pillBackground = Color.blue.opacity(0.12)
    static let pillForeground = Color.blue

    // MARK: - Interactive
    static let primaryAction = Color.blue
    static let destructiveAction = Color.red

    // MARK: - Gauge thresholds
    static func gauge(percent: Double, warn: Double = 60, critical: Double = 80) -> Color {
        percent >= critical ? danger : percent >= warn ? warning : success
    }

    /// Subtle tinted background for stat cells.
    static func tintedBackground(_ color: Color, opacity: Double = 0.08) -> Color {
        color.opacity(opacity)
    }
}
