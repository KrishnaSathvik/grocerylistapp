import Foundation
import SwiftData

/// DEBUG-only seed for interactive product-asset simulator review.
/// Activate with launch argument: `-B1ProduceReview`
enum ProduceReviewSeed {
    static let launchArgument = "-B1ProduceReview"
    static let listName = "B1 Produce Review"

    /// Representative Phase B1 items, with store phrases so Store grouping is meaningful.
    static let reviewLines: [String] = [
        "Mango from Walmart",
        "Orange from Walmart",
        "Grapes from Walmart",
        "Strawberries from Costco",
        "Watermelon from Costco",
        "Papaya from Walmart",
        "Cucumber from Walmart",
        "Zucchini from Walmart",
        "Broccoli from Costco",
        "Cauliflower from Costco",
        "Carrots from Walmart",
        "Sweet potatoes from Walmart",
        "Bell peppers from Walmart",
        "Green chilies from Indian Bazaar",
        "Eggplant from Indian Bazaar",
        "Mushrooms from Costco",
        "Cabbage from Walmart",
        "Okra from Indian Bazaar",
        "Lauki from Indian Bazaar",
        "Chicken drumsticks from Costco",
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

        // Mark two items completed to review opacity / saturation treatment.
        let sorted = list.items.sorted { $0.sortOrder < $1.sortOrder }
        if let first = sorted.first {
            _ = GroceryItemService.toggleComplete(first, context: context)
        }
        if sorted.count > 5 {
            _ = GroceryItemService.toggleComplete(sorted[5], context: context)
        }

        ActiveListResolver.setActive(list)
        return list
    }
}
