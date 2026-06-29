import SwiftUI
import SwiftData

struct CategoryDetailView: View {
    @Bindable var list: GroceryList
    let categoryId: String
    let categoryLabel: String

    var body: some View {
        FocusedShoppingView(
            list: list,
            mode: .category(categoryId: categoryId, label: categoryLabel)
        )
    }
}

#Preview {
    NavigationStack {
        CategoryDetailView(
            list: GroceryList(name: "Weekly"),
            categoryId: "dairy",
            categoryLabel: "Dairy & Eggs"
        )
    }
    .modelContainer(try! ModelContainerSetup.makeContainer(inMemory: true))
}
