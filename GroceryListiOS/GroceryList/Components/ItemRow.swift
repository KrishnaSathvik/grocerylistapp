import SwiftUI
import SwiftData

struct ItemRow: View {
    let item: GroceryItem
    var metadataMode: ItemRowMetadataMode = .full
    var categories: [CategoryService.CategoryInfo] = []
    var stores: [StoreService.StoreInfo] = []
    var isCompleted: Bool = false
    var isSelectionMode: Bool = false
    var isSelected: Bool = false
    var onToggle: () -> Void
    var onIncrement: () -> Void
    var onDecrement: () -> Void
    var onShowActions: () -> Void
    var onSelectCategory: (String) -> Void = { _ in }
    var onSelectStore: (String?) -> Void = { _ in }

    private let thumbnailSize: CGFloat = 38
    private let checkboxTouchSize: CGFloat = 32
    private let checkboxVisualSize: CGFloat = 22

    private var displayQuantity: Int {
        max(item.quantityValue ?? 1, 1)
    }

    private var showsStepper: Bool {
        item.quantityText == nil || item.quantityText?.isEmpty == true
    }

    private var showsThumbnail: Bool {
        ItemAssetResolver.bundledAssetName(
            itemName: item.name,
            categoryId: item.categoryId,
            storedAssetName: item.imageAssetName
        ) != nil
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .stroke(toggleColor, lineWidth: 1.5)
                        .frame(width: checkboxVisualSize, height: checkboxVisualSize)
                    if isCompleted || (isSelectionMode && isSelected) {
                        Image(systemName: toggleIcon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(toggleColor)
                    }
                }
                .frame(width: checkboxTouchSize, height: checkboxTouchSize)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHidden(true)

            if showsThumbnail {
                ItemThumbnailView(item: item, size: thumbnailSize)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(AppTypography.itemTitle)
                    .foregroundStyle(AppColors.ink)
                    .strikethrough(isCompleted)
                    .lineLimit(2)
                    .minimumScaleFactor(0.92)

                if metadataMode.showsCategory || metadataMode.showsStore {
                    ItemMetadataChips(
                        item: item,
                        mode: metadataMode,
                        categories: categories,
                        stores: stores,
                        onSelectCategory: onSelectCategory,
                        onSelectStore: onSelectStore
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            trailingControls
        }
        .frame(minHeight: AppSpacing.rowMinHeight)
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(AppColors.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColors.cardBorder.opacity(0.55), lineWidth: 0.5)
        )
        .shadow(color: AppColors.cardShadow.opacity(0.45), radius: 6, y: 2)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityText)
        .accessibilityValue(isCompleted ? "completed" : "not completed")
        .accessibilityAction(named: toggleAccessibilityLabel, onToggle)
    }

    @ViewBuilder
    private var trailingControls: some View {
        HStack(spacing: 4) {
            if showsStepper {
                QuantityStepper(
                    value: displayQuantity,
                    onDecrement: onDecrement,
                    onIncrement: onIncrement
                )
                .fixedSize()
            }

            if !isSelectionMode {
                Button(action: onShowActions) {
                    Image(systemName: AppIcons.editItem)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppColors.inkSecondary.opacity(0.75))
                        .frame(width: 34, height: 34)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit \(item.name)")
                .accessibilityHint("Opens item details")
            }
        }
    }

    private var accessibilityMetadata: String {
        var parts: [String] = []
        if metadataMode.showsCategory {
            parts.append(CategoryService.label(for: item.categoryId))
        }
        if metadataMode.showsStore {
            if let storeId = item.storeId, !storeId.isEmpty {
                let storeLabel = SeedData.storeLabel(for: storeId)
                if storeLabel != "Unassigned" {
                    parts.append(storeLabel)
                }
            } else if metadataMode == .storeOnly {
                parts.append("Unassigned")
            }
        }
        return parts.joined(separator: ", ")
    }

    private var toggleIcon: String {
        if isSelectionMode {
            return isSelected ? AppIcons.checkmarkFilled : AppIcons.circle
        }
        return isCompleted ? AppIcons.checkmarkFilled : AppIcons.circle
    }

    private var toggleColor: Color {
        if isSelectionMode && isSelected {
            return AppColors.accentLink
        }
        return isCompleted ? AppColors.accentSuccess : AppColors.inkSecondary.opacity(0.65)
    }

    private var toggleAccessibilityLabel: String {
        if isSelectionMode {
            return isSelected ? "Deselect item" : "Select item"
        }
        return isCompleted ? "Uncheck item" : "Check item"
    }

    private var accessibilityText: String {
        var parts = [item.name]
        if displayQuantity > 1 {
            parts.append("quantity \(displayQuantity)")
        }
        if let quantityText = item.quantityText {
            parts.append(quantityText)
        }
        let metadata = accessibilityMetadata
        if !metadata.isEmpty {
            parts.append(metadata)
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Read-only grouped row (Store / Categories tabs)

enum GroupedItemMetadataMode {
    case category
    case store

    func line(for item: GroceryItem, modelContext: ModelContext) -> String? {
        switch self {
        case .category:
            return CategoryService.label(for: item.categoryId)
        case .store:
            if let storeId = item.storeId, !storeId.isEmpty {
                let label = StoreService.label(for: storeId, context: modelContext)
                if label != "Unassigned" { return label }
            }
            return "No store"
        }
    }
}

enum GroupedItemRowStyle {
    case nested
    case standalone
}

struct GroupedItemRow: View {
    @Environment(\.modelContext) private var modelContext

    let item: GroceryItem
    var metadataMode: GroupedItemMetadataMode = .category
    var style: GroupedItemRowStyle = .nested

    private var thumbnailSize: CGFloat {
        style == .nested ? 26 : 38
    }

    private var showsThumbnail: Bool {
        style != .nested
            ? ItemAssetResolver.bundledAssetName(
                itemName: item.name,
                categoryId: item.categoryId,
                storedAssetName: item.imageAssetName
            ) != nil
            : false
    }

    private var metadataLine: String? {
        metadataMode.line(for: item, modelContext: modelContext)
    }

    private var quantityLabel: String? {
        if let text = item.quantityText, !text.isEmpty {
            return text
        }
        let value = max(item.quantityValue ?? 1, 1)
        return value > 1 ? "×\(value)" : nil
    }

    var body: some View {
        HStack(alignment: .center, spacing: style == .nested ? 10 : 12) {
            if showsThumbnail {
                ItemThumbnailView(item: item, size: thumbnailSize)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(style == .nested ? AppTypography.bodyMedium : AppTypography.itemTitle)
                    .foregroundStyle(AppColors.ink)
                    .lineLimit(2)

                if let metadataLine {
                    Text(metadataLine)
                        .font(AppTypography.metadata)
                        .foregroundStyle(AppColors.inkSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let quantityLabel {
                Text(quantityLabel)
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.inkSecondary.opacity(0.85))
            }
        }
        .frame(minHeight: style == .nested ? 44 : AppSpacing.rowMinHeight, alignment: .center)
        .padding(.horizontal, style == .nested ? 0 : 14)
        .padding(.vertical, style == .nested ? 8 : 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts = [item.name]
        if let metadataLine {
            parts.append(metadataLine)
        }
        if let quantityLabel {
            parts.append(quantityLabel)
        }
        return parts.joined(separator: ", ")
    }
}
