#if DEBUG
import Foundation
import SwiftData

/// DEBUG-only seed for final 182-asset catalog simulator review.
/// Activate with launch argument: `-FinalCatalogReview`
enum FinalCatalogReviewSeed {
    static let launchArgument = "-FinalCatalogReview"
    static let listName = "Final Catalog Review"

    /// Representative typed names + aliases across categories.
    /// Includes one intentional unmatched spice name for category-fallback coverage.
    static let reviewLines: [String] = [
        // Dairy / drinks
        "Milk from Walmart",
        "Oat milk from Costco",
        "Yogurt from Walmart",
        // Produce + aliases
        "Lettuce from Walmart",
        "Aam from Indian Bazaar",
        "Gobi from Indian Bazaar",
        "Green chili from Indian Bazaar",
        "Lauki from Indian Bazaar",
        "Shallots from Costco",
        "Spinach from Walmart",
        // Bakery flatbreads (near-dupe visual check)
        "Roti from Indian Bazaar",
        "Paratha from Indian Bazaar",
        "Naan from Indian Bazaar",
        "Pita bread from Costco",
        // Meat / seafood
        "Chicken drumsticks from Costco",
        "Ground turkey from Walmart",
        "Shrimp from Costco",
        // Pantry / condiments
        "Olive oil from Walmart",
        "Basmati rice from Indian Bazaar",
        "Pasta from Costco",
        // Beverages / snacks / frozen
        "Ginger ale from Walmart",
        "Protein bars from Costco",
        "Frozen pizza from Costco",
        // Household / care / baby / pet / floral
        "Toothpaste from Walmart",
        "Dish soap from Costco",
        "Baby wipes from Target",
        "Cat food from Petco",
        "Bouquet from Florist",
        // Category fallback (no product match; produce-form block)
        "Onion powder from Walmart",
        "Curry powder from Indian Bazaar",
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
            description: "Final 182-asset catalog simulator review",
            iconName: "cart.fill",
            tintHex: "#3D7EA6",
            context: context
        ) else {
            return nil
        }

        for line in reviewLines {
            GroceryItemService.addItems(name: line, to: list, context: context)
        }

        // Mark two trailing items completed so checked-state treatment is visible.
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
