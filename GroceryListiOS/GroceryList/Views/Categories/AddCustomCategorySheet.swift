import SwiftUI

struct AddCustomCategorySheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var categoryName = ""
    @State private var selectedSymbol = CustomCategoryIconOptions.symbols[0].name
    @State private var selectedColor = "#E8F5E9"
    @FocusState private var isFocused: Bool

    private let colorOptions = ["#E8F5E9", "#E8F4FD", "#FDE8E8", "#FFF3E0", "#FFF8E1", "#E8EAF6", "#FCE4EC", "#E0F2F1"]

    private var trimmed: String {
        categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    previewCard

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category name")
                            .font(AppTypography.metadata.weight(.semibold))
                            .foregroundStyle(AppColors.inkSecondary)
                        TextField("e.g. Asian Pantry", text: $categoryName)
                            .font(AppTypography.itemTitle)
                            .focused($isFocused)
                            .padding(14)
                            .background(AppColors.backgroundPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(AppColors.cardBorder, lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Icon")
                            .font(AppTypography.metadata.weight(.semibold))
                            .foregroundStyle(AppColors.inkSecondary)
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4),
                            spacing: 10
                        ) {
                            ForEach(CustomCategoryIconOptions.symbols, id: \.name) { option in
                                CategoryIconPickerButton(
                                    option: .system(option.name),
                                    isSelected: selectedSymbol == option.name,
                                    accessibilityLabel: option.label
                                ) {
                                    selectedSymbol = option.name
                                    HapticsService.selection()
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Color")
                            .font(AppTypography.metadata.weight(.semibold))
                            .foregroundStyle(AppColors.inkSecondary)
                        HStack(spacing: 10) {
                            ForEach(colorOptions, id: \.self) { hex in
                                Button {
                                    selectedColor = hex
                                    HapticsService.selection()
                                } label: {
                                    Circle()
                                        .fill(AppColors.colorHex(hex))
                                        .frame(width: 30, height: 30)
                                        .overlay {
                                            if selectedColor == hex {
                                                Circle()
                                                    .stroke(AppColors.accentPrimary, lineWidth: 2.5)
                                                    .padding(-3)
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Text("Custom categories appear in your Categories tab and can be assigned to items.")
                        .font(AppTypography.metadata)
                        .foregroundStyle(AppColors.inkSecondary)

                    Button("Add Category", action: addCategory)
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(trimmed.isEmpty)
                        .opacity(trimmed.isEmpty ? 0.55 : 1)
                }
                .padding(AppSpacing.screenHorizontal)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(AppColors.backgroundGrouped)
            .navigationTitle("Add Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { addCategory() }
                        .fontWeight(.semibold)
                        .disabled(trimmed.isEmpty)
                }
            }
            .onAppear { isFocused = true }
        }
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Preview")
                .font(AppTypography.metadata.weight(.semibold))
                .foregroundStyle(AppColors.inkSecondary)

            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppColors.colorHex(selectedColor).opacity(0.22))
                        .frame(width: 44, height: 44)
                    Image(systemName: selectedSymbol)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppColors.colorHex(selectedColor))
                }
                Text(trimmed.isEmpty ? "Category name" : trimmed)
                    .font(AppTypography.itemTitle)
                    .foregroundStyle(AppColors.ink)
                Spacer(minLength: 0)
            }
            .padding(14)
            .background(AppColors.backgroundPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(AppColors.cardBorder, lineWidth: 1)
            )
        }
    }

    private func addCategory() {
        guard CategoryService.addCustomCategory(label: trimmed, emoji: selectedSymbol, color: selectedColor) != nil else { return }
        HapticsService.add()
        dismiss()
    }
}
