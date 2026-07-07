import Foundation
import SwiftData

enum ShareTextFormatter {
    static func format(list: GroceryList, context: ModelContext, includeBrandHeader: Bool = true) -> String {
        let stores = StoreService.allStores(context: context)
        let storeLabels = Dictionary(uniqueKeysWithValues: stores.map { ($0.id, $0.label) })
        let storeOrder = stores.map(\.id)
        return format(
            list: list,
            storeLabels: storeLabels,
            storeOrder: storeOrder,
            includeBrandHeader: includeBrandHeader
        )
    }

    static func format(
        list: GroceryList,
        storeLabels: [String: String] = [:],
        storeOrder: [String] = SeedData.loadStoreDefinitions().map(\.id),
        includeBrandHeader: Bool = true
    ) -> String {
        let items = list.items.filter { !$0.isArchived }
        let active = items.filter { !$0.isCompleted }.sorted { $0.sortOrder < $1.sortOrder }
        let completed = items.filter(\.isCompleted).sorted { $0.sortOrder < $1.sortOrder }

        var lines: [String] = []
        if includeBrandHeader {
            lines.append("Groceries — Smart Lists")
        }
        lines.append(formattedDate)
        lines.append("")

        let storeGroups = Dictionary(grouping: active) { $0.storeId ?? "__none__" }
        let hasStores = storeGroups.keys.contains { $0 != "__none__" }

        if hasStores {
            for storeId in orderedStoreKeys(from: storeGroups, storeOrder: storeOrder) where storeId != "__none__" {
                lines.append("\(storeLabel(for: storeId, storeLabels: storeLabels)):")
                for item in storeGroups[storeId] ?? [] {
                    lines.append("  \(checkbox(for: item)) \(quantityPrefix(for: item))\(item.name)")
                }
                lines.append("")
            }
            if let unassigned = storeGroups["__none__"], !unassigned.isEmpty {
                lines.append("Other:")
                for item in unassigned {
                    lines.append("  \(checkbox(for: item)) \(quantityPrefix(for: item))\(item.name)")
                }
                lines.append("")
            }
        } else {
            for item in active {
                lines.append("\(checkbox(for: item)) \(quantityPrefix(for: item))\(item.name)")
            }
        }

        if !completed.isEmpty {
            lines.append("")
            lines.append("Picked up:")
            for item in completed {
                lines.append("  [x] \(item.name)")
            }
        }

        lines.append("")
        lines.append("\(active.count) item\(active.count == 1 ? "" : "s") remaining")
        return lines.joined(separator: "\n")
    }

    /// Grocery checklist for clipboard copy — grouped by store when items have stores.
    static func formatPlainList(list: GroceryList, context: ModelContext) -> String {
        let stores = StoreService.allStores(context: context)
        let storeLabels = Dictionary(uniqueKeysWithValues: stores.map { ($0.id, $0.label) })
        let storeOrder = stores.map(\.id)
        return formatPlainList(
            list: list,
            storeLabels: storeLabels,
            storeOrder: storeOrder
        )
    }

    static func formatPlainList(
        list: GroceryList,
        storeLabels: [String: String] = [:],
        storeOrder: [String] = SeedData.loadStoreDefinitions().map(\.id)
    ) -> String {
        let items = list.items.filter { !$0.isArchived }
        let active = items.filter { !$0.isCompleted }.sorted { $0.sortOrder < $1.sortOrder }
        let completed = items.filter(\.isCompleted).sorted { $0.sortOrder < $1.sortOrder }

        var lines: [String] = [list.name, ""]

        let storeGroups = Dictionary(grouping: active) { $0.storeId ?? "__none__" }
        let hasStores = storeGroups.keys.contains { $0 != "__none__" }

        if hasStores {
            for storeId in orderedStoreKeys(from: storeGroups, storeOrder: storeOrder) where storeId != "__none__" {
                lines.append("\(storeLabel(for: storeId, storeLabels: storeLabels)):")
                for item in storeGroups[storeId] ?? [] {
                    lines.append("  \(checkbox(for: item)) \(quantityPrefix(for: item))\(item.name)")
                }
                lines.append("")
            }
            if let unassigned = storeGroups["__none__"], !unassigned.isEmpty {
                lines.append("Other:")
                for item in unassigned {
                    lines.append("  \(checkbox(for: item)) \(quantityPrefix(for: item))\(item.name)")
                }
                lines.append("")
            }
        } else {
            for item in active {
                lines.append("\(checkbox(for: item)) \(quantityPrefix(for: item))\(item.name)")
            }
        }

        if !completed.isEmpty {
            if let last = lines.last, !last.isEmpty {
                lines.append("")
            }
            lines.append("Picked up:")
            for item in completed {
                lines.append("  ☑ \(item.name)")
            }
        }

        while lines.last == "" {
            lines.removeLast()
        }
        return lines.joined(separator: "\n")
    }

    /// Clean list for Messages — subject carries the list name; short App Store line at the end.
    static func formatForMessages(list: GroceryList, context: ModelContext) -> String {
        let listBody = format(list: list, context: context, includeBrandHeader: false)
        return """
        \(listBody)

        —
        Don't have the app? Get Groceries — Smart Lists on the App Store:
        \(AppConfig.appStoreShareURLString)
        """
    }

    /// Same readable list for copy/share; no import codes or app pitches in the message.
    static func formatForSharing(
        list: GroceryList,
        context: ModelContext,
        includeListTitle: Bool = false,
        includeURLsInBody: Bool = false,
        includeBrandHeader: Bool = false
    ) -> String {
        if !includeListTitle && !includeURLsInBody && !includeBrandHeader {
            return formatForMessages(list: list, context: context)
        }

        var sections: [String] = []
        if includeListTitle {
            sections.append(list.name)
        }
        sections.append(
            format(
                list: list,
                context: context,
                includeBrandHeader: includeBrandHeader
            )
        )

        if includeURLsInBody, let importLink = ListCodec.shareLinkString(for: list) {
            sections.append("")
            sections.append(importLink)
        }

        return sections.joined(separator: "\n")
    }

    static func previewLine(for item: GroceryItem) -> String {
        "\(quantityPrefix(for: item))\(item.name)"
    }

    static func formatSelectedItems(_ items: [GroceryItem], listName: String) -> String {
        let active = items.filter { !$0.isCompleted && !$0.isArchived }
            .sorted { $0.sortOrder < $1.sortOrder }
        let completed = items.filter(\.isCompleted).sorted { $0.sortOrder < $1.sortOrder }

        var lines: [String] = []
        lines.append(listName)
        lines.append(formattedDate)
        lines.append("")

        for item in active {
            lines.append("\(checkbox(for: item)) \(quantityPrefix(for: item))\(item.name)")
        }

        if !completed.isEmpty {
            lines.append("")
            lines.append("Picked up:")
            for item in completed {
                lines.append("  [x] \(item.name)")
            }
        }

        lines.append("")
        lines.append("\(active.count) item\(active.count == 1 ? "" : "s") selected")
        return lines.joined(separator: "\n")
    }

    private static func storeLabel(for storeId: String, storeLabels: [String: String]) -> String {
        storeLabels[storeId] ?? SeedData.storeLabel(for: storeId)
    }

    private static var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: .now)
    }

    private static func checkbox(for item: GroceryItem) -> String {
        "☐"
    }

    private static func quantityPrefix(for item: GroceryItem) -> String {
        if let text = item.quantityText, !text.isEmpty {
            return "\(text) "
        }
        if let qty = item.quantityValue, qty > 1 {
            return "\(qty)x "
        }
        return ""
    }

    private static func orderedStoreKeys(
        from groups: [String: [GroceryItem]],
        storeOrder: [String]
    ) -> [String] {
        var keys = storeOrder.filter { groups[$0] != nil }
        if groups["__none__"] != nil {
            keys.append("__none__")
        }
        for key in groups.keys where !keys.contains(key) {
            keys.append(key)
        }
        return keys
    }
}
