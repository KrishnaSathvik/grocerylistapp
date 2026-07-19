import SwiftUI
import SwiftData

// MARK: - Mode

enum FocusedShoppingGrouping {
    case byCategory
    case byStore
}

enum FocusedShoppingMode: Equatable {
    case store(storeId: String, label: String)
    case category(categoryId: String, label: String)

    var title: String {
        switch self {
        case .store(_, let label), .category(_, let label): return label
        }
    }

    var grouping: FocusedShoppingGrouping {
        switch self {
        case .store: return .byCategory
        case .category: return .byStore
        }
    }

    var groupingSubtitle: String {
        switch grouping {
        case .byCategory: return "Grouped by category"
        case .byStore: return "Grouped by store"
        }
    }

    var prefilledStoreId: String? {
        switch self {
        case .store(let storeId, _): return storeId
        case .category: return nil
        }
    }

    var prefilledCategoryId: String? {
        switch self {
        case .store: return nil
        case .category(let categoryId, _): return categoryId
        }
    }

    var addPlaceholder: String {
        switch self {
        case .store(_, let label): return "Add item to \(label)…"
        case .category(_, let label): return "Add item to \(label)…"
        }
    }

    var emptyTitle: String {
        switch self {
        case .store(_, let label): return "No \(label) items yet"
        case .category(_, let label): return "No \(label) items yet"
        }
    }

    var emptyMessage: String {
        switch self {
        case .store(_, let label):
            return "Add an item here and it will be saved under \(label) automatically."
        case .category:
            return "Add an item here and it will be saved under this category automatically."
        }
    }
}

// MARK: - Main view

struct FocusedShoppingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Bindable var list: GroceryList
    let mode: FocusedShoppingMode

    @State private var viewModel = FocusedShoppingViewModel()
    @FocusState private var isQuickAddFocused: Bool

    private var scopedItems: [GroceryItem] {
        list.items.filter { item in
            guard !item.isArchived else { return false }
            switch mode {
            case .store(let storeId, _):
                if storeId == "__unassigned__" {
                    return item.storeId == nil || item.storeId?.isEmpty == true
                }
                return item.storeId == storeId
            case .category(let categoryId, _):
                return item.categoryId == categoryId
            }
        }
    }

    private var activeItems: [GroceryItem] {
        scopedItems.filter { !$0.isCompleted }.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var completedItems: [GroceryItem] {
        scopedItems.filter { $0.isCompleted }.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var remainingCount: Int { activeItems.count }
    private var pickedUpCount: Int { completedItems.count }

    private var shoppingProgress: Double {
        let total = remainingCount + pickedUpCount
        guard total > 0 else { return 0 }
        return Double(pickedUpCount) / Double(total)
    }

    private var rowMetadataMode: ItemRowMetadataMode {
        switch mode.grouping {
        case .byCategory: return .hidden
        case .byStore: return .storeLabel
        }
    }

    private var actions: ListItemRowActions {
        ListItemRowActions.focused(from: viewModel, list: list, context: modelContext)
    }

    var body: some View {
        AdaptiveScreenShell {
            VStack(spacing: 0) {
                focusedHeader
                    .adaptiveHorizontalPadding()
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                VStack(alignment: .leading, spacing: 6) {
                    QuickAddBar(
                        text: $viewModel.draftText,
                        focus: $isQuickAddFocused,
                        placeholder: mode.addPlaceholder,
                        onSubmit: submitAdd
                    )

                    AddItemDetectionPreview(text: viewModel.draftText, modelContext: modelContext)
                        .padding(.leading, 4)
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: viewModel.draftText)
                }
                .adaptiveHorizontalPadding()
                .padding(.bottom, 12)

                if scopedItems.isEmpty {
                    focusedEmptyState
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        FocusedShoppingListContent(
                            mode: mode,
                            activeItems: activeItems,
                            completedItems: completedItems,
                            viewModel: viewModel,
                            rowMetadataMode: rowMetadataMode,
                            actions: actions,
                            modelContext: modelContext
                        )
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
        } bottomOverlay: {
            Group {
                if let message = viewModel.toastMessage, viewModel.undoSnapshot != nil {
                    UndoBanner(message: message) {
                        viewModel.undoDelete(in: list, context: modelContext)
                    }
                    .padding(.bottom, 16)
                    .transition(reduceMotion ? .identity : .move(edge: .bottom).combined(with: .opacity))
                } else if let message = viewModel.toastMessage {
                    ToastBanner(message: message)
                        .padding(.bottom, 16)
                }
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: viewModel.toastMessage)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            ActiveListResolver.setActive(list)
        }
    }

    private var focusedHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppColors.ink)
                        .frame(width: 44, height: 44, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")

                Spacer(minLength: 0)
            }

            HStack(alignment: .top, spacing: 14) {
                focusedIcon

                VStack(alignment: .leading, spacing: 6) {
                    Text(EssentialText.attributed(mode.title))
                        .font(
                            DynamicTypeLayout.usesCompactScreenTitle(dynamicTypeSize)
                                ? AppTypography.accessibilityScreenTitle
                                : AppTypography.screenTitle
                        )
                        .foregroundStyle(AppColors.ink)
                        .essentialTextLayout(dynamicTypeSize: dynamicTypeSize, regularLineLimit: 2)

                    Text(statusLine)
                        .font(AppTypography.metadata)
                        .foregroundStyle(AppColors.inkSecondary)
                        .lineLimit(DynamicTypeLayout.usesAccessibilityLayout(dynamicTypeSize) ? nil : 2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(mode.groupingSubtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.inkSecondary.opacity(0.85))
                        .lineLimit(DynamicTypeLayout.usesAccessibilityLayout(dynamicTypeSize) ? 3 : 1)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if remainingCount + pickedUpCount > 0 {
                ProgressView(value: shoppingProgress)
                    .tint(AppColors.accentSuccess)
            }
        }
    }

    @ViewBuilder
    private var focusedIcon: some View {
        switch mode {
        case .store(let storeId, let label):
            StoreLogoView(
                storeId: storeId == "__unassigned__" ? nil : storeId,
                displayLabel: label,
                size: 52,
                cornerRadius: 14
            )
        case .category(let categoryId, _):
            CategoryIconView(
                categoryId: categoryId,
                containerSize: 52,
                cornerRadius: 14
            )
        }
    }

    private var statusLine: String {
        if remainingCount + pickedUpCount == 0 {
            return "No items yet"
        }
        let remaining = "\(remainingCount) item\(remainingCount == 1 ? "" : "s") remaining"
        if pickedUpCount > 0 {
            return "\(remaining) · \(pickedUpCount) picked up"
        }
        return remaining
    }

    private var focusedEmptyState: some View {
        VStack(spacing: 20) {
            switch mode {
            case .store:
                Image(systemName: AppIcons.store)
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundStyle(AppColors.inkSecondary.opacity(0.45))
            case .category(let categoryId, _):
                CategoryIconView(categoryId: categoryId, containerSize: 72, cornerRadius: 18)
            }

            VStack(spacing: 8) {
                Text(mode.emptyTitle)
                    .font(AppTypography.emptyStateTitle)
                    .foregroundStyle(AppColors.ink)
                    .multilineTextAlignment(.center)

                Text(mode.emptyMessage)
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.inkSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 285)
            }

            Button(mode.addPlaceholder.replacingOccurrences(of: "…", with: "")) {
                isQuickAddFocused = true
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 32)
        }
        .adaptiveHorizontalPadding()
        .offset(y: -24)
    }

    private func submitAdd() {
        viewModel.addItem(
            to: list,
            context: modelContext,
            prefilledStoreId: mode.prefilledStoreId,
            prefilledCategoryId: mode.prefilledCategoryId
        )
    }
}

// MARK: - Grouped list content

struct FocusedShoppingListContent: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let mode: FocusedShoppingMode
    let activeItems: [GroceryItem]
    let completedItems: [GroceryItem]
    @Bindable var viewModel: FocusedShoppingViewModel
    let rowMetadataMode: ItemRowMetadataMode
    let actions: ListItemRowActions
    let modelContext: ModelContext

    var body: some View {
        if !activeItems.isEmpty {
            ForEach(groupedActiveSections) { section in
                Section {
                    ForEach(section.items) { item in
                        ConfigurableItemRow(
                            item: item,
                            metadataMode: rowMetadataMode,
                            showsEditButton: false,
                            actions: actions
                        )
                    }
                } header: {
                    if let title = section.title {
                        Text(title)
                            .appSectionLabel()
                    }
                }
            }
        }

        if !completedItems.isEmpty, viewModel.showCompletedItems {
            Section {
                if viewModel.isPickedUpExpanded {
                    ForEach(completedItems) { item in
                        ConfigurableItemRow(
                            item: item,
                            metadataMode: rowMetadataMode,
                            isCompleted: true,
                            showsEditButton: false,
                            actions: actions
                        )
                    }
                }
            } header: {
                Button {
                    if reduceMotion {
                        viewModel.isPickedUpExpanded.toggle()
                    } else {
                        withAnimation { viewModel.isPickedUpExpanded.toggle() }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("Picked up (\(completedItems.count))")
                            .appSectionLabel()
                        Image(systemName: viewModel.isPickedUpExpanded ? "chevron.up" : "chevron.down")
                            .font(AppTypography.caption.weight(.semibold))
                            .foregroundStyle(AppColors.inkSecondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private struct ShoppingSection: Identifiable {
        let id: String
        let title: String?
        let items: [GroceryItem]
    }

    private var groupedActiveSections: [ShoppingSection] {
        switch mode.grouping {
        case .byCategory:
            let groups = ListGroupingService.groupByCategory(items: activeItems, includeCompleted: false)
            if groups.count <= 1, groups.first?.id == activeItems.first?.categoryId {
                return [ShoppingSection(id: "all", title: nil, items: activeItems)]
            }
            return groups.map { ShoppingSection(id: $0.id, title: $0.label, items: $0.items) }

        case .byStore:
            let storeOrder = StoreService.allStores(context: modelContext).map(\.id)
            let groups = ListGroupingService.groupByStore(
                items: activeItems,
                includeCompleted: false,
                storeOrder: storeOrder
            )
            if groups.count <= 1 {
                return [ShoppingSection(id: "all", title: nil, items: activeItems)]
            }
            return groups.map { group in
                let title = group.id == "__unassigned__" ? "No store" : group.label
                return ShoppingSection(id: group.id, title: title, items: group.items)
            }
        }
    }
}

// MARK: - Navigation routes

struct StoreShoppingRoute: Hashable {
    let storeId: String
    let label: String
}

struct CategoryShoppingRoute: Hashable {
    let categoryId: String
    let label: String
}
