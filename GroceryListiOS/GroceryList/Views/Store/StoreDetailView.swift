import SwiftUI
import SwiftData

struct StoreDetailView: View {
    let storeId: String
    let storeLabel: String
    @Bindable var list: GroceryList

    var body: some View {
        FocusedShoppingView(
            list: list,
            mode: .store(storeId: storeId, label: storeLabel)
        )
    }
}

#Preview {
    NavigationStack {
        StoreDetailView(
            storeId: "costco",
            storeLabel: "Costco",
            list: GroceryList(name: "Weekly")
        )
    }
    .modelContainer(try! ModelContainerSetup.makeContainer(inMemory: true))
}
