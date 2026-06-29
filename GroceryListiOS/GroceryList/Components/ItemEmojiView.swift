import SwiftUI

enum DemoGroceryItems {
    struct Item {
        let name: String
        let keyword: String
        let category: String
        let categoryId: String
        let assetName: String?

        var emoji: String {
            ItemEmojiCatalog.emoji(for: keyword) ?? "🛒"
        }
    }

    static let milk = Item(name: "Milk", keyword: "milk", category: "Dairy", categoryId: "dairy", assetName: "category-dairy")
    static let bananas = Item(name: "Bananas", keyword: "bananas", category: "Produce", categoryId: "produce", assetName: "category-produce")
    static let chicken = Item(name: "Chicken", keyword: "chicken", category: "Meat", categoryId: "meat", assetName: "category-meat")
    static let eggs = Item(name: "Eggs", keyword: "eggs", category: "Dairy", categoryId: "dairy", assetName: "category-dairy")
    static let rice = Item(name: "Basmati rice", keyword: "basmati rice", category: "Pantry", categoryId: "pantry", assetName: "category-pantry")
    static let gochujang = Item(name: "Gochujang", keyword: "gochujang", category: "Condiments", categoryId: "condiments", assetName: "category-condiments")
    static let tomatoes = Item(name: "Tomatoes", keyword: "tomato", category: "Produce", categoryId: "produce", assetName: nil)
    static let bread = Item(name: "Bread", keyword: "bread", category: "Bakery", categoryId: "bakery", assetName: "category-bakery")

    static let sortDemo: [Item] = [milk, bananas, chicken, tomatoes]
    static let organizeDemo: [Item] = [milk, eggs, rice]
    static let spotlight: [Item] = [milk, bananas, chicken, eggs]
    static let sharePreview: [Item] = [milk, bananas, chicken]
}
