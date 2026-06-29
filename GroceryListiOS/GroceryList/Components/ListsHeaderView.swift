import SwiftUI
import SwiftData

// MARK: - Shared tab chrome

struct TabHeaderActionButton: View {
    let systemName: String
    var accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(AppColors.accentPrimary)
                .clipShape(Circle())
                .shadow(color: AppColors.accentPrimary.opacity(0.25), radius: 8, y: 3)
        }
        .accessibilityLabel(accessibilityLabel)
    }
}

struct TabScreenHeader<Action: View>: View {
    let title: String
    var metadata: String?
    @ViewBuilder let action: () -> Action

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(AppTypography.largeScreenTitle)
                    .foregroundStyle(AppColors.ink)

                if let metadata {
                    Text(metadata)
                        .font(AppTypography.metadata)
                        .foregroundStyle(AppColors.inkSecondary)
                }
            }

            Spacer(minLength: 0)

            action()
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .safeAreaPadding(.top, AppSpacing.topHeaderTopInset)
        .padding(.bottom, AppSpacing.topHeaderBottomSpacing)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension TabScreenHeader where Action == EmptyView {
    init(title: String, metadata: String? = nil) {
        self.title = title
        self.metadata = metadata
        self.action = { EmptyView() }
    }
}

// MARK: - Lists tab metadata

enum MyListsHeaderMetadata {
    static func subtitle(
        listCount: Int,
        totalItemsToBuy: Int,
        totalPickedUp: Int
    ) -> String {
        if listCount == 0 {
            return "Smart shopping, sorted for you"
        }
        let listLabel = listCount == 1 ? "list" : "lists"
        var text = "\(listCount) \(listLabel) · \(totalItemsToBuy) to buy"
        if totalPickedUp > 0 {
            text += " · \(totalPickedUp) picked up"
        }
        return text
    }
}

#Preview("Lists Header") {
    TopLevelHeader(
        title: "My Lists",
        metadata: MyListsHeaderMetadata.subtitle(listCount: 2, totalItemsToBuy: 8, totalPickedUp: 3)
    )
    .background(AppScreenBackground())
}

#Preview("Store Header") {
    TopLevelHeader(
        title: "Store",
        metadata: "Weekly Groceries · 2 stores"
    ) {
        TabHeaderActionButton(systemName: AppIcons.add, accessibilityLabel: "Add item", action: {})
    }
    .background(AppScreenBackground())
}
