import SwiftUI

enum ProductImageCatalog {
    static func assetName(for normalizedName: String) -> String? {
        ItemAssetResolver.productAssetName(for: normalizedName)
    }

    static func image(for normalizedName: String) -> Image? {
        guard let assetName = assetName(for: normalizedName),
              CatalogAssetAvailability.isUsable(assetName) else {
            return nil
        }
        return Image(assetName)
    }

    static func isUsableAsset(_ assetName: String) -> Bool {
        CatalogAssetAvailability.isUsable(assetName)
    }
}
