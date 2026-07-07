import SwiftUI
import SwiftData

struct ManageStoresView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showAddStoreSheet = false

    private var stores: [StoreService.StoreInfo] {
        StoreService.allStores(context: modelContext)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Built-in and custom stores used when adding items or shopping by store.")
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.inkSecondary)
                    .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    ForEach(Array(stores.enumerated()), id: \.element.id) { index, store in
                        if index > 0 {
                            SettingsDivider()
                        }
                        storeRow(store)
                    }
                }
                .appCard(padding: 0)

                Button {
                    showAddStoreSheet = true
                } label: {
                    Label("Add Custom Store", systemImage: "plus.circle.fill")
                        .font(AppTypography.button)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityLabel("Add custom store")
            }
            .adaptiveScreenContent()
            .padding(.vertical, 16)
            .padding(.bottom, 8)
        }
        .background(AppColors.backgroundGrouped)
        .navigationTitle("Manage Stores")
        .navigationBarTitleDisplayMode(.inline)
        .settingsSubpageStyle()
        .adaptiveSheet(isPresented: $showAddStoreSheet) {
            AddCustomStoreSheet()
        }
    }

    private func storeRow(_ store: StoreService.StoreInfo) -> some View {
        HStack(spacing: 14) {
            StoreLogoView(
                storeId: store.id,
                displayLabel: store.label,
                size: 40,
                cornerRadius: 10
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(store.label)
                    .font(AppTypography.itemTitle)
                    .foregroundStyle(AppColors.ink)
                Text(store.isCustom ? "Custom store" : "Default store")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.inkSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}

struct ManageCategoriesView: View {
    @State private var showAddCategorySheet = false

    private var categories: [CategoryService.CategoryInfo] {
        CategoryService.allCategories()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Built-in and custom categories used when organizing items.")
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.inkSecondary)
                    .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                        if index > 0 {
                            SettingsDivider()
                        }
                        categoryRow(category)
                    }
                }
                .appCard(padding: 0)

                Button {
                    showAddCategorySheet = true
                } label: {
                    Label("Add Custom Category", systemImage: "plus.circle.fill")
                        .font(AppTypography.button)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityLabel("Add custom category")
            }
            .adaptiveScreenContent()
            .padding(.vertical, 16)
            .padding(.bottom, 8)
        }
        .background(AppColors.backgroundGrouped)
        .navigationTitle("Manage Categories")
        .navigationBarTitleDisplayMode(.inline)
        .settingsSubpageStyle()
        .adaptiveSheet(isPresented: $showAddCategorySheet) {
            AddCustomCategorySheet()
        }
    }

    private func categoryRow(_ category: CategoryService.CategoryInfo) -> some View {
        HStack(spacing: 14) {
            CategoryIconView(
                categoryId: category.id,
                containerSize: 40,
                cornerRadius: 10
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(category.label)
                    .font(AppTypography.itemTitle)
                    .foregroundStyle(AppColors.ink)
                Text(category.isCustom ? "Custom category" : "Default category")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.inkSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Manage Stores") {
    NavigationStack {
        ManageStoresView()
    }
    .modelContainer(try! ModelContainerSetup.makeContainer(inMemory: true))
}

#Preview("Manage Categories") {
    NavigationStack {
        ManageCategoriesView()
    }
}
