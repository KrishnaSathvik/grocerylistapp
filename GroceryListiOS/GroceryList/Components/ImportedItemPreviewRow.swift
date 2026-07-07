import SwiftUI

struct ImportedItemPreviewRow: View {
    let item: ImportedListItem

    private var assetName: String? {
        let normalized = CategoryLearningService.normalize(item.name)
        return ItemAssetResolver.bundledAssetName(
            itemName: item.name,
            categoryId: item.categoryId,
            storedAssetName: ProductImageCatalog.assetName(for: normalized)
        )
    }

    private var subtitle: String {
        var parts = [SeedData.categoryLabel(for: item.categoryId)]
        if let storeId = item.storeId {
            let label = SeedData.storeLabel(for: storeId)
            if label != "Unassigned" {
                parts.append(label)
            }
        }
        return parts.joined(separator: " · ")
    }

    private var title: String {
        if let text = item.quantityText, !text.isEmpty {
            return "\(text) \(item.name)"
        }
        if let qty = item.quantityValue, qty > 1 {
            return "\(qty)x \(item.name)"
        }
        return item.name
    }

    var body: some View {
        HStack(spacing: 12) {
            ProductThumbnailView(assetName: assetName, size: AppSpacing.thumbnailSize)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.itemTitle)
                    .foregroundStyle(AppColors.ink)
                    .lineLimit(1)
                Text(subtitle)
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.inkSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
