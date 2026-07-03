import SwiftUI
import UIKit

struct ImageEmptyStateHero: View {
    let imageName: String
    let fallbackSystemImage: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 18) {
            emptyImage

            VStack(spacing: 8) {
                Text(title)
                    .font(AppTypography.emptyStateTitle)
                    .foregroundStyle(AppColors.ink)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.inkSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: 285)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 28)
        .offset(y: -18)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var emptyImage: some View {
        if let uiImage = UIImage(named: imageName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
                .accessibilityHidden(true)
        } else {
            Image(systemName: fallbackSystemImage)
                .font(.system(size: 58, weight: .semibold))
                .foregroundStyle(AppColors.inkSecondary.opacity(0.45))
                .frame(width: 180, height: 180)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Browse tab empty (matches List Detail layout)

/// Pill action + centered illustration — Store/Categories tabs when the active list has no groups yet.
struct BrowseTabEmptyState: View {
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    let imageName: String
    let fallbackSystemImage: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 0) {
            if let actionTitle, let action {
                BrowseTabCustomAddBar(title: actionTitle, action: action)
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.bottom, 12)
            }

            ImageEmptyStateHero(
                imageName: imageName,
                fallbackSystemImage: fallbackSystemImage,
                title: title,
                subtitle: subtitle
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

/// Quick-add-style pill that opens add-store / add-category instead of item entry.
struct BrowseTabCustomAddBar: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(AppColors.accentPrimary)
                    .accessibilityHidden(true)

                Text(title)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.inkSecondary)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(height: AppSpacing.addBarHeight)
            .background(AppColors.addBarBackground, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(AppColors.cardBorder, lineWidth: 1)
            )
            .shadow(color: AppColors.cardShadow.opacity(0.45), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

/// Centered illustration when the tab has no active list (no quick add).
struct BrowseTabInactiveEmptyState: View {
    let imageName: String
    let fallbackSystemImage: String
    let title: String
    let subtitle: String

    var body: some View {
        ImageEmptyStateHero(
            imageName: imageName,
            fallbackSystemImage: fallbackSystemImage,
            title: title,
            subtitle: subtitle
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("List") {
    ImageEmptyStateHero(
        imageName: "empty_list_illustration",
        fallbackSystemImage: "checklist",
        title: "Your list is empty",
        subtitle: "Add your first item above and we'll keep everything organized for shopping."
    )
    .background(AppColors.backgroundGrouped)
}

#Preview("Store") {
    ImageEmptyStateHero(
        imageName: "empty_store_illustration",
        fallbackSystemImage: "storefront",
        title: "No stores yet",
        subtitle: "Items grouped by store will appear here once you start building your list."
    )
    .background(AppColors.backgroundGrouped)
}

#Preview("Categories") {
    ImageEmptyStateHero(
        imageName: "empty_categories_illustration",
        fallbackSystemImage: "square.grid.2x2",
        title: "No categories yet",
        subtitle: "Your grocery items will be organized into categories here automatically."
    )
    .background(AppColors.backgroundGrouped)
}
