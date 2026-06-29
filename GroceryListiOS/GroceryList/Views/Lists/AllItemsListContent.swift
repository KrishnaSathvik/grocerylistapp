import SwiftUI
import SwiftData

struct AllItemsListContent: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var list: GroceryList
    @Bindable var viewModel: ListDetailViewModel
    let modelContext: ModelContext

    private var activeItems: [GroceryItem] {
        list.items
            .filter { !$0.isCompleted && !$0.isArchived }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private var completedItems: [GroceryItem] {
        list.items
            .filter { $0.isCompleted && !$0.isArchived }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private var actions: ListItemRowActions {
        ListItemRowActions.from(viewModel: viewModel, list: list, context: modelContext)
    }

    var body: some View {
        if !activeItems.isEmpty {
            Section {
                ForEach(activeItems) { item in
                    ConfigurableItemRow(
                        item: item,
                        isSelectionMode: viewModel.isSelectionMode,
                        isSelected: viewModel.selectedItemIds.contains(item.id),
                        actions: actions
                    )
                    .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
                .deleteDisabled(true)
            } header: {
                HStack {
                    Text("To Get (\(activeItems.count))")
                        .appSectionLabel()
                    Spacer()
                }
                .textCase(nil)
            }
        }

        if !completedItems.isEmpty, viewModel.showCompletedItems {
            Section {
                if viewModel.isPickedUpExpanded {
                    ForEach(completedItems) { item in
                        ConfigurableItemRow(
                            item: item,
                            isCompleted: true,
                            isSelectionMode: viewModel.isSelectionMode,
                            isSelected: viewModel.selectedItemIds.contains(item.id),
                            actions: actions
                        )
                        .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
            } header: {
                pickedUpHeader
            }
        }
    }

    @ViewBuilder
    private var pickedUpHeader: some View {
        HStack {
            Button {
                if reduceMotion {
                    viewModel.isPickedUpExpanded.toggle()
                } else {
                    withAnimation { viewModel.isPickedUpExpanded.toggle() }
                }
            } label: {
                HStack(spacing: 6) {
                    Text("Picked up (\(completedItems.count))")
                        .appSectionLabel()
                    Image(systemName: viewModel.isPickedUpExpanded ? "chevron.up" : "chevron.down")
                        .font(AppTypography.caption.weight(.semibold))
                        .foregroundStyle(AppColors.inkSecondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Picked up, \(completedItems.count) items")
            .accessibilityValue(viewModel.isPickedUpExpanded ? "expanded" : "collapsed")
            .accessibilityHint("Double tap to \(viewModel.isPickedUpExpanded ? "collapse" : "expand")")

            Spacer()
        }
        .textCase(nil)
    }
}
