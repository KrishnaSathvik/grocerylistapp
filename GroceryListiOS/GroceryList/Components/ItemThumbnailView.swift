import SwiftUI

struct ItemThumbnailView: View {
    let item: GroceryItem
    var size: CGFloat = AppSpacing.thumbnailSize

    var body: some View {
        ProductThumbnailView(
            assetName: resolvedAssetName,
            size: size
        )
    }

    private var resolvedAssetName: String? {
        ItemAssetResolver.bundledAssetName(
            itemName: item.name,
            categoryId: item.categoryId,
            storedAssetName: item.imageAssetName
        )
    }
}
