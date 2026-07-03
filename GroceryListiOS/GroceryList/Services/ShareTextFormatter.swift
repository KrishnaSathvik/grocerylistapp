import Foundation

enum ShareTextFormatter {
    static func format(list: GroceryList) -> String {
        let items = list.items.filter { !$0.isArchived }
        let active = items.filter { !$0.isCompleted }.sorted { $0.sortOrder < $1.sortOrder }
        let completed = items.filter(\.isCompleted).sorted { $0.sortOrder < $1.sortOrder }

        var lines: [String] = []
        lines.append("Groceries — Smart Lists")
        lines.append(formattedDate)
        lines.append("")

        let storeGroups = Dictionary(grouping: active) { $0.storeId ?? "__none__" }
        let hasStores = storeGroups.keys.contains { $0 != "__none__" }

        if hasStores {
            for storeId in orderedStoreKeys(from: storeGroups) where storeId != "__none__" {
                lines.append("\(SeedData.storeLabel(for: storeId)):")
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

    private static var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: .now)
    }

    private static func checkbox(for item: GroceryItem) -> String {
        "[ ]"
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

    private static func orderedStoreKeys(from groups: [String: [GroceryItem]]) -> [String] {
        let seedOrder = SeedData.loadStoreDefinitions().map(\.id)
        var keys = seedOrder.filter { groups[$0] != nil }
        if groups["__none__"] != nil {
            keys.append("__none__")
        }
        for key in groups.keys where !keys.contains(key) {
            keys.append(key)
        }
        return keys
    }
}
