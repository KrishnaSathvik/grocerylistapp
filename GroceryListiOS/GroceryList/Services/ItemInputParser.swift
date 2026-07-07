import Foundation

struct ParsedItemInput: Equatable, Sendable {
    let name: String
    let normalizedName: String
    let quantityValue: Int?
    let quantityText: String?
    let categoryId: String
    let storeId: String?
    let customStoreLabel: String?

    var hasConfidentPreview: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedName.count >= 2 else { return false }
        return trimmedName.rangeOfCharacter(from: .letters) != nil
    }

    func withStoreId(_ storeId: String?) -> ParsedItemInput {
        ParsedItemInput(
            name: name,
            normalizedName: normalizedName,
            quantityValue: quantityValue,
            quantityText: quantityText,
            categoryId: categoryId,
            storeId: storeId,
            customStoreLabel: nil
        )
    }
}

enum ItemInputParser {
    static func parse(
        _ raw: String,
        learningRules: [CategoryLearningRule] = [],
        stores: [SeedData.StoreDefinition]? = nil
    ) -> ParsedItemInput {
        let storeList = stores ?? SeedData.loadStoreDefinitions()
        let storePhrase = StoreDetectionService.parseStorePhrase(raw, stores: storeList)
        let storeId = StoreDetectionService.resolveStoreId(query: storePhrase.query, stores: storeList)
        let customStoreLabel: String? = {
            guard storeId == nil, storePhrase.isExplicit, let query = storePhrase.query else { return nil }
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            return StoreDetectionService.titleCaseStoreLabel(trimmed)
        }()

        let quantity = QuantityParserService.parse(storePhrase.cleanText)
        let categoryId = CategoryDetectionService.detectCategory(
            for: quantity.itemText,
            learningRules: learningRules
        )
        let normalized = CategoryLearningService.normalize(quantity.itemText)

        return ParsedItemInput(
            name: quantity.itemText,
            normalizedName: normalized,
            quantityValue: quantity.quantityValue,
            quantityText: quantity.quantityText,
            categoryId: categoryId,
            storeId: storeId,
            customStoreLabel: customStoreLabel
        )
    }

    static func parse(
        itemText: String,
        storePhrase: StoreDetectionService.StorePhrase,
        learningRules: [CategoryLearningRule] = [],
        stores: [SeedData.StoreDefinition]? = nil
    ) -> ParsedItemInput {
        let storeList = stores ?? SeedData.loadStoreDefinitions()
        let trimmedItem = itemText.trimmingCharacters(in: .whitespacesAndNewlines)
        let storeId = StoreDetectionService.resolveStoreId(query: storePhrase.query, stores: storeList)
        let customStoreLabel: String? = {
            guard storeId == nil, storePhrase.isExplicit, let query = storePhrase.query else { return nil }
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            return StoreDetectionService.titleCaseStoreLabel(trimmed)
        }()

        let quantity = QuantityParserService.parse(trimmedItem)
        let categoryId = CategoryDetectionService.detectCategory(
            for: quantity.itemText,
            learningRules: learningRules
        )
        let normalized = CategoryLearningService.normalize(quantity.itemText)

        return ParsedItemInput(
            name: quantity.itemText,
            normalizedName: normalized,
            quantityValue: quantity.quantityValue,
            quantityText: quantity.quantityText,
            categoryId: categoryId,
            storeId: storeId,
            customStoreLabel: customStoreLabel
        )
    }
}
