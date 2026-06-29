import Foundation

enum StoreBranding {
    private static let palette = [
        "#4A7C59", "#3D6B8E", "#8B6F8E", "#C17B3A",
        "#5C7A4A", "#6B5B95", "#2E7D6E", "#B85C38",
    ]

    static func iconSymbol(for label: String) -> String {
        let lower = label.lowercased()
        if lower.contains("farm") || lower.contains("farmers") { return "leaf.fill" }
        if lower.contains("bakery") || lower.contains("bread") { return "basket.fill" }
        if lower.contains("meat") || lower.contains("butcher") { return "fork.knife" }
        if lower.contains("pet") { return "pawprint.fill" }
        if lower.contains("pharmacy") || lower.contains("health") { return "cross.case.fill" }
        if lower.contains("indian") || lower.contains("asian") { return "takeoutbag.and.cup.and.straw.fill" }
        if lower.contains("market") || lower.contains("store") || lower.contains("shop") { return "storefront.fill" }
        return "storefront.fill"
    }

    static func colorHex(for label: String) -> String {
        let hash = abs(label.lowercased().hashValue)
        return palette[hash % palette.count]
    }
}
