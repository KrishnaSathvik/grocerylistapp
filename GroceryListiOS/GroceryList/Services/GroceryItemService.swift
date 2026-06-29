import Foundation
import SwiftData

struct DeletedItemSnapshot: Sendable {
    let id: UUID
    let name: String
    let normalizedName: String
    let quantityValue: Int?
    let quantityText: String?
    let categoryId: String
    let storeId: String?
    let isCompleted: Bool
    let iconName: String?
    let imageAssetName: String?
    let sortOrder: Int
    let notes: String?
    let createdAt: Date
    let completedAt: Date?

    init(item: GroceryItem) {
        id = item.id
        name = item.name
        normalizedName = item.normalizedName
        quantityValue = item.quantityValue
        quantityText = item.quantityText
        categoryId = item.categoryId
        storeId = item.storeId
        isCompleted = item.isCompleted
        iconName = item.iconName
        imageAssetName = item.imageAssetName
        sortOrder = item.sortOrder
        notes = item.notes
        createdAt = item.createdAt
        completedAt = item.completedAt
    }
}

enum GroceryItemService {
    private static func nextSortOrder(for list: GroceryList) -> Int {
        let orders = list.items.filter { !$0.isArchived }.map(\.sortOrder)
        return (orders.max() ?? -1) + 1
    }

    private static func touchList(_ list: GroceryList) {
        list.updatedAt = .now
    }

    @discardableResult
    static func addItem(
        name rawName: String,
        to list: GroceryList,
        context: ModelContext
    ) -> GroceryItem? {
        addItems(name: rawName, to: list, context: context).last
    }

    @discardableResult
    static func addItems(
        name rawName: String,
        to list: GroceryList,
        context: ModelContext
    ) -> [GroceryItem] {
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let learningRules = CategoryLearningService.fetchRules(context: context)
        let stores = StoreService.storeDefinitions(context: context)
        let parsedItems = MultiItemInputParser.parse(trimmed, learningRules: learningRules, stores: stores)
        guard !parsedItems.isEmpty else { return [] }

        var sortOrder = nextSortOrder(for: list)
        var created: [GroceryItem] = []

        for parsed in parsedItems {
            guard !parsed.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }

            var storeId = parsed.storeId
            if storeId == nil, let customLabel = parsed.customStoreLabel {
                storeId = StoreService.ensureCustomStore(label: customLabel, context: context)
            }

            let imageAsset = ProductImageCatalog.assetName(for: parsed.normalizedName)
            let item = GroceryItem(
                name: parsed.name,
                normalizedName: parsed.normalizedName,
                quantityValue: parsed.quantityValue,
                quantityText: parsed.quantityText,
                categoryId: parsed.categoryId,
                storeId: storeId,
                iconName: nil,
                imageAssetName: imageAsset,
                sortOrder: sortOrder,
                list: list
            )
            context.insert(item)
            list.items.append(item)
            created.append(item)
            sortOrder += 1
        }

        guard !created.isEmpty else { return [] }

        touchList(list)
        try? context.save()
        return created
    }

    static func toggleComplete(_ item: GroceryItem, context: ModelContext) {
        item.isCompleted.toggle()
        item.completedAt = item.isCompleted ? .now : nil
        if let list = item.list {
            touchList(list)
        }
        try? context.save()
    }

    static func assignItems(_ items: [GroceryItem], to targetList: GroceryList, context: ModelContext) {
        let startOrder = (targetList.items.map(\.sortOrder).max() ?? -1) + 1
        for (offset, item) in items.enumerated() {
            if let sourceList = item.list, sourceList.id != targetList.id {
                sourceList.items.removeAll { $0.id == item.id }
                sourceList.updatedAt = .now
            }
            item.list = targetList
            item.sortOrder = startOrder + offset
            if !targetList.items.contains(where: { $0.id == item.id }) {
                targetList.items.append(item)
            }
        }
        targetList.updatedAt = .now
        try? context.save()
    }

    static func deleteItems(_ items: [GroceryItem], context: ModelContext) -> [DeletedItemSnapshot] {
        items.map { deleteItem($0, context: context) }
    }

    static func updateQuantity(_ item: GroceryItem, value: Int?, context: ModelContext) {
        if item.quantityText != nil {
            return
        }
        if let value, value > 1 {
            item.quantityValue = value
        } else {
            item.quantityValue = nil
        }
        if let list = item.list {
            touchList(list)
        }
        try? context.save()
    }

    static func updateName(_ item: GroceryItem, name rawName: String, context: ModelContext) {
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let learningRules = CategoryLearningService.fetchRules(context: context)
        let parsed = ItemInputParser.parse(trimmed, learningRules: learningRules)
        item.name = parsed.name
        item.normalizedName = parsed.normalizedName
        item.quantityValue = parsed.quantityValue
        item.quantityText = parsed.quantityText
        item.categoryId = parsed.categoryId
        item.storeId = parsed.storeId
        item.imageAssetName = ProductImageCatalog.assetName(for: parsed.normalizedName)
        item.iconName = ItemEmojiCatalog.emoji(for: parsed.normalizedName)
        if let list = item.list {
            touchList(list)
        }
        try? context.save()
    }

    static func updateItem(
        _ item: GroceryItem,
        draft: ItemEditDraft,
        context: ModelContext
    ) {
        let trimmed = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        item.name = trimmed
        item.normalizedName = CategoryLearningService.normalize(trimmed)
        if draft.hasTextQuantity {
            item.quantityText = draft.quantityText
            item.quantityValue = nil
        } else if draft.quantityValue > 1 {
            item.quantityValue = draft.quantityValue
            item.quantityText = nil
        } else {
            item.quantityValue = nil
            item.quantityText = nil
        }
        item.categoryId = draft.categoryId
        item.storeId = draft.storeId
        let notes = draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        item.notes = notes.isEmpty ? nil : notes
        item.imageAssetName = ProductImageCatalog.assetName(for: item.normalizedName)
        item.iconName = nil
        CategoryLearningService.record(
            normalizedName: item.normalizedName,
            categoryId: draft.categoryId,
            context: context
        )
        if let listId = draft.listId, listId != item.list?.id {
            let targetId = listId
            let descriptor = FetchDescriptor<GroceryList>(
                predicate: #Predicate<GroceryList> { $0.id == targetId }
            )
            if let target = try? context.fetch(descriptor).first {
                assignItems([item], to: target, context: context)
                return
            }
        }
        if let list = item.list {
            touchList(list)
        }
        try? context.save()
    }

    @discardableResult
    static func deleteItem(_ item: GroceryItem, context: ModelContext) -> DeletedItemSnapshot {
        let snapshot = DeletedItemSnapshot(item: item)
        if let list = item.list {
            list.items.removeAll { $0.id == item.id }
            touchList(list)
        }
        context.delete(item)
        try? context.save()
        return snapshot
    }

    static func restoreItem(_ snapshot: DeletedItemSnapshot, to list: GroceryList, context: ModelContext) {
        let item = GroceryItem(
            id: snapshot.id,
            name: snapshot.name,
            normalizedName: snapshot.normalizedName,
            quantityValue: snapshot.quantityValue,
            quantityText: snapshot.quantityText,
            categoryId: snapshot.categoryId,
            storeId: snapshot.storeId,
            isCompleted: snapshot.isCompleted,
            iconName: snapshot.iconName,
            imageAssetName: snapshot.imageAssetName,
            sortOrder: snapshot.sortOrder,
            notes: snapshot.notes,
            createdAt: snapshot.createdAt,
            completedAt: snapshot.completedAt,
            list: list
        )
        context.insert(item)
        list.items.append(item)
        touchList(list)
        try? context.save()
    }

    static func clearCompleted(in list: GroceryList, context: ModelContext) {
        let completed = list.items.filter { $0.isCompleted && !$0.isArchived }
        for item in completed {
            list.items.removeAll { $0.id == item.id }
            context.delete(item)
        }
        touchList(list)
        try? context.save()
    }

    static func duplicateItem(_ item: GroceryItem, in list: GroceryList, context: ModelContext) {
        let sortOrder = (list.items.map(\.sortOrder).max() ?? -1) + 1
        let copy = GroceryItem(
            name: item.name,
            normalizedName: item.normalizedName,
            quantityValue: item.quantityValue,
            quantityText: item.quantityText,
            categoryId: item.categoryId,
            storeId: item.storeId,
            isCompleted: false,
            iconName: item.iconName,
            imageAssetName: item.imageAssetName,
            sortOrder: sortOrder,
            notes: item.notes,
            list: list
        )
        context.insert(copy)
        list.items.append(copy)
        touchList(list)
        try? context.save()
    }

    static func updateCategory(_ item: GroceryItem, categoryId: String, context: ModelContext) {
        item.categoryId = categoryId
        CategoryLearningService.record(
            normalizedName: item.normalizedName,
            categoryId: categoryId,
            context: context
        )
        if let list = item.list {
            touchList(list)
        }
        try? context.save()
    }

    static func updateStore(_ item: GroceryItem, storeId: String?, context: ModelContext) {
        item.storeId = storeId
        if let list = item.list {
            touchList(list)
        }
        try? context.save()
    }

    static func moveItems(in list: GroceryList, from source: IndexSet, to destination: Int, activeOnly: Bool, context: ModelContext) {
        var items = list.items
            .filter { !$0.isArchived && (activeOnly ? !$0.isCompleted : $0.isCompleted) }
            .sorted { $0.sortOrder < $1.sortOrder }

        items.move(fromOffsets: source, toOffset: destination)

        for (index, item) in items.enumerated() {
            item.sortOrder = index
        }
        touchList(list)
        try? context.save()
    }
}
