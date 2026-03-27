import SwiftUI

/// App-wide type styles built on top of Apple's Dynamic Type scale.
/// Always use these instead of ad-hoc `.font()` calls.
enum AppTypography {
    // MARK: - Display
    /// Large hero numbers (e.g. published count)
    static let heroNumber: Font = .system(.largeTitle, design: .rounded, weight: .bold)

    // MARK: - Headings
    static let screenTitle: Font = .title2.bold()
    static let cardTitle: Font = .subheadline.weight(.semibold)

    // MARK: - Body
    static let body: Font = .subheadline
    static let bodyMono: Font = .subheadline.monospaced()

    // MARK: - Captions
    static let caption: Font = .caption
    static let captionMono: Font = .caption.monospaced()
    static let captionBold: Font = .caption.bold()
    static let micro: Font = .caption2
    static let microMono: Font = .caption2.monospaced()

    // MARK: - Metrics
    /// Stat cell values
    static let metricValue: Font = .title3.bold()
    static let metricLabel: Font = .caption2

    // MARK: - Gauge
    static let gaugePercent: Font = .system(size: 13, weight: .semibold, design: .rounded)

    // MARK: - Labels
    static let sectionLabel: Font = .caption
    static let sectionLabelTracking: CGFloat = 0.5
}
