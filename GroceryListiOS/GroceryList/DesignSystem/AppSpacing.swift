import CoreGraphics

enum AppSpacing {
    static let screenHorizontal: CGFloat = 16
    /// Inset below the status bar for top-level tab titles.
    static let topHeaderTopInset: CGFloat = 8
    /// Space between the header subtitle and the first content block.
    static let topHeaderBottomSpacing: CGFloat = 12
    static let screenHorizontalCompact: CGFloat = 12
    static let cardCornerRadius: CGFloat = 16
    static let rowMinHeight: CGFloat = 76
    static let addBarHeight: CGFloat = 50
    static let buttonCornerRadius: CGFloat = 14
    static let thumbnailSize: CGFloat = 44
    static let listIconSize: CGFloat = 52
    static let sectionSpacing: CGFloat = 12
    static let groupedSectionSpacing: CGFloat = 12
    /// Vertical gap between settings cards on the More tab.
    static let settingsSectionSpacing: CGFloat = 20
    static let groupedSectionCornerRadius: CGFloat = 18
    static let groupedNestedRowCornerRadius: CGFloat = 12
    static let pillHeight: CGFloat = 34
    static let maxContentWidth: CGFloat = 640
    static let minTapTarget: CGFloat = 44
}
