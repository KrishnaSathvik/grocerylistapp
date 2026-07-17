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
        context: ModelContext,
        prefilledStoreId: String? = nil,
        prefilledCategoryId: String? = nil
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

            if storeId == nil {
                storeId = StoreDetectionService.defaultStoreId(
                    forListName: list.name,
                    stores: stores
                )
            }

            if let prefilledStoreId,
               prefilledStoreId != "__unassigned__",
               !prefilledStoreId.isEmpty {
                storeId = prefilledStoreId
            }

            var categoryId = parsed.categoryId
            if let prefilledCategoryId, !prefilledCategoryId.isEmpty {
                categoryId = prefilledCategoryId
            }

            let imageAsset = ProductImageCatalog.assetName(for: parsed.normalizedName)
            let item = GroceryItem(
                name: parsed.name,
                normalizedName: parsed.normalizedName,
                quantityValue: parsed.quantityValue,
                quantityText: parsed.quantityText,
                categoryId: categoryId,
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
        PersistenceService.save(context: context, operation: "add grocery items")
        return created
    }

    @discardableResult
    static func toggleComplete(_ item: GroceryItem, context: ModelContext) -> Bool {
        item.isCompleted.toggle()
        item.completedAt = item.isCompleted ? .now : nil
        if let list = item.list {
            touchList(list)
        }
        return PersistenceService.save(context: context, operation: "toggle item completion")
    }

    @discardableResult
    static func assignItems(_ items: [GroceryItem], to targetList: GroceryList, context: ModelContext) -> Bool {
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
        return PersistenceService.save(context: context, operation: "assign items to list")
    }

    static func deleteItems(_ items: [GroceryItem], context: ModelContext) -> [DeletedItemSnapshot] {
        items.map { deleteItem($0, context: context) }
    }

    @discardableResult
    static func updateQuantity(_ item: GroceryItem, value: Int?, context: ModelContext) -> Bool {
        if item.quantityText != nil {
            return true
        }
        if let value, value > 1 {
            item.quantityValue = value
        } else {
            item.quantityValue = nil
        }
        if let list = item.list {
            touchList(list)
        }
        return PersistenceService.save(context: context, operation: "update item quantity")
    }

    @discardableResult
    static func updateName(_ item: GroceryItem, name rawName: String, context: ModelContext) -> Bool {
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

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
        return PersistenceService.save(context: context, operation: "update item name")
    }

    @discardableResult
    static func updateItem(
        _ item: GroceryItem,
        draft: ItemEditDraft,
        context: ModelContext
    ) -> Bool {
        let trimmed = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let previousNormalized = item.normalizedName
        let learningRules = CategoryLearningService.fetchRules(context: context)
        let detectedCategory = CategoryDetectionService.detectCategory(
            for: trimmed,
            learningRules: learningRules
        )

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
        var categoryId = draft.categoryId
        if item.normalizedName != previousNormalized, !draft.categoryManuallySelected, detectedCategory != "misc" {
            categoryId = detectedCategory
        }
        item.categoryId = categoryId
        item.storeId = draft.storeId
        let notes = draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        item.notes = notes.isEmpty ? nil : notes
        item.imageAssetName = ProductImageCatalog.assetName(for: item.normalizedName)
        item.iconName = nil
        if draft.categoryManuallySelected || categoryId != "misc" {
            CategoryLearningService.record(
                normalizedName: item.normalizedName,
                categoryId: categoryId,
                context: context
            )
        }
        if let listId = draft.listId, listId != item.list?.id {
            let targetId = listId
            let descriptor = FetchDescriptor<GroceryList>(
                predicate: #Predicate<GroceryList> { $0.id == targetId }
            )
            if let target = try? context.fetch(descriptor).first {
                return assignItems([item], to: target, context: context)
            }
        }
        if let list = item.list {
            touchList(list)
        }
        return PersistenceService.save(context: context, operation: "update item")
    }

    @discardableResult
    static func deleteItem(_ item: GroceryItem, context: ModelContext) -> DeletedItemSnapshot {
        let snapshot = DeletedItemSnapshot(item: item)
        if let list = item.list {
            list.items.removeAll { $0.id == item.id }
            touchList(list)
        }
        context.delete(item)
        PersistenceService.save(context: context, operation: "delete item")
        return snapshot
    }

    @discardableResult
    static func restoreItem(_ snapshot: DeletedItemSnapshot, to list: GroceryList, context: ModelContext) -> Bool {
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
        return PersistenceService.save(context: context, operation: "restore item")
    }

    @discardableResult
    static func clearCompleted(in list: GroceryList, context: ModelContext) -> Bool {
        let completed = list.items.filter { $0.isCompleted && !$0.isArchived }
        for item in completed {
            list.items.removeAll { $0.id == item.id }
            context.delete(item)
        }
        touchList(list)
        return PersistenceService.save(context: context, operation: "clear completed items")
    }

    @discardableResult
    static func duplicateItem(_ item: GroceryItem, in list: GroceryList, context: ModelContext) -> Bool {
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
        return PersistenceService.save(context: context, operation: "duplicate item")
    }

    @discardableResult
    static func updateCategory(_ item: GroceryItem, categoryId: String, context: ModelContext) -> Bool {
        item.categoryId = categoryId
        CategoryLearningService.record(
            normalizedName: item.normalizedName,
            categoryId: categoryId,
            context: context
        )
        if let list = item.list {
            touchList(list)
        }
        return PersistenceService.save(context: context, operation: "update item category")
    }

    @discardableResult
    static func updateStore(_ item: GroceryItem, storeId: String?, context: ModelContext) -> Bool {
        item.storeId = storeId
        if let list = item.list {
            touchList(list)
        }
        return PersistenceService.save(context: context, operation: "update item store")
    }

    @discardableResult
    static func moveItems(in list: GroceryList, from source: IndexSet, to destination: Int, activeOnly: Bool, context: ModelContext) -> Bool {
        var items = list.items
            .filter { !$0.isArchived && (activeOnly ? !$0.isCompleted : $0.isCompleted) }
            .sorted { $0.sortOrder < $1.sortOrder }

        items.move(fromOffsets: source, toOffset: destination)

        for (index, item) in items.enumerated() {
            item.sortOrder = index
        }
        touchList(list)
        return PersistenceService.save(context: context, operation: "move items")
    }

    /// Recomputes auto-assigned `imageAssetName` from the current item name.
    /// Safe because there is no manual image-picker UI — stored values are a cache.
    @discardableResult
    static func reconcileImageAssets(in list: GroceryList, context: ModelContext) -> Int {
        var updated = 0
        for item in list.items where !item.isArchived {
            let resolved = ItemAssetResolver.productAssetName(for: item.normalizedName)
            if resolved != item.imageAssetName {
                item.imageAssetName = resolved
                updated += 1
            }
        }
        guard updated > 0 else { return 0 }
        touchList(list)
        PersistenceService.save(context: context, operation: "reconcile item image assets")
        return updated
    }

    /// Recomputes a single item's cached product image from its current name.
    @discardableResult
    static func reconcileImageAsset(_ item: GroceryItem, context: ModelContext) -> Bool {
        let resolved = ItemAssetResolver.productAssetName(for: item.normalizedName)
        guard resolved != item.imageAssetName else { return true }
        item.imageAssetName = resolved
        if let list = item.list {
            touchList(list)
        }
        return PersistenceService.save(context: context, operation: "reconcile item image asset")
    }
}
