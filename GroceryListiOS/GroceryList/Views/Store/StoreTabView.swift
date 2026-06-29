import SwiftUI
import SwiftData

struct StoreTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<GroceryList> { !$0.isArchived },
        sort: [SortDescriptor(\GroceryList.sortOrder), SortDescriptor(\GroceryList.name)]
    )
    private var lists: [GroceryList]

    @State private var showAddStoreSheet = false

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

    private var headerSubtitle: String {
        guard let activeList else { return "Create a list to shop by store" }
        let count = groupsWithItems.count
        let label = count == 1 ? "store" : "stores"
        return "\(activeList.name) · \(count) \(label)"
    }

    var body: some View {
        NavigationStack {
            TopLevelTabScreen(title: "Store", subtitle: headerSubtitle) {
                ScrollView {
                    VStack(spacing: 0) {
                        PrimaryActionRow(
                            title: "Add Store",
                            systemImage: "plus.circle.fill"
                        ) {
                            showAddStoreSheet = true
                        }
                        .padding(.horizontal, AppSpacing.screenHorizontal)

                        if activeList == nil {
                            EmptyStateView(
                                title: "No active list",
                                message: "Create a list on the Lists tab to shop by store.",
                                systemImage: AppIcons.store
                            )
                            .padding(.horizontal, AppSpacing.screenHorizontal)
                            .padding(.top, AppSpacing.sectionSpacing)
                        } else if groupsWithItems.isEmpty {
                            ImageEmptyStateHero(
                                imageName: "empty_store_illustration",
                                fallbackSystemImage: "storefront",
                                title: "No stores yet",
                                subtitle: "Add items with a store, like “milk from Costco”, and they'll appear here grouped by where you shop."
                            )
                            .padding(.horizontal, AppSpacing.screenHorizontal)
                            .padding(.top, AppSpacing.sectionSpacing)
                        } else {
                            VStack(alignment: .leading, spacing: AppSpacing.groupedSectionSpacing) {
                                Text("Stores")
                                    .appSectionLabel()
                                    .padding(.horizontal, AppSpacing.screenHorizontal)
                                    .padding(.top, AppSpacing.sectionSpacing)

                                ForEach(groupsWithItems) { group in
                                    GroupedSummaryCard(
                                        kind: .store(
                                            storeId: group.id == "__unassigned__" ? nil : group.id,
                                            label: group.label
                                        ),
                                        itemCount: group.items.count,
                                        items: group.items
                                    )
                                    .padding(.horizontal, AppSpacing.screenHorizontal)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddStoreSheet) {
                AddCustomStoreSheet()
            }
        }
    }
}

#Preview {
    StoreTabView()
        .modelContainer(try! ModelContainerSetup.makeContainer(inMemory: true))
}
