import Foundation

enum ListGroupingService {
    struct StoreGroup: Identifiable {
        let id: String
        let label: String
        let items: [GroceryItem]
    }

    struct CategoryGroup: Identifiable {
        let id: String
        let label: String
        let items: [GroceryItem]
    }

    private static let unassignedStoreId = "__unassigned__"

    static func groupByStore(
        items: [GroceryItem],
        includeCompleted: Bool = false,
        storeOrder: [String]? = nil
    ) -> [StoreGroup] {
        let filtered = items.filter { item in
            !item.isArchived && (includeCompleted || !item.isCompleted)
        }

        var buckets: [String: [GroceryItem]] = [:]
        for item in filtered {
            let key = item.storeId ?? unassignedStoreId
            buckets[key, default: []].append(item)
        }

        for key in buckets.keys {
            buckets[key]?.sort { $0.sortOrder < $1.sortOrder }
        }

        var groups: [StoreGroup] = []
        let storeOrder = storeOrder ?? SeedData.loadStoreDefinitions().map(\.id)

        for storeId in storeOrder where buckets[storeId] != nil {
            groups.append(
                StoreGroup(
                    id: storeId,
                    label: SeedData.storeLabel(for: storeId),
                    items: buckets[storeId] ?? []
                )
            )
            buckets.removeValue(forKey: storeId)
        }

        for (storeId, storeItems) in buckets.sorted(by: { $0.key < $1.key }) {
            let label = storeId == unassignedStoreId
                ? "Unassigned"
                : SeedData.storeLabel(for: storeId)
            groups.append(StoreGroup(id: storeId, label: label, items: storeItems))
        }

        return groups
    }

    static func groupByCategory(
        items: [GroceryItem],
        includeCompleted: Bool = false
    ) -> [CategoryGroup] {
        let filtered = items.filter { item in
            !item.isArchived && (includeCompleted || !item.isCompleted)
        }

        var buckets: [String: [GroceryItem]] = [:]
        for item in filtered {
            buckets[item.categoryId, default: []].append(item)
        }

        for key in buckets.keys {
            buckets[key]?.sort { $0.sortOrder < $1.sortOrder }
        }

        var groups: [CategoryGroup] = []
        let categoryOrder = AppSettings.categoryOrder

        for categoryId in categoryOrder where buckets[categoryId] != nil {
            groups.append(
                CategoryGroup(
                    id: categoryId,
                    label: SeedData.categoryLabel(for: categoryId),
                    items: buckets[categoryId] ?? []
                )
            )
            buckets.removeValue(forKey: categoryId)
        }

        for (categoryId, categoryItems) in buckets.sorted(by: { $0.key < $1.key }) {
            groups.append(
                CategoryGroup(
                    id: categoryId,
                    label: SeedData.categoryLabel(for: categoryId),
                    items: categoryItems
                )
            )
        }

        return groups
    }

    static func displayCategoryGroups(
        items: [GroceryItem],
        includeCompleted: Bool = false
    ) -> [CategoryGroup] {
        let itemGroups = groupByCategory(items: items, includeCompleted: includeCompleted)
        let lookup = Dictionary(uniqueKeysWithValues: itemGroups.map { ($0.id, $0) })
        let customIds = Set(CategoryService.customCategories().map(\.id))
        var result: [CategoryGroup] = []

        for categoryId in AppSettings.categoryOrder {
            if let group = lookup[categoryId] {
                result.append(group)
            } else if customIds.contains(categoryId) {
                result.append(
                    CategoryGroup(
                        id: categoryId,
                        label: CategoryService.label(for: categoryId),
                        items: []
                    )
                )
            }
        }

        for (categoryId, group) in lookup.sorted(by: { $0.key < $1.key })
            where !result.contains(where: { $0.id == categoryId }) {
            result.append(group)
        }

        return result
    }

    static func displayStoreGroups(
        items: [GroceryItem],
        storeOrder: [String],
        storeLabels: [String: String],
        includeCompleted: Bool = false
    ) -> [StoreGroup] {
        let itemGroups = groupByStore(items: items, includeCompleted: includeCompleted, storeOrder: storeOrder)
        let lookup = Dictionary(uniqueKeysWithValues: itemGroups.map { ($0.id, $0) })

        var result = storeOrder.map { storeId in
            lookup[storeId] ?? StoreGroup(id: storeId, label: storeLabels[storeId] ?? storeId.capitalized, items: [])
        }

        for (storeId, group) in lookup where !result.contains(where: { $0.id == storeId }) {
            result.append(group)
        }

        return result
    }
}
