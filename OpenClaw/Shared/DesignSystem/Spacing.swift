import SwiftUI

/// Consistent spacing scale based on a 4-pt grid — Apple HIG recommended.
enum Spacing {
    /// 4 pt — minimal separation (icon-to-text inline)
    static let xxs: CGFloat = 4
    /// 8 pt — tight grouping (related elements)
    static let xs: CGFloat = 8
    /// 12 pt — default inner padding / stack spacing
    static let sm: CGFloat = 12
    /// 16 pt — card padding / section spacing
    static let md: CGFloat = 16
    /// 24 pt — between cards / major sections
    static let lg: CGFloat = 24
    /// 32 pt — screen-edge insets / hero spacing
    static let xl: CGFloat = 32
    /// 48 pt — large visual breaks
    static let xxl: CGFloat = 48
}
