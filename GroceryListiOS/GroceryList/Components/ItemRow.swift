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
    var showsEditButton: Bool = true
    var onToggle: () -> Void
    var onIncrement: () -> Void
    var onDecrement: () -> Void
    var onShowActions: () -> Void
    var onSelectCategory: (String) -> Void = { _ in }
    var onSelectStore: (String?) -> Void = { _ in }

    private let thumbnailSize: CGFloat = 38
    private let checkboxTouchSize: CGFloat = AppSpacing.minTapTarget
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

    private var rowBackground: Color {
        isCompleted ? AppColors.completedRowBackground : AppColors.backgroundPrimary
    }

    private var titleColor: Color {
        isCompleted ? AppColors.completedInk : AppColors.ink
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Button(action: onToggle) {
                completionToggle
                    .frame(width: checkboxTouchSize, height: checkboxTouchSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHidden(true)

            if showsThumbnail {
                ItemThumbnailView(item: item, size: thumbnailSize)
                    .opacity(isCompleted ? 0.72 : 1)
                    .saturation(isCompleted ? 0.35 : 1)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(AppTypography.itemTitle)
                    .foregroundStyle(titleColor)
                    .strikethrough(isCompleted, color: titleColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.92)

                if metadataMode.showsCategory || metadataMode.showsStore {
                    ItemMetadataChips(
                        item: item,
                        mode: metadataMode,
                        categories: categories,
                        stores: stores,
                        isMuted: isCompleted,
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
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColors.cardBorder.opacity(isCompleted ? 0.35 : 0.55), lineWidth: 0.5)
        )
        .shadow(color: AppColors.cardShadow.opacity(isCompleted ? 0.18 : 0.45), radius: isCompleted ? 3 : 6, y: isCompleted ? 1 : 2)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityText)
        .accessibilityValue(isCompleted ? "completed" : "not completed")
        .accessibilityAction(named: toggleAccessibilityLabel, onToggle)
    }

    @ViewBuilder
    private var completionToggle: some View {
        ZStack {
            if isCompleted {
                Circle()
                    .fill(AppColors.accentSuccess)
                    .frame(width: checkboxVisualSize, height: checkboxVisualSize)
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            } else if isSelectionMode && isSelected {
                Circle()
                    .fill(AppColors.accentLink)
                    .frame(width: checkboxVisualSize, height: checkboxVisualSize)
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                Circle()
                    .stroke(AppColors.inkSecondary.opacity(0.65), lineWidth: 1.5)
                    .frame(width: checkboxVisualSize, height: checkboxVisualSize)
            }
        }
    }

    @ViewBuilder
    private var trailingControls: some View {
        HStack(spacing: 4) {
            if showsStepper {
                QuantityStepper(
                    value: displayQuantity,
                    isMuted: isCompleted,
                    onDecrement: onDecrement,
                    onIncrement: onIncrement
                )
                .fixedSize()
            }

            if !isSelectionMode, showsEditButton {
                Button(action: onShowActions) {
                    Image(systemName: AppIcons.editItem)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(
                            isCompleted
                                ? AppColors.completedInk.opacity(0.75)
                                : AppColors.inkSecondary.opacity(0.75)
                        )
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .frame(width: AppSpacing.minTapTarget, height: AppSpacing.minTapTarget)
                .contentShape(Rectangle())
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
        return "\(value)"
    }

    private var detailLine: String? {
        let parts = [quantityLabel, metadataLine].compactMap { $0 }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: " · ")
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

                if let detailLine {
                    Text(detailLine)
                        .font(AppTypography.metadata)
                        .foregroundStyle(AppColors.inkSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: style == .nested ? 44 : AppSpacing.rowMinHeight, alignment: .center)
        .padding(.horizontal, style == .nested ? 0 : 14)
        .padding(.vertical, style == .nested ? 8 : 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts = [item.name]
        if let quantityLabel {
            parts.append("Quantity \(quantityLabel)")
        }
        if let metadataLine {
            parts.append(metadataLine)
        }
        return parts.joined(separator: ", ")
    }
}
