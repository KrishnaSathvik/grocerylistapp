import SwiftUI
import SwiftData

enum ItemRowMetadataMode {
    case full
    case categoryOnly
    case storeOnly
    /// Read-only store label (focused category shopping).
    case storeLabel
    /// No secondary metadata (focused store shopping, grouped by category).
    case hidden

    var showsCategory: Bool {
        self == .full || self == .categoryOnly
    }

    var showsStore: Bool {
        self == .full || self == .storeOnly || self == .storeLabel
    }

    var allowsMetadataEditing: Bool {
        switch self {
        case .full, .categoryOnly, .storeOnly: return true
        case .storeLabel, .hidden: return false
        }
    }
}

struct ItemMetadataChips: View {
    let item: GroceryItem
    let mode: ItemRowMetadataMode
    let categories: [CategoryService.CategoryInfo]
    let stores: [StoreService.StoreInfo]
    var isMuted: Bool = false
    let onSelectCategory: (String) -> Void
    let onSelectStore: (String?) -> Void

    private var secondaryInk: Color {
        isMuted ? AppColors.completedInk : AppColors.inkSecondary
    }

    var body: some View {
        switch mode {
        case .full:
            FullMetadataDisplay(item: item, inkColor: secondaryInk, isMuted: isMuted)
        case .hidden:
            EmptyView()
        case .categoryOnly:
            if mode.allowsMetadataEditing {
                CategoryChipMenu(
                    categoryId: item.categoryId,
                    categories: categories,
                    onSelect: onSelectCategory
                )
            } else {
                CategoryCompactPill(
                    categoryId: item.categoryId,
                    label: CategoryService.label(for: item.categoryId),
                    isMuted: isMuted
                )
            }
        case .storeOnly:
            if mode.allowsMetadataEditing {
                StoreChipMenu(
                    storeId: item.storeId,
                    stores: stores,
                    onSelect: onSelectStore
                )
            } else {
                StoreLabelDisplay(item: item, inkColor: secondaryInk)
            }
        case .storeLabel:
            StoreLabelDisplay(item: item, inkColor: secondaryInk)
        }
    }

    static func orderedCategories() -> [CategoryService.CategoryInfo] {
        let order = AppSettings.categoryOrder
        let all = CategoryService.allCategories()
        let lookup = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
        var result = order.compactMap { lookup[$0] }
        for category in all where !order.contains(category.id) {
            result.append(category)
        }
        return result
    }
}

// MARK: - Full metadata (list detail — display only)

private struct FullMetadataDisplay: View {
    let item: GroceryItem
    var inkColor: Color = AppColors.inkSecondary
    var isMuted: Bool = false

    private var categoryLabel: String {
        CategoryService.label(for: item.categoryId)
    }

    private var storeLabel: String? {
        guard let storeId = item.storeId, !storeId.isEmpty else { return nil }
        let label = SeedData.storeLabel(for: storeId)
        return label == "Unassigned" ? nil : label
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            metadataLine(includeStore: true)
            metadataLine(includeStore: false)
            CategoryCompactPill(
                categoryId: item.categoryId,
                label: categoryLabel,
                isMuted: isMuted
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel(metadataAccessibilityLabel)
    }

    @ViewBuilder
    private func metadataLine(includeStore: Bool) -> some View {
        if includeStore, let storeLabel {
            Text("\(categoryLabel) · \(storeLabel)")
                .font(AppTypography.metadata)
                .foregroundStyle(inkColor)
                .fixedSize(horizontal: true, vertical: false)
        } else {
            Text(categoryLabel)
                .font(AppTypography.metadata)
                .foregroundStyle(inkColor)
                .fixedSize(horizontal: true, vertical: false)
        }
    }

    private var metadataAccessibilityLabel: String {
        if let storeLabel {
            return "Category, \(categoryLabel), Store, \(storeLabel)"
        }
        return "Category, \(categoryLabel)"
    }
}

// MARK: - Read-only store label

private struct StoreLabelDisplay: View {
    let item: GroceryItem
    var inkColor: Color = AppColors.inkSecondary

    private var storeLabel: String? {
        guard let storeId = item.storeId, !storeId.isEmpty else { return nil }
        let label = SeedData.storeLabel(for: storeId)
        return label == "Unassigned" ? nil : label
    }

    var body: some View {
        if let storeLabel {
            Text(storeLabel)
                .font(AppTypography.metadata)
                .foregroundStyle(inkColor)
                .lineLimit(1)
        }
    }
}

// MARK: - Compact category pill

private struct CategoryCompactPill: View {
    let categoryId: String
    let label: String
    var isMuted: Bool = false

    private var accent: Color {
        if isMuted {
            return AppColors.completedInk
        }
        if let hex = CategoryService.colorHex(for: categoryId) {
            return AppColors.colorHex(hex)
        }
        return AppColors.accentSuccess
    }

    var body: some View {
        Text(label)
            .font(AppTypography.badge)
            .tracking(0.2)
            .foregroundStyle(accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(accent.opacity(0.14))
            .clipShape(Capsule())
            .fixedSize(horizontal: true, vertical: false)
    }
}

// MARK: - Category chip

private struct CategoryChipMenu: View {
    let categoryId: String
    let categories: [CategoryService.CategoryInfo]
    let onSelect: (String) -> Void

    private var label: String {
        CategoryService.label(for: categoryId)
    }

    private var accent: Color {
        if let hex = CategoryService.colorHex(for: categoryId) {
            return AppColors.colorHex(hex)
        }
        return AppColors.accentSuccess
    }

    var body: some View {
        Menu {
            ForEach(categories) { category in
                Button {
                    HapticsService.selection()
                    onSelect(category.id)
                } label: {
                    HStack {
                        Text(category.label)
                        if category.id == categoryId {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            ViewThatFits(in: .horizontal) {
                chipLabel(label)
                CategoryCompactPill(categoryId: categoryId, label: label)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Category, \(label)")
        .accessibilityHint("Opens category picker")
    }

    private func chipLabel(_ text: String) -> some View {
        HStack(spacing: 4) {
            Text(text)
                .fixedSize(horizontal: true, vertical: false)
            Image(systemName: "chevron.down")
                .font(.system(size: 8, weight: .bold))
                .opacity(0.65)
        }
        .font(AppTypography.badge)
        .tracking(0.2)
        .foregroundStyle(accent)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(accent.opacity(0.14))
        .clipShape(Capsule())
    }
}

// MARK: - Store chip

private struct StoreChipMenu: View {
    let storeId: String?
    let stores: [StoreService.StoreInfo]
    let onSelect: (String?) -> Void

    private var label: String {
        guard let storeId, !storeId.isEmpty else { return "Unassigned" }
        return SeedData.storeLabel(for: storeId)
    }

    private var hasAssignedStore: Bool {
        guard let storeId, !storeId.isEmpty else { return false }
        return label != "Unassigned"
    }

    var body: some View {
        Menu {
            Button {
                HapticsService.selection()
                onSelect(nil)
            } label: {
                HStack {
                    Text("Unassigned")
                    if !hasAssignedStore {
                        Spacer()
                        Image(systemName: "checkmark")
                    }
                }
            }
            ForEach(stores) { store in
                Button {
                    HapticsService.selection()
                    onSelect(store.id)
                } label: {
                    HStack {
                        Text(store.label)
                        if store.id == storeId {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                StoreLogoView(storeId: hasAssignedStore ? storeId : nil, size: 18, cornerRadius: 4)
                Text(label)
                    .fixedSize(horizontal: true, vertical: false)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .opacity(0.65)
            }
            .font(AppTypography.badge)
            .tracking(0.2)
            .foregroundStyle(AppColors.inkSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppColors.filterUnselected.opacity(0.55))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Store, \(label)")
        .accessibilityHint("Opens store picker")
    }
}
