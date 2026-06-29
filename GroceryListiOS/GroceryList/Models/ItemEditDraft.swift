import Foundation

struct ItemEditDraft: Equatable {
    var name: String
    var quantityValue: Int
    var quantityText: String?
    var categoryId: String
    var storeId: String?
    var listId: UUID?
    var notes: String

    var hasTextQuantity: Bool {
        guard let quantityText, !quantityText.isEmpty else { return false }
        return true
    }

    init(item: GroceryItem) {
        name = item.name
        quantityValue = max(item.quantityValue ?? 1, 1)
        quantityText = item.quantityText
        categoryId = item.categoryId
        storeId = item.storeId
        listId = item.list?.id
        notes = item.notes ?? ""
    }
}
