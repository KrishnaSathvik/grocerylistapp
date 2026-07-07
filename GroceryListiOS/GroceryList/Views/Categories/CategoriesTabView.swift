import SwiftUI
import SwiftData

struct CategoriesTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<GroceryList> { !$0.isArchived },
        sort: [SortDescriptor(\GroceryList.sortOrder), SortDescriptor(\GroceryList.name)]
    )
    private var lists: [GroceryList]

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
                            imageName: "empty_categories_illustration",
                            fallbackSystemImage: AppIcons.categories,
                            title: "No active list",
                            subtitle: "Create a list on the Lists tab to browse by category."
                        )
                    } else if groupsWithItems.isEmpty {
                        BrowseTabEmptyState(
                            imageName: "empty_categories_illustration",
                            fallbackSystemImage: AppIcons.categories,
                            title: "No categorized items yet",
                            subtitle: "Add items to a list and we'll organize them into categories automatically."
                        )
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: AppSpacing.groupedSectionSpacing) {
                                GroupedBrowseToolbar(title: "Categories")

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
            .navigationDestination(for: CategoryShoppingRoute.self) { route in
                if let activeList {
                    CategoryDetailView(
                        list: activeList,
                        categoryId: route.categoryId,
                        categoryLabel: route.label
                    )
                }
            }
        }
    }
}

#Preview {
    CategoriesTabView()
        .modelContainer(try! ModelContainerSetup.makeContainer(inMemory: true))
}
