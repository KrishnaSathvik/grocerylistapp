import SwiftUI

/// System typography — rounded for hero titles and card headings; SF Pro elsewhere.
enum AppTypography {
    // MARK: - Screen & navigation

    static let largeScreenTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let screenTitle = Font.system(.title, design: .rounded).weight(.bold)
    static let navTitle = Font.system(.headline, design: .rounded).weight(.semibold)

    // MARK: - Cards & empty states

    static let cardTitle = Font.system(.headline, design: .rounded).weight(.semibold)
    static let emptyStateTitle = Font.system(.title2, design: .rounded).weight(.bold)

    // MARK: - Body & list content

    static let body = Font.body
    static let bodyMedium = Font.body.weight(.medium)
    static let itemTitle = Font.body.weight(.semibold)

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
