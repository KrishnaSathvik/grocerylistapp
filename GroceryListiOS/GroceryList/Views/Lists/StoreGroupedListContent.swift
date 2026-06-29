import SwiftUI
import SwiftData

struct StoreGroupedListContent: View {
    @Bindable var list: GroceryList
    @Bindable var viewModel: ListDetailViewModel
    let modelContext: ModelContext

    private var groups: [ListGroupingService.StoreGroup] {
        ListGroupingService.groupByStore(
            items: list.items,
            includeCompleted: AppSettings.showCompletedInStoreView,
            storeOrder: StoreService.allStores(context: modelContext).map(\.id)
        )
    }

    private var actions: ListItemRowActions {
        ListItemRowActions.from(viewModel: viewModel, list: list, context: modelContext)
    }

    var body: some View {
        LazyVStack(spacing: AppSpacing.sectionSpacing) {
            ForEach(groups) { group in
                VStack(alignment: .leading, spacing: 8) {
                    StoreSectionHeader(
                        storeId: group.id == "__unassigned__" ? nil : group.id,
                        label: group.label,
                        itemCount: group.items.count
                    )

                    VStack(spacing: 0) {
                        ForEach(group.items) { item in
                            ConfigurableItemRow(
                                item: item,
                                metadataMode: .categoryOnly,
                                isSelectionMode: viewModel.isSelectionMode,
                                isSelected: viewModel.selectedItemIds.contains(item.id),
                                actions: actions
                            )
                            if item.id != group.items.last?.id {
                                Divider()
                                    .padding(.leading, 50)
                            }
                        }
                    }
                    .background(AppColors.backgroundPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous)
                            .stroke(AppColors.cardBorder, lineWidth: 1)
                    )
                }
            }
        }
    }
}
