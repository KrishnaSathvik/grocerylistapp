import Foundation
import SwiftData

@Model
final class GroceryList {
    @Attribute(.unique) var id: UUID
    var name: String
    var listDescription: String?
    var createdAt: Date
    var updatedAt: Date
    var sortOrder: Int
    var isArchived: Bool
    var iconName: String
    var tintHex: String

    @Relationship(deleteRule: .cascade, inverse: \GroceryItem.list)
    var items: [GroceryItem]

    init(
        id: UUID = UUID(),
        name: String,
        listDescription: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        sortOrder: Int = 0,
        isArchived: Bool = false,
        iconName: String = "cart.fill",
        tintHex: String = "#4A7C59",
        items: [GroceryItem] = []
    ) {
        self.id = id
        self.name = name
        self.listDescription = listDescription
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sortOrder = sortOrder
        self.isArchived = isArchived
        self.iconName = iconName
        self.tintHex = tintHex
        self.items = items
    }

    var activeItemCount: Int {
        items.filter { !$0.isCompleted && !$0.isArchived }.count
    }

    var completedItemCount: Int {
        items.filter { $0.isCompleted && !$0.isArchived }.count
    }

    var totalItemCount: Int {
        items.filter { !$0.isArchived }.count
    }

    var shoppingProgress: Double {
        let total = totalItemCount
        guard total > 0 else { return 0 }
        return Double(completedItemCount) / Double(total)
    }
}
