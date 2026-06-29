import SwiftUI

struct CategoryOrderView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var orderedIds: [String] = AppSettings.categoryOrder

    private var categories: [SeedData.CategoryDefinition] {
        let all = SeedData.loadCategories()?.categories ?? []
        let lookup = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
        var result = orderedIds.compactMap { lookup[$0] }
        for category in all where !orderedIds.contains(category.id) {
            result.append(category)
        }
        return result
    }

    var body: some View {
        List {
            Section {
                ForEach(categories, id: \.id) { category in
                    HStack(spacing: 14) {
                        CategoryIconView(
                            categoryId: category.id,
                            containerSize: 44,
                            imageSize: 34,
                            cornerRadius: 11
                        )

                        Text(category.label)
                            .font(AppTypography.itemTitle)
                            .foregroundStyle(AppColors.ink)

                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 6)
                    .listRowBackground(AppColors.backgroundPrimary)
                }
                .onMove { source, destination in
                    var ids = categories.map(\.id)
                    ids.move(fromOffsets: source, toOffset: destination)
                    orderedIds = ids
                    AppSettings.categoryOrder = ids
                    HapticsService.selection()
                }
            } footer: {
                Text("Drag to reorder categories to match your shopping route.")
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.inkSecondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppColors.backgroundGrouped)
        .navigationTitle("Reorder Categories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Reset") {
                    AppSettings.resetCategoryOrder()
                    orderedIds = AppSettings.defaultCategoryOrder
                    HapticsService.selection()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .fontWeight(.semibold)
            }
        }
        .environment(\.editMode, .constant(.active))
        .settingsSubpageStyle()
    }
}

#Preview {
    NavigationStack {
        CategoryOrderView()
    }
}
