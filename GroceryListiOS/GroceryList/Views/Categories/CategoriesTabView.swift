import SwiftUI
import SwiftData

struct CategoriesTabView: View {
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

    private var headerSubtitle: String {
        guard let activeList else { return "Create a list to browse by category" }
        let count = categoryGroups.count
        let label = count == 1 ? "category" : "categories"
        return "\(activeList.name) · \(count) \(label)"
    }

    var body: some View {
        NavigationStack {
            TopLevelTabScreen(title: "Categories", subtitle: headerSubtitle) {
                ScrollView {
                    VStack(spacing: 0) {
                        PrimaryActionRow(
                            title: "Add Category",
                            systemImage: "plus.circle.fill"
                        ) {
                            showAddCategorySheet = true
                        }
                        .padding(.horizontal, AppSpacing.screenHorizontal)

                        if activeList == nil {
                            EmptyStateView(
                                title: "No active list",
                                message: "Create a list on the Lists tab to browse by category.",
                                systemImage: AppIcons.categories
                            )
                            .padding(.horizontal, AppSpacing.screenHorizontal)
                            .padding(.top, AppSpacing.sectionSpacing)
                        } else if categoryGroups.isEmpty {
                            ImageEmptyStateHero(
                                imageName: "empty_categories_illustration",
                                fallbackSystemImage: "square.grid.2x2",
                                title: "No categories yet",
                                subtitle: "Your grocery items will be organized into categories here automatically."
                            )
                            .padding(.horizontal, AppSpacing.screenHorizontal)
                            .padding(.top, AppSpacing.sectionSpacing)
                        } else {
                            VStack(alignment: .leading, spacing: AppSpacing.groupedSectionSpacing) {
                                Text("Categories")
                                    .appSectionLabel()
                                    .padding(.horizontal, AppSpacing.screenHorizontal)
                                    .padding(.top, AppSpacing.sectionSpacing)

                                ForEach(categoryGroups) { group in
                                    GroupedSummaryCard(
                                        kind: .category(
                                            categoryId: group.id,
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
