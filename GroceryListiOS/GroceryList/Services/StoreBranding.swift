import Foundation

enum StoreBranding {
    static let customStoreColorOptions: [String] = [
        "#4A7C59", "#3D7EA6", "#C4883C", "#A63D40", "#6A8E7F", "#5E7EA8",
        "#8B6F8E", "#7A8B6F", "#B08968", "#6B7D8E", "#2E7D6E", "#B85C38",
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
        return customStoreColorOptions[hash % customStoreColorOptions.count]
    }
}

enum CustomStoreIconOptions {
    static let symbols: [(name: String, label: String)] = [
        ("storefront.fill", "Storefront"),
        ("cart.fill", "Cart"),
        ("basket.fill", "Basket"),
        ("bag.fill", "Bag"),
        ("building.2.fill", "Building"),
        ("leaf.fill", "Farmers market"),
        ("fork.knife", "Food shop"),
        ("cup.and.saucer.fill", "Cafe"),
        ("cross.case.fill", "Pharmacy"),
        ("pawprint.fill", "Pet store"),
        ("takeoutbag.and.cup.and.straw.fill", "Takeout"),
        ("mappin.and.ellipse", "Local shop"),
        ("house.fill", "Neighborhood"),
        ("star.fill", "Favorite"),
        ("sparkles", "Specialty"),
        ("shippingbox.fill", "Bulk"),
    ]
}
