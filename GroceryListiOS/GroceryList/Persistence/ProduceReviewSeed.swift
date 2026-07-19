#if DEBUG
import Foundation
import SwiftData

/// DEBUG-only seed for interactive product-asset simulator review.
/// Activate with launch argument: `-B1ProduceReview`
enum ProduceReviewSeed {
    static let launchArgument = "-B1ProduceReview"
    static let listName = "B1 Produce Review"

    /// Stage 1 / B1 acceptance names plus long titles for content-fit review.
    /// Store phrases keep Store grouping meaningful.
    /// Gate names are ordered near the top so first-viewport screenshots cover them.
    static let reviewLines: [String] = [
        "Orange from Walmart",
        "Grapes from Walmart",
        "Cabbage from Walmart",
        "Broccoli from Costco",
        "Cucumber from Walmart",
        "Zucchini from Walmart",
        "Eggplant from Indian Bazaar",
        "Mushrooms from Costco",
        "Strawberries from Costco",
        "Watermelon from Costco",
        "Chicken drumsticks from Costco",
        "Extra virgin olive oil from Walmart",
        "Unsweetened vanilla almond milk from Costco",
        "Mango from Walmart",
        "Papaya from Walmart",
        "Cauliflower from Costco",
        "Carrots from Walmart",
        "Sweet potatoes from Walmart",
        "Bell peppers from Walmart",
        "Green chilies from Indian Bazaar",
        "Okra from Indian Bazaar",
        "Lauki from Indian Bazaar",
    ]

    static var isRequested: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    @discardableResult
    static func seedIfRequested(context: ModelContext) -> GroceryList? {
        guard isRequested else { return nil }

        let existing = (try? context.fetch(FetchDescriptor<GroceryList>())) ?? []
        if let list = existing.first(where: { $0.name == listName }) {
            ActiveListResolver.setActive(list)
            return list
        }

        guard let list = GroceryListService.createList(
            name: listName,
            description: "Phase B1 produce asset review",
            iconName: "leaf.fill",
            tintHex: "#4A7C59",
            context: context
        ) else {
            return nil
        }

        for line in reviewLines {
            GroceryItemService.addItems(name: line, to: list, context: context)
        }

        // Mark two trailing filler items completed (keep gate names in TO GET).
        let sorted = list.items.sorted { $0.sortOrder < $1.sortOrder }
        if sorted.count >= 2 {
            _ = GroceryItemService.toggleComplete(sorted[sorted.count - 1], context: context)
            _ = GroceryItemService.toggleComplete(sorted[sorted.count - 2], context: context)
        }

        ActiveListResolver.setActive(list)
        return list
    }
}
#endif
