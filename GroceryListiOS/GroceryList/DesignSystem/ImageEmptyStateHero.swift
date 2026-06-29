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
