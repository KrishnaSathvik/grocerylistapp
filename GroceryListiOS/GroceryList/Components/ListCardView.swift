import SwiftUI

struct ListCardView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let list: GroceryList
    var isActive: Bool = false

    private var usesAccessibilityLayout: Bool {
        DynamicTypeLayout.usesAccessibilityLayout(dynamicTypeSize)
    }

    var body: some View {
        HStack(alignment: usesAccessibilityLayout ? .top : .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppColors.colorHex(list.tintHex).opacity(0.16))
                    .frame(width: AppSpacing.listIconSize, height: AppSpacing.listIconSize)
                Image(systemName: list.iconName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(AppColors.colorHex(list.tintHex))
            }

            VStack(alignment: .leading, spacing: 6) {
                if usesAccessibilityLayout {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(EssentialText.attributed(list.name))
                            .font(AppTypography.adaptiveCardTitle(for: dynamicTypeSize))
                            .foregroundStyle(AppColors.ink)
                            .essentialTextLayout(dynamicTypeSize: dynamicTypeSize, regularLineLimit: 2)
                        if isActive { activeBadge }
                    }
                } else {
                    HStack(spacing: 8) {
                        Text(list.name)
                            .font(AppTypography.cardTitle)
                            .foregroundStyle(AppColors.ink)
                            .lineLimit(2)
                        if isActive { activeBadge }
                    }
                }

                if list.totalItemCount == 0 {
                    Text("Tap to start shopping")
                        .font(AppTypography.metadata)
                        .foregroundStyle(AppColors.accentSuccess)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(subtitleText)
                        .font(AppTypography.metadata)
                        .foregroundStyle(AppColors.inkSecondary)
                        .lineLimit(usesAccessibilityLayout ? nil : 2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if list.totalItemCount > 0 {
                    ProgressView(value: list.shoppingProgress)
                        .tint(AppColors.accentSuccess)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: AppIcons.chevron)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.inkSecondary)
                .frame(width: AppSpacing.minTapTarget, height: AppSpacing.minTapTarget, alignment: .trailing)
        }
        .appCard()
    }

    private var activeBadge: some View {
        Text("Active")
            .font(AppTypography.badge)
            .tracking(0.2)
            .foregroundStyle(AppColors.accentPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(AppColors.accentPrimary.opacity(0.12))
            .clipShape(Capsule())
    }

    private var subtitleText: String {
        let total = list.totalItemCount
        let toBuy = list.activeItemCount
        let pickedUp = list.completedItemCount
        if pickedUp > 0 {
            return "\(total) items · \(toBuy) to buy · \(pickedUp) picked up"
        }
        if toBuy == total {
            let label = total == 1 ? "item" : "items"
            return "\(total) \(label) to buy"
        }
        return "\(total) total · \(toBuy) to buy"
    }
}

#Preview {
    VStack(spacing: 12) {
        ListCardView(list: GroceryList(name: "Weekly Groceries", tintHex: "#4A7C59"), isActive: true)
        ListCardView(list: GroceryList(name: "A Very Long Grocery List Name For Review", tintHex: "#3D7EA6"))
    }
    .padding()
    .background(AppColors.backgroundGrouped)
}
