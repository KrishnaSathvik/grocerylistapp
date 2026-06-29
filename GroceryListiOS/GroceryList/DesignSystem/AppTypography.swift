import SwiftUI

/// System typography — rounded for hero titles and card headings; SF Pro elsewhere.
enum AppTypography {
    // MARK: - Screen & navigation

    static let largeScreenTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let screenTitle = Font.system(size: 30, weight: .bold, design: .rounded)
    static let navTitle = Font.system(size: 17, weight: .semibold, design: .rounded)

    // MARK: - Cards & empty states

    static let cardTitle = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let emptyStateTitle = Font.system(size: 22, weight: .bold, design: .rounded)

    // MARK: - Body & list content

    static let body = Font.system(size: 16, weight: .regular)
    static let bodyMedium = Font.system(size: 16, weight: .medium)
    static let itemTitle = Font.system(size: 16, weight: .semibold)

    // MARK: - Supporting text

    static let metadata = Font.system(size: 13, weight: .medium)
    static let caption = Font.system(size: 12, weight: .medium)
    static let sectionLabel = Font.system(size: 12, weight: .bold)

    // MARK: - Controls

    static let button = Font.system(size: 16, weight: .semibold)
    static let largeButton = Font.system(size: 17, weight: .semibold)
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
