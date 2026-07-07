import SwiftUI
import SwiftData

struct StoreTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<GroceryList> { !$0.isArchived },
        sort: [SortDescriptor(\GroceryList.sortOrder), SortDescriptor(\GroceryList.name)]
    )
    private var lists: [GroceryList]

    private var activeList: GroceryList? {
        ActiveListResolver.resolve(from: lists)
    }

    private var allStores: [StoreService.StoreInfo] {
        StoreService.allStores(context: modelContext)
    }

    private var storeLabels: [String: String] {
        Dictionary(uniqueKeysWithValues: allStores.map { ($0.id, $0.label) })
    }

    private var displayStoreGroups: [ListGroupingService.StoreGroup] {
        guard let activeList else { return [] }
        return ListGroupingService.displayStoreGroups(
            items: activeList.items,
            storeOrder: allStores.map(\.id),
            storeLabels: storeLabels,
            includeCompleted: AppSettings.showCompletedInStoreView
        )
    }

    private var groupsWithItems: [ListGroupingService.StoreGroup] {
        displayStoreGroups.filter { !$0.items.isEmpty }
    }

    var body: some View {
        NavigationStack {
            TopLevelTabScreen(
                title: "Stores",
                subtitle: "See what to buy from each store."
            ) {
                Group {
                    if activeList == nil {
                        BrowseTabInactiveEmptyState(
                            imageName: "empty_store_illustration",
                            fallbackSystemImage: AppIcons.store,
                            title: "No active list",
                            subtitle: "Create a list on the Lists tab to shop by store."
                        )
                    } else if groupsWithItems.isEmpty {
                        BrowseTabEmptyState(
                            imageName: "empty_store_illustration",
                            fallbackSystemImage: AppIcons.store,
                            title: "No store items yet",
                            subtitle: "Add a store while entering an item, such as “milk from Costco.” Your items will appear here automatically."
                        )
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: AppSpacing.groupedSectionSpacing) {
                                GroupedBrowseToolbar(title: "Stores")

                                ForEach(groupsWithItems) { group in
                                    NavigationLink(
                                        value: StoreShoppingRoute(
                                            storeId: group.id,
                                            label: group.label
                                        )
                                    ) {
                                        GroupedSummaryCard(
                                            kind: .store(
                                                storeId: group.id == "__unassigned__" ? nil : group.id,
                                                label: group.label
                                            ),
                                            itemCount: group.items.count,
                                            items: group.items
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .adaptiveHorizontalPadding()
                            .padding(.top, AppSpacing.sectionSpacing)
                            .padding(.bottom, 32)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .navigationBarHidden(true)
            .navigationDestination(for: StoreShoppingRoute.self) { route in
                if let activeList {
                    StoreDetailView(
                        storeId: route.storeId,
                        storeLabel: route.label,
                        list: activeList
                    )
                }
            }
        }
    }
}

#Preview {
    StoreTabView()
        .modelContainer(try! ModelContainerSetup.makeContainer(inMemory: true))
}
