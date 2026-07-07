import Foundation
import SwiftData

enum SeedData {
    struct CategoryDefinition: Codable {
        let id: String
        let label: String
        let color: String
        let emoji: String
    }

    struct CategorySeedFile: Codable {
        let categories: [CategoryDefinition]
        let keywords: [String: [String]]
    }

    struct StoreDefinition: Codable {
        let id: String
        let label: String
        let domain: String?
        let color: String
    }

    struct StoreSeedFile: Codable {
        let stores: [StoreDefinition]
    }

    static func bootstrapIfNeeded(context: ModelContext) {
        seedStoresIfNeeded(context: context)
    }

    static func loadCategories() -> CategorySeedFile? {
        guard let url = Bundle.main.url(forResource: "category_keywords", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(CategorySeedFile.self, from: data)
    }

    static func categoryLabel(for categoryId: String) -> String {
        CategoryService.label(for: categoryId)
    }

    static func categoryLabelFromSeed(for categoryId: String) -> String {
        loadCategories()?.categories.first(where: { $0.id == categoryId })?.label ?? categoryId.capitalized
    }

    static func categoryEmoji(for categoryId: String) -> String {
        CategoryService.emoji(for: categoryId)
    }

    static func categoryEmojiFromSeed(for categoryId: String) -> String {
        loadCategories()?.categories.first(where: { $0.id == categoryId })?.emoji ?? "📦"
    }

    static func categoryColorHex(for categoryId: String) -> String? {
        CategoryService.colorHex(for: categoryId)
    }

    static func categoryColorHexFromSeed(for categoryId: String) -> String? {
        loadCategories()?.categories.first(where: { $0.id == categoryId })?.color
    }

    static func loadStoreDefinitions() -> [StoreDefinition] {
        guard let url = Bundle.main.url(forResource: "default_stores", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let seed = try? JSONDecoder().decode(StoreSeedFile.self, from: data) else {
            return []
        }
        return seed.stores
    }

    static func storeLabel(for storeId: String?) -> String {
        guard let storeId else { return "Unassigned" }
        if let store = loadStoreDefinitions().first(where: { $0.id == storeId }) {
            return store.label
        }
        return storeId.capitalized
    }

    static func storeDomain(for storeId: String) -> String? {
        loadStoreDefinitions().first(where: { $0.id == storeId })?.domain
    }

    static func storeColorHex(for storeId: String) -> String? {
        loadStoreDefinitions().first(where: { $0.id == storeId })?.color
    }

    private static func seedStoresIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<GroceryStore>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        guard let url = Bundle.main.url(forResource: "default_stores", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let seed = try? JSONDecoder().decode(StoreSeedFile.self, from: data) else {
            return
        }

        for (index, store) in seed.stores.enumerated() {
            context.insert(
                GroceryStore(
                    id: store.id,
                    label: store.label,
                    domain: store.domain,
                    colorHex: store.color,
                    isCustom: false,
                    sortOrder: index
                )
            )
        }
    }
}
