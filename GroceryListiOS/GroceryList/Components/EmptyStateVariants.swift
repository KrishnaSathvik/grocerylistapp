import SwiftUI

struct MyListsEmptyState: View {
    var onCreateList: () -> Void

    var body: some View {
        EmptyStateScene(
            title: "No lists yet",
            message: "Create a list or pick a starter template below.",
            illustration: { GroceryBasketIllustration(size: 130) },
            primaryTitle: "New List",
            primaryAction: onCreateList
        )
    }
}

struct ListDetailEmptyState: View {
    var onAddItem: () -> Void
    var onImport: () -> Void
    var onStarterChip: (String) -> Void

    private let chips = ["2 eggs from Walmart", "bananas 6", "bread from Trader Joe's"]

    var body: some View {
        EmptyStateScene(
            title: "Your list is empty",
            message: "Add your first item or import a saved list to get started.",
            illustration: { PaperBagIllustration(size: 150) },
            primaryTitle: "Add Item",
            primaryAction: onAddItem,
            secondaryTitle: "Import List",
            secondaryAction: onImport,
            starterChips: chips,
            onStarterChip: onStarterChip
        )
    }
}

struct StoreEmptyState: View {
    var onAddItem: () -> Void
    var onAddCustomStore: () -> Void
    var onStarterChip: (String) -> Void

    private let chips = ["milk from Costco", "rice from H Mart", "snacks from Target"]

    var body: some View {
        EmptyStateScene(
            title: "No store items yet",
            message: "Add items with a store, like “milk from Costco”, to group them by where you shop.",
            illustration: { StorefrontIllustration(size: 140) },
            primaryTitle: "Add Item",
            primaryAction: onAddItem,
            secondaryTitle: "Add Custom Store",
            secondaryAction: onAddCustomStore,
            starterChips: chips,
            onStarterChip: onStarterChip,
            expandVertically: true
        )
    }
}

struct CategoriesEmptyState: View {
    var onAddItem: () -> Void
    var onStarterChip: (String) -> Void

    private let chips = ["bananas", "milk", "gochujang"]

    var body: some View {
        EmptyStateScene(
            title: "No categories yet",
            message: "Add groceries and we'll sort them into aisles automatically.",
            illustration: { CategoryGridIllustration(size: 130) },
            primaryTitle: "Add Item",
            primaryAction: onAddItem,
            starterChips: chips,
            onStarterChip: onStarterChip,
            expandVertically: true
        )
    }
}
