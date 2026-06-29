import SwiftUI

struct AddCustomCategorySheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var categoryName = ""
    @State private var selectedSymbol = CustomCategoryIconOptions.symbols[0].name
    @State private var selectedColor = CategoryService.customCategoryColorOptions[0]
    @FocusState private var isFocused: Bool

    private var trimmed: String {
        categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var accentColor: Color {
        AppColors.colorHex(selectedColor)
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
                                customIconButton(for: option)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Accent color")
                            .font(AppTypography.metadata.weight(.semibold))
                            .foregroundStyle(AppColors.inkSecondary)
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6),
                            spacing: 12
                        ) {
                            ForEach(CategoryService.customCategoryColorOptions, id: \.self) { hex in
                                Button {
                                    selectedColor = hex
                                    HapticsService.selection()
                                } label: {
                                    Circle()
                                        .fill(AppColors.colorHex(hex))
                                        .frame(width: 34, height: 34)
                                        .overlay {
                                            if selectedColor == hex {
                                                Circle()
                                                    .stroke(AppColors.backgroundPrimary, lineWidth: 2.5)
                                                    .padding(2)
                                                Circle()
                                                    .stroke(AppColors.accentPrimary, lineWidth: 2)
                                                    .padding(-2)
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Color \(hex)")
                                .accessibilityAddTraits(selectedColor == hex ? .isSelected : [])
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
                .adaptiveScreenContent()
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

    private func customIconButton(for option: (name: String, label: String)) -> some View {
        let isSelected = selectedSymbol == option.name
        return Button {
            selectedSymbol = option.name
            HapticsService.selection()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? accentColor.opacity(0.18) : AppColors.backgroundPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(
                                isSelected ? accentColor : AppColors.cardBorder,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                Image(systemName: option.name)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isSelected ? accentColor : AppColors.ink.opacity(0.75))
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Preview")
                .font(AppTypography.metadata.weight(.semibold))
                .foregroundStyle(AppColors.inkSecondary)

            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(accentColor.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: selectedSymbol)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(accentColor)
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
