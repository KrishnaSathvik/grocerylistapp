import Foundation
import SwiftData

enum ListImportService {
    static func addItems(
        _ imported: [ImportedListItem],
        to list: GroceryList,
        context: ModelContext
    ) {
        guard !imported.isEmpty else { return }

        var sortOrder = (list.items.filter { !$0.isArchived }.map(\.sortOrder).max() ?? -1) + 1
        for entry in imported {
            let item = makeItem(from: entry, sortOrder: sortOrder, list: list)
            context.insert(item)
            list.items.append(item)
            sortOrder += 1
        }
        list.updatedAt = .now
        try? context.save()
    }

    static func replaceItems(
        _ imported: [ImportedListItem],
        in list: GroceryList,
        context: ModelContext
    ) {
        let existing = list.items
        for item in existing {
            context.delete(item)
        }
        list.items.removeAll()

        for (index, entry) in imported.enumerated() {
            let item = makeItem(from: entry, sortOrder: index, list: list)
            context.insert(item)
            list.items.append(item)
        }
        list.updatedAt = .now
        try? context.save()
    }

    private static func makeItem(
        from entry: ImportedListItem,
        sortOrder: Int,
        list: GroceryList
    ) -> GroceryItem {
        let normalized = CategoryLearningService.normalize(entry.name)
        return GroceryItem(
            name: entry.name,
            normalizedName: normalized,
            quantityValue: entry.quantityValue,
            categoryId: entry.categoryId,
            storeId: entry.storeId,
            isCompleted: entry.isCompleted,
            iconName: ItemEmojiCatalog.emoji(for: normalized),
            imageAssetName: ProductImageCatalog.assetName(for: normalized),
            sortOrder: sortOrder,
            completedAt: entry.isCompleted ? .now : nil,
            list: list
        )
    }
}
