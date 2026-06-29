import SwiftUI
import SwiftData

struct CategoryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<GroceryList> { !$0.isArchived },
        sort: [SortDescriptor(\GroceryList.sortOrder), SortDescriptor(\GroceryList.name)]
    )
    private var lists: [GroceryList]

    @Bindable var list: GroceryList
    let categoryId: String
    let categoryLabel: String

    @State private var viewModel = ListDetailViewModel()

    private var items: [GroceryItem] {
        list.items
            .filter { !$0.isArchived && !$0.isCompleted && $0.categoryId == categoryId }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private var actions: ListItemRowActions {
        ListItemRowActions.from(viewModel: viewModel, list: list, context: modelContext)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            List {
                if items.isEmpty {
                    EmptyStateView(
                        title: "No items",
                        message: "Nothing in this category yet.",
                        systemImage: AppIcons.categorySymbol(for: categoryId)
                    )
                    .frame(minHeight: 200)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(items) { item in
                        ConfigurableItemRow(item: item, metadataMode: .storeOnly, actions: actions)
                            .listRowBackground(AppColors.backgroundPrimary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppColors.backgroundGrouped)

            if let message = viewModel.toastMessage, viewModel.undoSnapshot != nil {
                UndoBanner(message: message) {
                    viewModel.undoDelete(in: list, context: modelContext)
                }
                .padding(.bottom, 16)
            }
        }
        .navigationTitle(categoryLabel)
        .navigationBarTitleDisplayMode(.large)
        .fullScreenCover(item: $viewModel.editingItem) { item in
            EditItemSheet(
                item: item,
                lists: lists,
                onSave: { draft in
                    viewModel.saveEdit(for: item, draft: draft, context: modelContext)
                },
                onDuplicate: {
                    viewModel.duplicateFromEdit(item, in: list, context: modelContext)
                },
                onDelete: {
                    viewModel.deleteFromEdit(item, context: modelContext)
                }
            )
        }
    }
}
