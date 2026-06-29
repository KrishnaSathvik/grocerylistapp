import Foundation

enum CategoryService {
    struct CategoryInfo: Identifiable, Equatable, Codable, Sendable {
        let id: String
        let label: String
        let color: String
        let emoji: String
        let isCustom: Bool
    }

    static func allCategories() -> [CategoryInfo] {
        let catalogSeed = GroceryCatalog.categories.map { entry in
            CategoryInfo(
                id: entry.id,
                label: entry.displayName,
                color: entry.colorHex,
                emoji: SeedData.categoryEmojiFromSeed(for: entry.id),
                isCustom: false
            )
        }
        let seed = catalogSeed.isEmpty
            ? (SeedData.loadCategories()?.categories ?? []).map {
                CategoryInfo(id: $0.id, label: $0.label, color: $0.color, emoji: $0.emoji, isCustom: false)
            }
            : catalogSeed
        let custom = AppSettings.customCategories
        let customIds = Set(custom.map(\.id))
        return seed.filter { !customIds.contains($0.id) } + custom
    }

    static func customCategories() -> [CategoryInfo] {
        AppSettings.customCategories
    }

    static func label(for categoryId: String) -> String {
        if let custom = AppSettings.customCategories.first(where: { $0.id == categoryId }) {
            return custom.label
        }
        return SeedData.categoryLabelFromSeed(for: categoryId)
    }

    static func emoji(for categoryId: String) -> String {
        if let custom = AppSettings.customCategories.first(where: { $0.id == categoryId }) {
            return custom.emoji
        }
        return SeedData.categoryEmojiFromSeed(for: categoryId)
    }

    static func colorHex(for categoryId: String) -> String? {
        if let custom = AppSettings.customCategories.first(where: { $0.id == categoryId }) {
            return custom.color
        }
        return SeedData.categoryColorHexFromSeed(for: categoryId)
    }

    /// Saturated accent colors for custom categories (matches built-in catalog tints).
    static let customCategoryColorOptions: [String] = [
        "#4A7C59", "#3D7EA6", "#C4883C", "#A63D40", "#6A8E7F", "#5E7EA8",
        "#D4889A", "#8B6F8E", "#7A8B6F", "#B08968", "#6B7D8E", "#A0855B",
    ]

    @discardableResult
    static func addCustomCategory(label rawLabel: String, emoji: String, color: String) -> CategoryInfo? {
        let label = rawLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !label.isEmpty else { return nil }

        let id = slugify(label)
        guard !id.isEmpty else { return nil }

        var custom = AppSettings.customCategories
        if let existing = custom.first(where: { $0.id == id }) {
            return existing
        }

        let info = CategoryInfo(id: id, label: label, color: color, emoji: emoji, isCustom: true)
        custom.append(info)
        AppSettings.customCategories = custom

        var order = AppSettings.categoryOrder
        if !order.contains(id) {
            order.append(id)
            AppSettings.categoryOrder = order
        }

        return info
    }

    private static func slugify(_ label: String) -> String {
        let lowered = label.lowercased()
        let allowed = lowered.filter { $0.isLetter || $0.isNumber || $0 == " " }
        let slug = allowed.split(separator: " ").joined(separator: "-")
        return String(slug.prefix(40))
    }
}
