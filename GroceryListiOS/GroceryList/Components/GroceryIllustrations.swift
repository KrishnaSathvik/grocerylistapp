import SwiftUI

// MARK: - Product spotlight (empty states + onboarding accents)

struct ProductSpotlightIllustration: View {
    var items: [DemoGroceryItems.Item] = DemoGroceryItems.spotlight
    var thumbSize: CGFloat = 64

    var body: some View {
        HStack(spacing: 14) {
            ForEach(items.indices, id: \.self) { index in
                ProductThumbnailView(
                    assetName: items[index].assetName,
                    size: thumbSize,
                    showStubAssets: true
                )
                .rotationEffect(.degrees(index.isMultiple(of: 2) ? -4 : 4))
                .shadow(color: AppColors.cardShadow, radius: 8, y: 4)
            }
        }
        .padding(.vertical, 8)
        .accessibilityHidden(true)
    }
}

// MARK: - Basket (My Lists empty)

struct GroceryBasketIllustration: View {
    var size: CGFloat = 100

    var body: some View {
        ProductSpotlightIllustration(thumbSize: size * 0.42)
    }
}

// MARK: - Paper bag (list detail empty)

struct PaperBagIllustration: View {
    var size: CGFloat = 110

    var body: some View {
        ProductSpotlightIllustration(
            items: [DemoGroceryItems.milk, DemoGroceryItems.bananas, DemoGroceryItems.rice, DemoGroceryItems.chicken],
            thumbSize: size * 0.38
        )
    }
}

// MARK: - Store (store empty)

struct StorefrontIllustration: View {
    var size: CGFloat = 100

    var body: some View {
        VStack(spacing: 16) {
            ProductSpotlightIllustration(
                items: [DemoGroceryItems.milk, DemoGroceryItems.rice, DemoGroceryItems.eggs],
                thumbSize: size * 0.44
            )

            HStack(spacing: 8) {
                tagChip("Costco", tint: "#FDE8E8")
                tagChip("H Mart", tint: "#E8EAF6")
            }
        }
        .accessibilityHidden(true)
    }

    private func tagChip(_ text: String, tint: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(AppColors.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(AppColors.colorHex(tint))
            .clipShape(Capsule())
    }
}

// MARK: - Category grid (categories empty)

struct CategoryGridIllustration: View {
    var size: CGFloat = 100

    private let tiles: [(hex: String, item: DemoGroceryItems.Item, label: String)] = [
        ("#E8F5E9", DemoGroceryItems.bananas, "Produce"),
        ("#E8F4FD", DemoGroceryItems.milk, "Dairy"),
        ("#FFF3E0", DemoGroceryItems.rice, "Pantry"),
        ("#FFF8E1", DemoGroceryItems.gochujang, "Condiments"),
    ]

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
            ],
            spacing: 10
        ) {
            ForEach(Array(tiles.enumerated()), id: \.offset) { _, tile in
                VStack(spacing: 8) {
                    ProductThumbnailView(
                        assetName: tile.item.assetName,
                        size: size * 0.28,
                        showStubAssets: true
                    )
                    Text(tile.label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.inkSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppColors.colorHex(tile.hex))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .frame(maxWidth: size * 2.2)
        .accessibilityHidden(true)
    }
}

#Preview("Illustrations") {
    VStack(spacing: 32) {
        ProductSpotlightIllustration()
        StorefrontIllustration()
        CategoryGridIllustration()
    }
    .padding()
    .background(AppColors.backgroundGrouped)
}
