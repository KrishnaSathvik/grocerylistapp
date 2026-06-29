import Foundation
import SwiftData

enum StoreService {
    struct StoreInfo: Identifiable, Equatable, Sendable {
        let id: String
        let label: String
        let domain: String?
        let colorHex: String
        let iconSymbol: String?
        let isCustom: Bool
        let sortOrder: Int

        var asDefinition: SeedData.StoreDefinition {
            SeedData.StoreDefinition(id: id, label: label, domain: domain, color: colorHex)
        }
    }

    static func allStores(context: ModelContext) -> [StoreInfo] {
        let descriptor = FetchDescriptor<GroceryStore>(
            sortBy: [SortDescriptor(\GroceryStore.sortOrder), SortDescriptor(\GroceryStore.label)]
        )
        let persisted = (try? context.fetch(descriptor)) ?? []
        if persisted.isEmpty {
            return SeedData.loadStoreDefinitions().enumerated().map { index, store in
                StoreInfo(
                    id: store.id,
                    label: store.label,
                    domain: store.domain,
                    colorHex: store.color,
                    iconSymbol: nil,
                    isCustom: false,
                    sortOrder: index
                )
            }
        }
        return persisted.map {
            StoreInfo(
                id: $0.id,
                label: $0.label,
                domain: $0.domain,
                colorHex: $0.colorHex,
                iconSymbol: $0.iconSymbol,
                isCustom: $0.isCustom,
                sortOrder: $0.sortOrder
            )
        }
    }

    static func storeDefinitions(context: ModelContext) -> [SeedData.StoreDefinition] {
        allStores(context: context).map(\.asDefinition)
    }

    static func label(for storeId: String?, context: ModelContext) -> String {
        guard let storeId else { return "Unassigned" }
        if let store = allStores(context: context).first(where: { $0.id == storeId }) {
            return store.label
        }
        return SeedData.storeLabel(for: storeId)
    }

    static func colorHex(for storeId: String, context: ModelContext) -> String? {
        allStores(context: context).first(where: { $0.id == storeId })?.colorHex
            ?? SeedData.storeColorHex(for: storeId)
    }

    static func iconSymbol(for storeId: String, context: ModelContext) -> String? {
        allStores(context: context).first(where: { $0.id == storeId })?.iconSymbol
    }

    static func domain(for storeId: String, context: ModelContext) -> String? {
        allStores(context: context).first(where: { $0.id == storeId })?.domain
            ?? SeedData.storeDomain(for: storeId)
    }

    static func storeId(forLabel label: String, context: ModelContext) -> String? {
        let normalized = label.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return nil }
        return allStores(context: context).first(where: { $0.label.lowercased() == normalized })?.id
    }

    static func ensureCustomStore(label rawLabel: String, context: ModelContext) -> String? {
        let label = StoreDetectionService.titleCaseStoreLabel(rawLabel)
        guard !label.isEmpty else { return nil }

        if let existingId = storeId(forLabel: label, context: context) {
            return existingId
        }

        switch addCustomStore(label: label, context: context) {
        case .added(let info):
            return info.id
        case .duplicate:
            return storeId(forLabel: label, context: context)
        case .invalid:
            return nil
        }
    }

    enum AddStoreResult {
        case added(StoreInfo)
        case duplicate
        case invalid
    }

    @discardableResult
    static func addCustomStore(
        label rawLabel: String,
        iconSymbol: String = CustomStoreIconOptions.symbols[0].name,
        colorHex: String? = nil,
        context: ModelContext
    ) -> AddStoreResult {
        let label = StoreDetectionService.titleCaseStoreLabel(rawLabel)
        guard !label.isEmpty else { return .invalid }

        let id = slugify(label)
        guard !id.isEmpty else { return .invalid }

        let descriptor = FetchDescriptor<GroceryStore>(
            predicate: #Predicate { $0.id == id }
        )
        if (try? context.fetch(descriptor).first) != nil {
            return .duplicate
        }

        let normalizedLabel = label.lowercased()
        let labelDescriptor = FetchDescriptor<GroceryStore>()
        if let stores = try? context.fetch(labelDescriptor),
           stores.contains(where: { $0.label.lowercased() == normalizedLabel }) {
            return .duplicate
        }

        let accent = colorHex ?? StoreBranding.colorHex(for: label)
        let count = (try? context.fetchCount(FetchDescriptor<GroceryStore>())) ?? 0
        let store = GroceryStore(
            id: id,
            label: label,
            domain: nil,
            colorHex: accent,
            iconSymbol: iconSymbol,
            isCustom: true,
            sortOrder: count
        )
        context.insert(store)
        PersistenceService.save(context: context, operation: "add custom store")
        return .added(
            StoreInfo(
                id: store.id,
                label: store.label,
                domain: store.domain,
                colorHex: store.colorHex,
                iconSymbol: store.iconSymbol,
                isCustom: true,
                sortOrder: store.sortOrder
            )
        )
    }

    private static func slugify(_ label: String) -> String {
        let lowered = label.lowercased()
        let allowed = lowered.filter { $0.isLetter || $0.isNumber || $0 == " " }
        let slug = allowed.split(separator: " ").joined(separator: "-")
        return String(slug.prefix(40))
    }
}
