import Foundation
import SwiftData

struct ListStarterTemplate: Identifiable {
    let id: String
    let name: String
    let iconName: String
    let tintHex: String
}

enum GroceryListService {
    static let listTintOptions = ["#4A7C59", "#3D7EA6", "#C4883C", "#A63D40", "#6B7D8E", "#8B6F8E"]

    static let starterTemplates: [ListStarterTemplate] = [
        ListStarterTemplate(id: "weekly", name: "Weekly Groceries", iconName: "cart.fill", tintHex: "#4A7C59"),
        ListStarterTemplate(id: "costco", name: "Costco Run", iconName: "storefront.fill", tintHex: "#3D7EA6"),
        ListStarterTemplate(id: "indian", name: "Indian Store", iconName: "leaf.fill", tintHex: "#C4883C"),
        ListStarterTemplate(id: "party", name: "Party Prep", iconName: "party.popper.fill", tintHex: "#A63D40"),
    ]
    static let listIconOptions = [
        "cart.fill", "bag.fill", "basket.fill", "storefront.fill",
        "party.popper.fill", "takeoutbag.and.cup.and.straw.fill", "leaf.fill", "house.fill"
    ]

    @discardableResult
    static func createList(
        name rawName: String,
        description: String? = nil,
        iconName: String = "cart.fill",
        tintHex: String? = nil,
        context: ModelContext
    ) -> GroceryList? {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }

        let descriptor = FetchDescriptor<GroceryList>()
        let existing = (try? context.fetch(descriptor)) ?? []
        let sortOrder = (existing.map(\.sortOrder).max() ?? -1) + 1
        let tint = tintHex ?? listTintOptions[existing.count % listTintOptions.count]
        let desc = description?.trimmingCharacters(in: .whitespacesAndNewlines)

        let list = GroceryList(
            name: name,
            listDescription: desc?.isEmpty == true ? nil : desc,
            sortOrder: sortOrder,
            iconName: iconName,
            tintHex: tint
        )
        context.insert(list)
        PersistenceService.save(context: context, operation: "create list")
        ActiveListResolver.setActive(list)
        return list
    }

    static func updateList(
        _ list: GroceryList,
        name: String,
        description: String?,
        iconName: String,
        tintHex: String,
        context: ModelContext
    ) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        list.name = trimmedName
        let desc = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        list.listDescription = desc?.isEmpty == true ? nil : desc
        list.iconName = iconName
        list.tintHex = tintHex
        list.updatedAt = .now
        PersistenceService.save(context: context, operation: "update list")
    }

    static func duplicateList(_ source: GroceryList, context: ModelContext) -> GroceryList? {
        let descriptor = FetchDescriptor<GroceryList>()
        let existing = (try? context.fetch(descriptor)) ?? []
        let sortOrder = (existing.map(\.sortOrder).max() ?? -1) + 1

        let copy = GroceryList(
            name: "\(source.name) Copy",
            listDescription: source.listDescription,
            sortOrder: sortOrder,
            iconName: source.iconName,
            tintHex: source.tintHex
        )
        context.insert(copy)

        let sortedItems = source.items
            .filter { !$0.isArchived }
            .sorted { $0.sortOrder < $1.sortOrder }

        for (index, item) in sortedItems.enumerated() {
            let newItem = GroceryItem(
                name: item.name,
                normalizedName: item.normalizedName,
                quantityValue: item.quantityValue,
                quantityText: item.quantityText,
                categoryId: item.categoryId,
                storeId: item.storeId,
                isCompleted: item.isCompleted,
                iconName: item.iconName,
                imageAssetName: item.imageAssetName,
                sortOrder: index,
                notes: item.notes,
                createdAt: item.createdAt,
                completedAt: item.completedAt,
                list: copy
            )
            context.insert(newItem)
            copy.items.append(newItem)
        }

        PersistenceService.save(context: context, operation: "duplicate list")
        return copy
    }

    @discardableResult
    static func deleteList(_ list: GroceryList, context: ModelContext) -> Bool {
        let wasActive = ActiveListResolver.activeListId == list.id
        context.delete(list)
        PersistenceService.save(context: context, operation: "delete list")

        let descriptor = FetchDescriptor<GroceryList>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\GroceryList.sortOrder), SortDescriptor(\GroceryList.name)]
        )
        let remaining = (try? context.fetch(descriptor)) ?? []
        if let fallback = remaining.first, wasActive {
            ActiveListResolver.setActive(fallback)
        } else if remaining.isEmpty {
            ActiveListResolver.clearActive()
        }
        return true
    }

    static func uniqueListName(_ baseName: String, existing lists: [GroceryList]) -> String {
        let names = Set(lists.map(\.name))
        let trimmed = baseName.trimmingCharacters(in: .whitespacesAndNewlines)
        let seed = trimmed.isEmpty ? "Imported List" : trimmed
        if !names.contains(seed) { return seed }
        var index = 2
        while names.contains("\(seed) \(index)") {
            index += 1
        }
        return "\(seed) \(index)"
    }

    @discardableResult
    static func importSharedList(
        name rawName: String,
        items imported: [ImportedListItem],
        context: ModelContext
    ) -> GroceryList? {
        guard !imported.isEmpty else { return nil }

        let descriptor = FetchDescriptor<GroceryList>()
        let existing = (try? context.fetch(descriptor)) ?? []
        let name = uniqueListName(rawName, existing: existing)
        guard let list = createList(name: name, context: context) else { return nil }
        ListImportService.replaceItems(imported, in: list, context: context)
        return list
    }

    static func ensureMinimumList(context: ModelContext) -> GroceryList {
        let descriptor = FetchDescriptor<GroceryList>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\GroceryList.sortOrder)]
        )
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        return createList(name: SeedData.defaultListName, context: context)!
    }
}
