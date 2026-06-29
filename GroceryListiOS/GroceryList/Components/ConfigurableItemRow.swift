import SwiftUI
import SwiftData

struct ConfigurableItemRow: View {
    @Environment(\.modelContext) private var modelContext

    let item: GroceryItem
    var metadataMode: ItemRowMetadataMode = .full
    var isCompleted: Bool = false
    var isSelectionMode: Bool = false
    var isSelected: Bool = false
    var showsEditButton: Bool = true
    let actions: ListItemRowActions

    private var categories: [CategoryService.CategoryInfo] {
        ItemMetadataChips.orderedCategories()
    }

    private var stores: [StoreService.StoreInfo] {
        StoreService.allStores(context: modelContext)
    }

    var body: some View {
        SwipeToDeleteRow(
            isEnabled: !isSelectionMode,
            onDelete: { actions.onDelete(item) }
        ) {
            ItemRow(
                item: item,
                metadataMode: metadataMode,
                categories: categories,
                stores: stores,
                isCompleted: isCompleted,
                isSelectionMode: isSelectionMode,
                isSelected: isSelected,
                showsEditButton: showsEditButton,
                onToggle: {
                    if isSelectionMode {
                        actions.onSelect(item)
                    } else {
                        actions.onToggle(item)
                    }
                },
                onIncrement: { actions.onIncrement(item) },
                onDecrement: { actions.onDecrement(item) },
                onShowActions: { actions.onEdit(item) },
                onSelectCategory: { categoryId in
                    guard categoryId != item.categoryId else { return }
                    actions.onUpdateCategory(item, categoryId)
                },
                onSelectStore: { storeId in
                    guard storeId != item.storeId else { return }
                    actions.onUpdateStore(item, storeId)
                }
            )
            .background(isSelected ? AppColors.accentLink.opacity(0.08) : Color.clear)
        }
        .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}

struct ListItemRowActions {
    let onToggle: (GroceryItem) -> Void
    let onIncrement: (GroceryItem) -> Void
    let onDecrement: (GroceryItem) -> Void
    let onEdit: (GroceryItem) -> Void
    let onDelete: (GroceryItem) -> Void
    let onDuplicate: (GroceryItem) -> Void
    let onUpdateCategory: (GroceryItem, String) -> Void
    let onUpdateStore: (GroceryItem, String?) -> Void
    let onSelect: (GroceryItem) -> Void

    @MainActor
    static func from(viewModel: ListDetailViewModel, list: GroceryList, context: ModelContext) -> ListItemRowActions {
        ListItemRowActions(
            onToggle: { viewModel.toggleComplete($0, context: context) },
            onIncrement: { viewModel.incrementQuantity($0, context: context) },
            onDecrement: { viewModel.decrementQuantity($0, context: context) },
            onEdit: { viewModel.editingItem = $0 },
            onDelete: { viewModel.deleteItem($0, context: context) },
            onDuplicate: { viewModel.duplicateItem($0, in: list, context: context) },
            onUpdateCategory: { viewModel.updateCategory($0, categoryId: $1, context: context) },
            onUpdateStore: { viewModel.updateStore($0, storeId: $1, context: context) },
            onSelect: { viewModel.toggleSelection(for: $0) }
        )
    }

    @MainActor
    static func focused(from viewModel: FocusedShoppingViewModel, list: GroceryList, context: ModelContext) -> ListItemRowActions {
        ListItemRowActions(
            onToggle: { viewModel.toggleComplete($0, context: context) },
            onIncrement: { viewModel.incrementQuantity($0, context: context) },
            onDecrement: { viewModel.decrementQuantity($0, context: context) },
            onEdit: { _ in },
            onDelete: { viewModel.deleteItem($0, context: context) },
            onDuplicate: { _ in },
            onUpdateCategory: { _, _ in },
            onUpdateStore: { _, _ in },
            onSelect: { _ in }
        )
    }
}
