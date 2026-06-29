import Foundation
import SwiftData

@Model
final class GroceryItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var normalizedName: String
    var quantityValue: Int?
    var quantityText: String?
    var categoryId: String
    var storeId: String?
    var isCompleted: Bool
    var isArchived: Bool
    var iconName: String?
    var imageAssetName: String?
    var sortOrder: Int
    var notes: String?
    var createdAt: Date
    var completedAt: Date?

    var list: GroceryList?

    init(
        id: UUID = UUID(),
        name: String,
        normalizedName: String? = nil,
        quantityValue: Int? = nil,
        quantityText: String? = nil,
        categoryId: String = "misc",
        storeId: String? = nil,
        isCompleted: Bool = false,
        isArchived: Bool = false,
        iconName: String? = nil,
        imageAssetName: String? = nil,
        sortOrder: Int = 0,
        notes: String? = nil,
        createdAt: Date = .now,
        completedAt: Date? = nil,
        list: GroceryList? = nil
    ) {
        self.id = id
        self.name = name
        self.normalizedName = normalizedName ?? name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        self.quantityValue = quantityValue
        self.quantityText = quantityText
        self.categoryId = categoryId
        self.storeId = storeId
        self.isCompleted = isCompleted
        self.isArchived = isArchived
        self.iconName = iconName
        self.imageAssetName = imageAssetName
        self.sortOrder = sortOrder
        self.notes = notes
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.list = list
    }
}
