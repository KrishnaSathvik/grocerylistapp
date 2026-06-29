import SwiftUI
import SwiftData

struct CategoriesTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<GroceryList> { !$0.isArchived },
        sort: [SortDescriptor(\GroceryList.sortOrder), SortDescriptor(\GroceryList.name)]
    )
    private var lists: [GroceryList]

    @State private var showAddCategorySheet = false

    private var activeList: GroceryList? {
        ActiveListResolver.resolve(from: lists)
    }

    private var categoryGroups: [ListGroupingService.CategoryGroup] {
        guard let activeList else { return [] }
        return ListGroupingService.displayCategoryGroups(items: activeList.items, includeCompleted: false)
    }

    private var groupsWithItems: [ListGroupingService.CategoryGroup] {
        categoryGroups.filter { !$0.items.isEmpty }
    }

    var body: some View {
        NavigationStack {
            TopLevelTabScreen(
                title: "Categories",
                subtitle: "Browse your list by grocery aisle or item type."
            ) {
                Group {
                    if activeList == nil {
                        BrowseTabInactiveEmptyState(
                            imageName: "empty_list_illustration",
                            fallbackSystemImage: AppIcons.categories,
                            title: "No active list",
                            subtitle: "Create a list on the Lists tab to browse by category."
                        )
                    } else if groupsWithItems.isEmpty {
                        BrowseTabEmptyState(
                            actionTitle: "Add custom category",
                            action: { showAddCategorySheet = true },
                            imageName: "empty_list_illustration",
                            fallbackSystemImage: AppIcons.categories,
                            title: "No categories yet",
                            subtitle: "Add a custom category above, or add items on your list and we'll organize them automatically."
                        )
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: AppSpacing.groupedSectionSpacing) {
                                GroupedBrowseToolbar(title: "Categories", actionTitle: "Add Category") {
                                    showAddCategorySheet = true
                                }
                                .adaptiveHorizontalPadding()
                                .padding(.top, AppSpacing.sectionSpacing)

                                ForEach(groupsWithItems) { group in
                                    NavigationLink(
                                        value: CategoryShoppingRoute(
                                            categoryId: group.id,
                                            label: group.label
                                        )
                                    ) {
                                        GroupedSummaryCard(
                                            kind: .category(
                                                categoryId: group.id,
                                                label: group.label
                                            ),
                                            itemCount: group.items.count,
                                            items: group.items
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .adaptiveHorizontalPadding()
                                }
                            }
                            .padding(.bottom, 32)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .navigationBarHidden(true)
            .navigationDestination(for: CategoryShoppingRoute.self) { route in
                if let activeList {
                    CategoryDetailView(
                        list: activeList,
                        categoryId: route.categoryId,
                        categoryLabel: route.label
                    )
                }
            }
            .sheet(isPresented: $showAddCategorySheet) {
                AddCustomCategorySheet()
            }
        }
    }
}

#Preview {
    CategoriesTabView()
        .modelContainer(try! ModelContainerSetup.makeContainer(inMemory: true))
}
