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
    ///
    /// Prefers a match from the current item name. `storedAssetName` is treated as a
    /// cached auto-resolution (there is no manual image-picker UI), so it is used only
    /// when the current name has no product match.
    static func resolve(
        itemName: String,
        categoryId: String? = nil,
        storedAssetName: String? = nil
    ) -> Resolution {
        let normalized = CategoryLearningService.normalize(itemName)

        if let product = matchProduct(in: normalized) {
            return Resolution(
                assetName: product.assetName,
                kind: .product,
                categoryId: product.categoryId,
                productId: product.id
            )
        }

        if let stored = storedAssetName,
           let product = GroceryCatalog.products.first(where: { $0.assetName == stored }) {
            return Resolution(
                assetName: stored,
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

    /// Fresh-produce roots must not absorb powdered/spice forms (onion powder → onions).
    private static let produceFormBlockTokens: Set<String> = [
        "powder", "seasoning", "spice", "extract", "seeds", "seed", "mix", "sauce", "paste",
        "chutney", "pesto", "chips",
    ]

    private static func matchProduct(in normalizedName: String) -> GroceryCatalog.ProductEntry? {
        let name = normalizedName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        let nameTokens = tokens(in: name)
        guard !nameTokens.isEmpty else { return nil }
        let nameHasProduceFormBlock = nameTokens.contains(where: { produceFormBlockTokens.contains($0) })

        var best: GroceryCatalog.ProductEntry?
        var bestLength = 0
        var bestDistance = Int.max

        for product in GroceryCatalog.products {
            for keyword in product.keywords {
                let kw = keyword.lowercased()
                let keywordTokens = tokens(in: kw)
                if nameHasProduceFormBlock,
                   product.categoryId == "produce",
                   !keywordTokens.contains(where: { produceFormBlockTokens.contains($0) }) {
                    continue
                }
                if keywordMatches(nameTokens: nameTokens, keyword: kw) {
                    // Exact phrase matches always beat fuzzy hits, even if shorter.
                    if bestDistance > 0 || kw.count > bestLength {
                        best = product
                        bestLength = kw.count
                        bestDistance = 0
                    }
                    continue
                }

                // Never let a fuzzy keyword override an exact product match
                // (e.g. "flour" must not lose to fuzzy "flowers").
                guard bestDistance > 0 else { continue }
                guard let distance = fuzzyPhraseDistance(nameTokens: nameTokens, keyword: kw) else { continue }
                if kw.count > bestLength || (kw.count == bestLength && distance < bestDistance) {
                    best = product
                    bestLength = kw.count
                    bestDistance = distance
                }
            }
        }

        return best
    }

    private static func fuzzyPhraseDistance(nameTokens: [String], keyword: String) -> Int? {
        CategoryDetectionService.productFuzzyPhraseDistance(nameTokens: nameTokens, keyword: keyword)
    }

    private static func keywordMatches(nameTokens: [String], keyword: String) -> Bool {
        let keywordTokens = tokens(in: keyword)
        guard !keywordTokens.isEmpty, keywordTokens.count <= nameTokens.count else { return false }

        if keywordTokens == nameTokens {
            return true
        }

        let maxStart = nameTokens.count - keywordTokens.count
        for start in 0...maxStart {
            let candidate = Array(nameTokens[start ..< start + keywordTokens.count])
            if candidate == keywordTokens {
                return true
            }
        }
        return false
    }

    private static func tokens(in value: String) -> [String] {
        value
            .lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
    }
}
