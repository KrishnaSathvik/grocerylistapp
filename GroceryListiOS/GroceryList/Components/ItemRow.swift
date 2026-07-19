import SwiftUI
import SwiftData

struct ItemRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let item: GroceryItem
    var metadataMode: ItemRowMetadataMode = .full
    var categories: [CategoryService.CategoryInfo] = []
    var stores: [StoreService.StoreInfo] = []
    var isCompleted: Bool = false
    var isSelectionMode: Bool = false
    var isSelected: Bool = false
    var showsEditButton: Bool = true
    /// DEBUG review harness: force thumbnail omission even when a bundled asset exists.
    var forceHideThumbnail: Bool = false
    var onToggle: () -> Void
    var onIncrement: () -> Void
    var onDecrement: () -> Void
    var onShowActions: () -> Void
    var onSelectCategory: (String) -> Void = { _ in }
    var onSelectStore: (String?) -> Void = { _ in }

    #if DEBUG
    @Environment(\.itemRowShowCandidateBadge) private var showCandidateBadge
    @Environment(\.itemRowForceMirror) private var forceMirror
    @State private var debugCandidateCode: String = "?"
    #endif

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
        if forceHideThumbnail { return false }
        return ItemAssetResolver.bundledAssetName(
            itemName: item.name,
            categoryId: item.categoryId,
            storedAssetName: item.imageAssetName
        ) != nil
    }

    /// Manual x-flip is only for DEBUG LTR harnesses that set `itemRowForceMirror`.
    /// Real RTL uses leading-origin Layout coordinates — do not double-flip.
    private var shouldMirrorLayout: Bool {
        #if DEBUG
        forceMirror == true
        #else
        false
        #endif
    }

    private var rowBackground: Color {
        isCompleted ? AppColors.completedRowBackground : AppColors.backgroundPrimary
    }

    private var titleColor: Color {
        isCompleted ? AppColors.completedInk : AppColors.ink
    }

    var body: some View {
        AdaptiveItemRowLayout(
            spacing: 10,
            mirrorsHorizontally: shouldMirrorLayout
        ) {
            completionButton
                .itemRowLayoutRole(.checkbox)

            if showsThumbnail {
                thumbnail
                    .itemRowLayoutRole(.thumbnail)
            }

            itemTitle
                .itemRowLayoutRole(.title)

            if metadataMode.showsCategory || metadataMode.showsStore {
                metadataChips
                    .itemRowLayoutRole(.metadata)
            }

            if showsStepper {
                QuantityStepper(
                    value: displayQuantity,
                    isMuted: isCompleted,
                    onDecrement: onDecrement,
                    onIncrement: onIncrement
                )
                .fixedSize()
                .itemRowLayoutRole(.stepper)
            }

            if !isSelectionMode, showsEditButton {
                editButton
                    .itemRowLayoutRole(.edit)
            }
        }
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
        #if DEBUG
        .background {
            GeometryReader { proxy in
                let contentWidth = max(0, proxy.size.width - 28)
                Color.clear
                    .preference(
                        key: ItemRowDebugLayoutSizeKey.self,
                        value: contentWidth
                    )
                    .onAppear { updateDebugCandidate(proposedWidth: contentWidth) }
                    .onChange(of: contentWidth) { _, width in
                        updateDebugCandidate(proposedWidth: width)
                    }
            }
        }
        .onPreferenceChange(ItemRowDebugLayoutSizeKey.self) { width in
            updateDebugCandidate(proposedWidth: width)
        }
        .accessibilityIdentifier("item-row-candidate-\(debugCandidateCode)")
        .overlay(alignment: .topTrailing) {
            if showCandidateBadge {
                Text(debugCandidateCode)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(AppColors.accentLink.opacity(0.85)))
                    .padding(6)
                    .accessibilityIdentifier("item-row-candidate-badge-\(debugCandidateCode)")
                    .accessibilityLabel("Candidate \(debugCandidateCode)")
            }
        }
        #endif
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityText)
        .accessibilityValue(isCompleted ? "completed" : "not completed")
        .accessibilityAction(named: toggleAccessibilityLabel, onToggle)
    }

    private var completionButton: some View {
        Button(action: onToggle) {
            completionToggle
                .frame(width: checkboxTouchSize, height: checkboxTouchSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHidden(true)
    }

    private var thumbnail: some View {
        ItemThumbnailView(item: item, size: thumbnailSize)
            .opacity(isCompleted ? 0.72 : 1)
            .saturation(isCompleted ? 0.35 : 1)
    }

    private var itemTitle: some View {
        EssentialWordWrappingText(
            text: item.name,
            color: titleColor,
            isStrikethrough: isCompleted
        )
    }

    @ViewBuilder
    private var metadataChips: some View {
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

    private var editButton: some View {
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

    #if DEBUG
    private func updateDebugCandidate(proposedWidth: CGFloat) {
        guard proposedWidth > 1 else { return }
        let titleIdeal = (item.name as NSString)
            .size(withAttributes: [.font: AppTypography.itemTitleUIFont()])
            .width
        let inlineRequired = ItemRowFitGeometry.inlineRequiredWidth(
            hasThumbnail: showsThumbnail,
            hasEdit: !isSelectionMode && showsEditButton,
            hasStepper: showsStepper,
            titleIdealWidth: titleIdeal
        )
        let protected = ItemRowFitGeometry.protectedTitleWidth(oneLineIdealWidth: titleIdeal)
        let splitRequired = ItemRowFitGeometry.splitRequiredWidth(
            checkboxWidth: ItemRowFitGeometry.Chrome.checkboxWidth,
            thumbnailWidth: showsThumbnail ? ItemRowFitGeometry.Chrome.thumbnailWidth : 0,
            protectedTitleWidth: protected,
            editWidth: (!isSelectionMode && showsEditButton)
                ? ItemRowFitGeometry.Chrome.editWidth : 0,
            spacing: ItemRowFitGeometry.Chrome.spacing
        )
        let selected = ItemRowFitGeometry.selectCandidate(
            proposedWidth: proposedWidth,
            inlineRequiredWidth: inlineRequired,
            splitRequiredWidth: splitRequired
        )
        debugCandidateCode = selected.debugCode
        ItemRowCandidateDebug.lastSelected = selected
    }
    #endif
}

#if DEBUG
private struct ItemRowDebugLayoutSizeKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct ItemRowShowCandidateBadgeKey: EnvironmentKey {
    static let defaultValue = false
}

private struct ItemRowForceMirrorKey: EnvironmentKey {
    static let defaultValue: Bool? = nil
}

extension EnvironmentValues {
    var itemRowShowCandidateBadge: Bool {
        get { self[ItemRowShowCandidateBadgeKey.self] }
        set { self[ItemRowShowCandidateBadgeKey.self] = newValue }
    }

    /// When non-nil, overrides `layoutDirection` for AdaptiveItemRowLayout mirroring (DEBUG harness).
    var itemRowForceMirror: Bool? {
        get { self[ItemRowForceMirrorKey.self] }
        set { self[ItemRowForceMirrorKey.self] = newValue }
    }
}
#endif

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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
                Text(EssentialText.attributed(item.name))
                    .font(style == .nested ? AppTypography.bodyMedium : AppTypography.itemTitle)
                    .foregroundStyle(AppColors.ink)
                    .essentialTextLayout(dynamicTypeSize: dynamicTypeSize, regularLineLimit: 2)

                if let detailLine {
                    Text(detailLine)
                        .font(AppTypography.metadata)
                        .foregroundStyle(AppColors.inkSecondary)
                        .lineLimit(DynamicTypeLayout.metadataLineLimit(for: dynamicTypeSize))
                        .fixedSize(horizontal: false, vertical: true)
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

#if DEBUG
#Preview("ItemRow · Large · Acceptance") {
    ItemRowPreviewHost(dynamicTypeSize: .large, variant: .standard)
}

#Preview("ItemRow · Accessibility Large") {
    ItemRowPreviewHost(dynamicTypeSize: .accessibility1, variant: .standard)
}

#Preview("ItemRow · Accessibility XXXL") {
    ItemRowPreviewHost(dynamicTypeSize: .accessibility5, variant: .standard)
}

#Preview("ItemRow · Selection · No Edit") {
    ItemRowPreviewHost(dynamicTypeSize: .large, variant: .selectionMode)
}

#Preview("ItemRow · No Thumbnail Names") {
    ItemRowPreviewHost(dynamicTypeSize: .large, variant: .forceNoThumbnail)
}

#Preview("ItemRow · Optional States") {
    ItemRowPreviewHost(dynamicTypeSize: .large, variant: .optionalStates)
}

#Preview("ItemRow · RTL · Large") {
    ItemRowPreviewHost(dynamicTypeSize: .large, variant: .standard)
        .environment(\.layoutDirection, .rightToLeft)
}

private enum ItemRowPreviewVariant {
    case standard
    case selectionMode
    case forceNoThumbnail
    case optionalStates
}

private struct ItemRowPreviewHost: View {
    let dynamicTypeSize: DynamicTypeSize
    var variant: ItemRowPreviewVariant = .standard

    private var previewNames: [String] {
        switch variant {
        case .standard, .selectionMode:
            return [
                "Orange",
                "Grapes",
                "Cabbage",
                "Broccoli",
                "Cucumber",
                "Zucchini",
                "Eggplant",
                "Mushrooms",
                "Strawberries",
                "Watermelon",
                "Chicken drumsticks",
                "Extra virgin olive oil",
            ]
        case .forceNoThumbnail:
            return [
                "Custom pantry staple xyz",
                "House blend mystery spice",
                "Unmapped long grocery name for layout",
            ]
        case .optionalStates:
            return []
        }
    }

    var body: some View {
        Group {
            if variant == .optionalStates {
                Stage1ItemRowReviewHarness(scene: .optionalStates)
            } else {
                standardPreviewList
            }
        }
        .environment(\.dynamicTypeSize, dynamicTypeSize)
        .background(AppColors.backgroundGrouped)
    }

    private var standardPreviewList: some View {
        let list = GroceryList(name: "Preview")
        let items = previewNames.enumerated().map { index, name in
            GroceryItem(name: name, categoryId: "produce", sortOrder: index, list: list)
        }

        return ScrollView {
            VStack(spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    ItemRow(
                        item: item,
                        isSelectionMode: variant == .selectionMode,
                        isSelected: variant == .selectionMode && index == 0,
                        showsEditButton: variant != .selectionMode,
                        forceHideThumbnail: variant == .forceNoThumbnail,
                        onToggle: {},
                        onIncrement: {},
                        onDecrement: {},
                        onShowActions: {}
                    )
                }
            }
            .padding()
        }
    }
}
#endif
