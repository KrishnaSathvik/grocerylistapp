import SwiftUI

enum CategoryIconOption: Equatable {
    case system(String)
    case asset(String)

    var accessibilityLabel: String {
        switch self {
        case .system(let name):
            name.replacingOccurrences(of: ".", with: " ").replacingOccurrences(of: "-", with: " ")
        case .asset(let name):
            name.replacingOccurrences(of: "category-", with: "").replacingOccurrences(of: "-", with: " ")
        }
    }
}

enum CustomCategoryIconOptions {
    static let symbols: [(name: String, label: String)] = [
        ("cart.fill", "Shopping cart"),
        ("basket.fill", "Basket"),
        ("bag.fill", "Bag"),
        ("storefront.fill", "Storefront"),
        ("leaf.fill", "Leaf"),
        ("fork.knife", "Fork and knife"),
        ("cup.and.saucer.fill", "Cup and saucer"),
        ("takeoutbag.and.cup.and.straw.fill", "Takeout"),
        ("house.fill", "House"),
        ("sparkles", "Sparkles"),
        ("heart.fill", "Heart"),
        ("pawprint.fill", "Paw print"),
        ("drop.fill", "Drop"),
        ("star.fill", "Star"),
        ("square.grid.2x2.fill", "Grid"),
        ("shippingbox.fill", "Shipping box"),
    ]
}

enum CategoryIconRendering {
    static func isSFSymbolName(_ value: String) -> Bool {
        value.contains(".") || value.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == ".") }
    }

    static func resolvedCategoryId(for categoryId: String) -> String {
        GroceryCatalog.category(for: categoryId)?.id ?? categoryId
    }

    static func resolvedAssetName(for categoryId: String) -> String? {
        let resolvedId = resolvedCategoryId(for: categoryId)
        let primary = GroceryCatalog.categoryAssetName(for: resolvedId)
        if CatalogAssetAvailability.isUsable(primary) { return primary }
        if CatalogAssetAvailability.isUsable("category-misc") { return "category-misc" }
        return nil
    }
}

/// Renders built-in catalog category assets or custom category icons.
struct CategoryIconView: View {
    let categoryId: String
    var containerSize: CGFloat = 44
    var cornerRadius: CGFloat = 12

    private var resolvedCategoryId: String {
        CategoryIconRendering.resolvedCategoryId(for: categoryId)
    }

    private var isCustom: Bool {
        CategoryService.customCategories().contains { $0.id == resolvedCategoryId }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(AppColors.categoryTint(for: resolvedCategoryId))
                .frame(width: containerSize, height: containerSize)

            if isCustom {
                customIcon
            } else {
                catalogIcon
            }
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var customIcon: some View {
        let stored = CategoryService.emoji(for: resolvedCategoryId)
        let accent = AppColors.colorHex(CategoryService.colorHex(for: resolvedCategoryId) ?? "#6B7D8E")
        if CategoryIconRendering.isSFSymbolName(stored) {
            Image(systemName: stored)
                .font(.system(size: containerSize * 0.42, weight: .semibold))
                .foregroundStyle(accent)
        } else {
            EmojiLabel(emoji: stored, size: containerSize * 0.55)
        }
    }

    @ViewBuilder
    private var catalogIcon: some View {
        if let assetName = CategoryIconRendering.resolvedAssetName(for: resolvedCategoryId) {
            ProductThumbnailView(assetName: assetName, size: containerSize, badgeFill: true)
        } else {
            Image(systemName: AppIcons.categorySymbol(for: resolvedCategoryId))
                .font(.system(size: containerSize * 0.42, weight: .semibold))
                .foregroundStyle(AppColors.ink.opacity(0.65))
        }
    }
}

struct CategoryIconPickerButton: View {
    let option: CategoryIconOption
    let isSelected: Bool
    var accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        isSelected
                            ? AppColors.accentSuccess.opacity(0.18)
                            : AppColors.backgroundPrimary
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(
                                isSelected ? AppColors.accentPrimary : AppColors.cardBorder,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )

                iconContent
                    .foregroundStyle(AppColors.ink.opacity(0.8))
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var iconContent: some View {
        switch option {
        case .system(let name):
            Image(systemName: name)
                .font(.system(size: 20, weight: .semibold))
        case .asset(let name):
            ProductThumbnailView(assetName: name, size: 44, badgeFill: true)
        }
    }
}
