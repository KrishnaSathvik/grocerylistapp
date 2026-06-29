import Foundation

/// Resolves typed item names → product or category illustration assets.
enum ItemAssetResolver {
    struct Resolution: Equatable, Sendable {
        enum Kind: Sendable {
            case product
            case category
        }

        let assetName: String
        let kind: Kind
        let categoryId: String
        let productId: String?
    }

    /// Full resolution pipeline for display and persistence hints.
    static func resolve(
        itemName: String,
        categoryId: String? = nil,
        storedAssetName: String? = nil
    ) -> Resolution {
        let normalized = CategoryLearningService.normalize(itemName)

        if let stored = storedAssetName,
           let product = GroceryCatalog.products.first(where: { $0.assetName == stored }) {
            return Resolution(
                assetName: stored,
                kind: .product,
                categoryId: product.categoryId,
                productId: product.id
            )
        }

        if let product = matchProduct(in: normalized) {
            return Resolution(
                assetName: product.assetName,
                kind: .product,
                categoryId: product.categoryId,
                productId: product.id
            )
        }

        let resolvedCategory = categoryId
            ?? CategoryDetectionService.detectFromKeywords(for: normalized, keywords: GroceryCatalog.categoryKeywords)

        return Resolution(
            assetName: GroceryCatalog.categoryAssetName(for: resolvedCategory),
            kind: .category,
            categoryId: resolvedCategory,
            productId: nil
        )
    }

    /// Asset name only when a real bundled illustration is available.
    /// Prefers the resolved product asset; falls back to the category illustration when the product image is not bundled yet.
    static func bundledAssetName(
        itemName: String,
        categoryId: String? = nil,
        storedAssetName: String? = nil
    ) -> String? {
        let resolution = resolve(itemName: itemName, categoryId: categoryId, storedAssetName: storedAssetName)
        if CatalogAssetAvailability.isUsable(resolution.assetName) {
            return resolution.assetName
        }

        let categoryAsset = GroceryCatalog.categoryAssetName(for: resolution.categoryId)
        guard CatalogAssetAvailability.isUsable(categoryAsset) else { return nil }
        return categoryAsset
    }

    /// Product asset name for persistence on `GroceryItem.imageAssetName` (product matches only).
    static func productAssetName(for normalizedName: String) -> String? {
        matchProduct(in: normalizedName)?.assetName
    }

    // MARK: - Private

    private static func matchProduct(in normalizedName: String) -> GroceryCatalog.ProductEntry? {
        let name = normalizedName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }

        var best: GroceryCatalog.ProductEntry?
        var bestLength = 0

        for product in GroceryCatalog.products {
            for keyword in product.keywords {
                let kw = keyword.lowercased()
                guard name == kw || name.contains(kw) else { continue }
                if kw.count > bestLength {
                    best = product
                    bestLength = kw.count
                }
            }
        }

        return best
    }
}
