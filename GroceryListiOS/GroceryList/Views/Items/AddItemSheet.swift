import SwiftUI
import SwiftData

struct AddItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var list: GroceryList
    var initialText: String = ""

    @State private var inputText = ""
    @FocusState private var isFocused: Bool

    init(list: GroceryList, initialText: String = "") {
        self.list = list
        self.initialText = initialText
        _inputText = State(initialValue: initialText)
    }

    private var trimmed: String {
        inputText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var parsedItems: [ParsedItemInput] {
        let rules = CategoryLearningService.fetchRules(context: modelContext)
        let stores = StoreService.storeDefinitions(context: modelContext)
        return MultiItemInputParser.parse(trimmed, learningRules: rules, stores: stores)
    }

    private var hasValidParsedItems: Bool {
        parsedItems.contains { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 10) {
                        TextField("Add item...", text: $inputText)
                            .font(.system(size: 17, weight: .medium))
                            .focused($isFocused)
                            .submitLabel(.done)
                            .onSubmit(addIfValid)

                        if !inputText.isEmpty {
                            Button {
                                inputText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(AppColors.inkSecondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                    .frame(height: AppSpacing.addBarHeight)
                    .background(AppColors.addBarBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius, style: .continuous)
                            .stroke(AppColors.cardBorder, lineWidth: 1)
                    )

                    if isFocused && trimmed.isEmpty {
                        QuickAddHelperText()
                    }

                    if let preview = QuickAddPreviewFormatter.preview(for: parsedItems, modelContext: modelContext) {
                        VStack(alignment: .leading, spacing: 4) {
                            if let header = preview.header {
                                Text(header)
                                    .font(AppTypography.metadata)
                                    .foregroundStyle(AppColors.inkSecondary)
                            }
                            ForEach(Array(preview.lines.enumerated()), id: \.offset) { _, line in
                                Text(line)
                                    .font(AppTypography.metadata)
                                    .foregroundStyle(AppColors.inkSecondary)
                            }
                            if preview.moreCount > 0 {
                                Text("+\(preview.moreCount) more")
                                    .font(AppTypography.metadata)
                                    .foregroundStyle(AppColors.inkSecondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel(preview.accessibilityLabel)
                    }

                    Button("Add Item", action: addIfValid)
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(trimmed.isEmpty || !hasValidParsedItems)
                        .opacity(trimmed.isEmpty ? 0.5 : 1)
                }
                .padding(AppSpacing.screenHorizontal)
                .padding(.top, 8)
            }
            .background(AppColors.backgroundGrouped)
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { isFocused = true }
        }
        .presentationDetents([.medium, .large])
    }

    private func addIfValid() {
        guard !GroceryItemService.addItems(name: trimmed, to: list, context: modelContext).isEmpty else { return }
        HapticsService.add()
        dismiss()
    }
}
