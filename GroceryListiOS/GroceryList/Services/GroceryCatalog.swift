import Foundation

/// Shared grocery taxonomy loaded from web-app-derived catalog JSON.
enum GroceryCatalog {
    struct CategoryEntry: Codable, Identifiable, Sendable {
        let id: String
        let displayName: String
        let assetName: String
        let colorKey: String
        let colorHex: String
        let sortOrder: Int
        let keywords: [String]
    }

    struct ProductEntry: Codable, Identifiable, Sendable {
        let id: String
        let displayName: String
        let assetName: String
        let categoryId: String
        let keywords: [String]
    }

    private static let loadedCategories: [CategoryEntry] = load("category_catalog")
    private static let loadedProducts: [ProductEntry] = load("product_catalog")

    static var categories: [CategoryEntry] { loadedCategories }
    static var products: [ProductEntry] { loadedProducts }

    static var categoryKeywords: [String: [String]] {
        Dictionary(uniqueKeysWithValues: loadedCategories.map { ($0.id, $0.keywords) })
    }

    static var defaultCategoryOrder: [String] {
        loadedCategories.sorted { $0.sortOrder < $1.sortOrder }.map(\.id)
    }

    static func category(for id: String) -> CategoryEntry? {
        let key = normalizedCategoryKey(id)
        return loadedCategories.first {
            normalizedCategoryKey($0.id) == key
                || normalizedCategoryKey($0.displayName) == key
        }
    }

    static func normalizedCategoryKey(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "&", with: "and")
            .filter { $0.isLetter || $0.isNumber }
    }

    static func product(for id: String) -> ProductEntry? {
        loadedProducts.first { $0.id == id }
    }

    static func categoryAssetName(for categoryId: String) -> String {
        category(for: categoryId)?.assetName ?? "category-misc"
    }

    private static func load<T: Decodable>(_ name: String) -> [T] {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([T].self, from: data) else {
            return []
        }
        return entries
    }
}
