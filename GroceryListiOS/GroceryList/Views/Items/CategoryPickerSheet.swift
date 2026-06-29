import SwiftUI

struct CategoryPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategoryId: String

    var itemName: String?

    @State private var searchText = ""

    private var orderedCategories: [CategoryService.CategoryInfo] {
        let order = AppSettings.categoryOrder
        let all = CategoryService.allCategories()
        let lookup = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
        var result = order.compactMap { lookup[$0] }
        for category in all where !order.contains(category.id) {
            result.append(category)
        }
        guard !searchText.isEmpty else { return result }
        return result.filter {
            $0.label.localizedCaseInsensitiveContains(searchText)
                || $0.id.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let itemName {
                    itemContextHeader(name: itemName)
                        .padding(.horizontal, AppSpacing.screenHorizontal)
                        .padding(.top, 4)
                        .padding(.bottom, 12)
                }

                searchField
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.bottom, 12)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(orderedCategories) { category in
                            categoryRow(category)
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.bottom, 16)
                }
            }
            .background(AppColors.backgroundGrouped)
            .navigationTitle("Change Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .accessibilityLabel("Done choosing category")
                }
            }
        }
    }

    private func itemContextHeader(name: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(AppTypography.cardTitle)
                .foregroundStyle(AppColors.ink)
                .lineLimit(2)
            Text("Currently: \(CategoryService.label(for: selectedCategoryId))")
                .font(AppTypography.metadata)
                .foregroundStyle(AppColors.inkSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.medium))
                .foregroundStyle(AppColors.inkSecondary)
            TextField("Search categories", text: $searchText)
                .font(AppTypography.itemTitle)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityLabel("Search categories")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppColors.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
    }

    private func categoryRow(_ category: CategoryService.CategoryInfo) -> some View {
        let isSelected = selectedCategoryId == category.id

        return Button {
            selectedCategoryId = category.id
            HapticsService.selection()
        } label: {
            HStack(spacing: 14) {
                CategoryIconView(
                    categoryId: category.id,
                    containerSize: 36,
                    imageSize: 28,
                    cornerRadius: 10
                )

                Text(category.label)
                    .font(AppTypography.itemTitle)
                    .foregroundStyle(AppColors.ink)

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.accentPrimary)
                }
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 58)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? AppColors.accentSuccess.opacity(0.12) : AppColors.backgroundPrimary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? AppColors.accentSuccess.opacity(0.28) : AppColors.cardBorder, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.bottom, 8)
        .accessibilityLabel("\(category.label)\(isSelected ? ", selected" : "")")
    }
}
