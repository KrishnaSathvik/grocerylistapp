import SwiftUI
import UIKit

/// System typography — rounded for hero titles and card headings; SF Pro elsewhere.
enum AppTypography {
    // MARK: - Screen & navigation

    static let largeScreenTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let screenTitle = Font.system(.title, design: .rounded).weight(.bold)
    /// Compact top-level title used at accessibility content sizes.
    static let accessibilityScreenTitle = Font.system(.title2, design: .rounded).weight(.bold)
    static let navTitle = Font.system(.headline, design: .rounded).weight(.semibold)

    // MARK: - Cards & empty states

    static let cardTitle = Font.system(.headline, design: .rounded).weight(.semibold)
    /// Card titles at accessibility sizes — still strong, less heroic.
    static let accessibilityCardTitle = Font.system(.title3, design: .rounded).weight(.semibold)
    static let emptyStateTitle = Font.system(.title2, design: .rounded).weight(.bold)

    // MARK: - Body & list content

    static let body = Font.body
    static let bodyMedium = Font.body.weight(.medium)
    static let itemTitle = Font.body.weight(.semibold)

    /// UIKit font matching `itemTitle` (body text style, semibold) with Dynamic Type scaling.
    static func itemTitleUIFont(compatibleWith traitCollection: UITraitCollection? = nil) -> UIFont {
        let base = UIFont.systemFont(ofSize: 17, weight: .semibold)
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: base, compatibleWith: traitCollection)
    }

    // MARK: - Supporting text

    static let metadata = Font.footnote.weight(.medium)
    static let caption = Font.caption.weight(.medium)
    static let sectionLabel = Font.caption2.weight(.bold)

    // MARK: - Controls

    static let button = Font.body.weight(.semibold)
    static let largeButton = Font.body.weight(.semibold)
    static let badge = Font.system(size: 11, weight: .bold)
    static let tiny = Font.system(size: 10, weight: .bold)
    static let tabLabel = Font.system(size: 10, weight: .medium)

    // MARK: - Adaptive helpers

    static func topLevelScreenTitle(for size: DynamicTypeSize) -> Font {
        DynamicTypeLayout.usesCompactScreenTitle(size) ? accessibilityScreenTitle : largeScreenTitle
    }

    static func adaptiveCardTitle(for size: DynamicTypeSize) -> Font {
        DynamicTypeLayout.usesAccessibilityLayout(size) ? accessibilityCardTitle : cardTitle
    }

    // MARK: - Legacy aliases (prefer named tokens above)

    static let largeTitle = largeScreenTitle
    static let title = emptyStateTitle
    static let title2 = cardTitle
    static let sectionHeader = sectionLabel
    static let bodySemibold = button
    static let onboardingTitle = screenTitle
}

// MARK: - Section label styling

extension Text {
    func appSectionLabel() -> some View {
        font(AppTypography.sectionLabel)
            .foregroundStyle(AppColors.inkSecondary)
            .textCase(.uppercase)
            .tracking(0.4)
    }
}
