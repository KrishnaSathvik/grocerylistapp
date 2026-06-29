import SwiftUI
import SwiftData

struct CategoryGroupedListContent: View {
    @Bindable var list: GroceryList
    @Bindable var viewModel: ListDetailViewModel
    let modelContext: ModelContext
    var onFocusAdd: (() -> Void)?
    var onStarterChip: ((String) -> Void)?

    @State private var expandedCategoryIds: Set<String> = []

    private var groups: [ListGroupingService.CategoryGroup] {
        ListGroupingService.groupByCategory(items: list.items, includeCompleted: false)
    }

    private var actions: ListItemRowActions {
        ListItemRowActions.from(viewModel: viewModel, list: list, context: modelContext)
    }

    var body: some View {
        if groups.isEmpty {
            CategoriesEmptyState(
                onAddItem: { onFocusAdd?() },
                onStarterChip: { onStarterChip?($0) }
            )
            .frame(minHeight: 420)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        } else {
            ForEach(groups) { group in
                Section {
                    Button {
                        toggleExpansion(for: group.id)
                    } label: {
                        CategoryCardView(
                            categoryId: group.id,
                            label: group.label,
                            itemCount: group.items.count,
                            isExpanded: expandedCategoryIds.contains(group.id)
                        )
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    if expandedCategoryIds.contains(group.id) {
                        ForEach(group.items) { item in
                            ConfigurableItemRow(
                                item: item,
                                metadataMode: .storeOnly,
                                isSelectionMode: viewModel.isSelectionMode,
                                isSelected: viewModel.selectedItemIds.contains(item.id),
                                actions: actions
                            )
                            .listRowBackground(AppColors.backgroundPrimary)
                        }
                    }
                }
            }
        }
    }

    private func toggleExpansion(for categoryId: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedCategoryIds.contains(categoryId) {
                expandedCategoryIds.remove(categoryId)
            } else {
                expandedCategoryIds.insert(categoryId)
            }
        }
    }
}
