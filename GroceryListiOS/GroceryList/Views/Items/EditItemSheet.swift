import SwiftUI
import SwiftData

struct EditItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var draft: ItemEditDraft
    @State private var showCategoryPicker = false
    @State private var showStorePicker = false
    @State private var showListPicker = false
    @State private var showDeleteAlert = false

    let item: GroceryItem
    let lists: [GroceryList]
    let onSave: (ItemEditDraft) -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    init(
        item: GroceryItem,
        lists: [GroceryList] = [],
        onSave: @escaping (ItemEditDraft) -> Void,
        onDuplicate: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.item = item
        self.lists = lists
        _draft = State(initialValue: ItemEditDraft(item: item))
        self.onSave = onSave
        self.onDuplicate = onDuplicate
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        itemPreview

                        SettingsCard(title: "Item") {
                            nameRow
                            EditSheetDivider()
                            quantitySection
                        }

                        SettingsCard(title: "Organization") {
                            pickerRow(
                                title: "Category",
                                value: SeedData.categoryLabel(for: draft.categoryId)
                            ) {
                                showCategoryPicker = true
                            }
                            EditSheetDivider()
                            pickerRow(title: "Store", value: storeDisplayLabel) {
                                showStorePicker = true
                            }
                            if lists.count > 1 {
                                EditSheetDivider()
                                pickerRow(title: "List", value: selectedListName) {
                                    showListPicker = true
                                }
                            }
                        }

                        SettingsCard(title: "Details") {
                            notesRow
                        }

                        SettingsCard(title: "Actions") {
                            Button(action: duplicateItem) {
                                actionRow(title: "Duplicate Item", systemImage: "plus.square.on.square")
                            }
                            .buttonStyle(.plain)
                        }

                        SettingsCard(title: "Danger") {
                            Button(role: .destructive) {
                                showDeleteAlert = true
                            } label: {
                                actionRow(
                                    title: "Delete Item",
                                    systemImage: "trash",
                                    isDestructive: true
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .adaptiveScreenContent()
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(draft)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(trimmedName.isEmpty)
                }
            }
            .onChange(of: draft.name) { _, newValue in
                applyDetectedCategory(for: newValue)
            }
            .fullScreenCover(isPresented: $showCategoryPicker) {
                CategoryPickerSheet(
                    selectedCategoryId: Binding(
                        get: { draft.categoryId },
                        set: { newValue in
                            draft.categoryId = newValue
                            draft.categoryManuallySelected = true
                        }
                    ),
                    itemName: draft.name
                )
            }
            .fullScreenCover(isPresented: $showStorePicker) {
                StorePickerSheet(
                    selectedStoreId: $draft.storeId,
                    itemName: draft.name
                )
            }
            .confirmationDialog("Move to list", isPresented: $showListPicker, titleVisibility: .visible) {
                ForEach(lists) { list in
                    Button(list.name) {
                        draft.listId = list.id
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Delete \(draft.name)?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    onDelete()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This item will be removed from \(selectedListName).")
            }
        }
    }

    private var trimmedName: String {
        draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var selectedListName: String {
        if let listId = draft.listId, let list = lists.first(where: { $0.id == listId }) {
            return list.name
        }
        return item.list?.name ?? "this list"
    }

    private var storeDisplayLabel: String {
        let label = StoreService.label(for: draft.storeId, context: modelContext)
        return label == "Unassigned" ? "No store" : label
    }

    private var previewMetadata: String {
        let category = SeedData.categoryLabel(for: draft.categoryId)
        if storeDisplayLabel != "No store" {
            return "\(category) · \(storeDisplayLabel)"
        }
        return category
    }

    private var showsThumbnail: Bool {
        ItemAssetResolver.bundledAssetName(
            itemName: draft.name,
            categoryId: draft.categoryId,
            storedAssetName: item.imageAssetName
        ) != nil
    }

    private var itemPreview: some View {
        HStack(alignment: .center, spacing: 14) {
            if showsThumbnail {
                ItemThumbnailView(item: item, size: 52)
            } else {
                CategoryIconView(
                    categoryId: draft.categoryId,
                    containerSize: 52,
                    cornerRadius: 14
                )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(trimmedName.isEmpty ? "Item" : draft.name)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColors.ink)
                    .lineLimit(2)

                Text(previewMetadata)
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.inkSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
    }

    private var nameRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Name")
                .font(AppTypography.metadata.weight(.semibold))
                .foregroundStyle(AppColors.inkSecondary)
            TextField("Item name", text: $draft.name)
                .font(AppTypography.itemTitle)
                .textInputAutocapitalization(.sentences)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var quantitySection: some View {
        if draft.hasTextQuantity {
            VStack(alignment: .leading, spacing: 6) {
                Text("Quantity")
                    .font(AppTypography.metadata.weight(.semibold))
                    .foregroundStyle(AppColors.inkSecondary)
                TextField("Quantity (e.g. 2 lb)", text: Binding(
                    get: { draft.quantityText ?? "" },
                    set: { draft.quantityText = $0.isEmpty ? nil : $0 }
                ))
                .font(AppTypography.itemTitle)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        } else {
            HStack {
                Text("Quantity")
                    .font(AppTypography.itemTitle)
                    .foregroundStyle(AppColors.ink)
                Spacer()
                QuantityStepper(
                    value: draft.quantityValue,
                    onDecrement: {
                        if draft.quantityValue > 1 {
                            draft.quantityValue -= 1
                            HapticsService.stepper()
                        }
                    },
                    onIncrement: {
                        if draft.quantityValue < 99 {
                            draft.quantityValue += 1
                            HapticsService.stepper()
                        }
                    }
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var notesRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Notes")
                .font(AppTypography.metadata.weight(.semibold))
                .foregroundStyle(AppColors.inkSecondary)
            TextField("Optional notes", text: $draft.notes, axis: .vertical)
                .font(AppTypography.itemTitle)
                .lineLimit(3...6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func pickerRow(title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(AppTypography.itemTitle)
                    .foregroundStyle(AppColors.ink)
                Spacer()
                Text(value)
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.inkSecondary)
                    .lineLimit(1)
                Image(systemName: AppIcons.chevron)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.inkSecondary.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private func actionRow(
        title: String,
        systemImage: String,
        isDestructive: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .medium))
                .frame(width: 22)
                .foregroundStyle(isDestructive ? AppColors.accentDestructive : AppColors.accentPrimary)
            Text(title)
                .font(AppTypography.itemTitle)
                .foregroundStyle(isDestructive ? AppColors.accentDestructive : AppColors.ink)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func duplicateItem() {
        onDuplicate()
        dismiss()
    }

    private func applyDetectedCategory(for rawName: String) {
        guard !draft.categoryManuallySelected else { return }

        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let rules = CategoryLearningService.fetchRules(context: modelContext)
        let detected = CategoryDetectionService.detectCategory(
            for: trimmed,
            learningRules: rules
        )
        if detected != "misc" || draft.categoryId == "misc" {
            draft.categoryId = detected
        }
    }
}

private struct EditSheetDivider: View {
    var body: some View {
        Divider()
            .overlay(AppColors.cardBorder)
            .padding(.leading, 16)
    }
}
