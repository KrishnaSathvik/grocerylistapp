import SwiftUI
import SwiftData

struct AddCustomStoreSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var storeName = ""
    @State private var selectedSymbol = CustomStoreIconOptions.symbols[0].name
    @State private var selectedColor = StoreBranding.customStoreColorOptions[0]
    @State private var errorMessage: String?
    @FocusState private var isFocused: Bool

    private var trimmed: String {
        storeName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var displayName: String {
        let titled = StoreDetectionService.titleCaseStoreLabel(trimmed)
        return titled.isEmpty ? "Store name" : titled
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
                        Text("Store name")
                            .font(AppTypography.metadata.weight(.semibold))
                            .foregroundStyle(AppColors.inkSecondary)
                        TextField("e.g. Local Market", text: $storeName)
                            .font(AppTypography.itemTitle)
                            .focused($isFocused)
                            .padding(14)
                            .background(AppColors.backgroundPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(AppColors.cardBorder, lineWidth: 1)
                            )
                            .accessibilityLabel("Store name")
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Icon")
                            .font(AppTypography.metadata.weight(.semibold))
                            .foregroundStyle(AppColors.inkSecondary)
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4),
                            spacing: 10
                        ) {
                            ForEach(CustomStoreIconOptions.symbols, id: \.name) { option in
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
                            ForEach(StoreBranding.customStoreColorOptions, id: \.self) { hex in
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
                            }
                        }
                    }

                    Text("Use this store by typing naturally, like “milk from \(displayName)”.")
                        .font(AppTypography.metadata)
                        .foregroundStyle(AppColors.inkSecondary)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(AppTypography.metadata.weight(.semibold))
                            .foregroundStyle(AppColors.accentDestructive)
                    }

                    Button("Add Store", action: addStore)
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(trimmed.isEmpty)
                        .opacity(trimmed.isEmpty ? 0.55 : 1)
                        .accessibilityLabel("Add store")
                }
                .adaptiveScreenContent()
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(AppColors.backgroundGrouped)
            .navigationTitle("Add Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { addStore() }
                        .fontWeight(.semibold)
                        .disabled(trimmed.isEmpty)
                }
            }
            .onAppear { isFocused = true }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
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
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName)
                        .font(AppTypography.itemTitle)
                        .foregroundStyle(AppColors.ink)
                    Text("Custom store")
                        .font(AppTypography.metadata)
                        .foregroundStyle(AppColors.inkSecondary)
                }
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

    private func addStore() {
        errorMessage = nil
        switch StoreService.addCustomStore(
            label: trimmed,
            iconSymbol: selectedSymbol,
            colorHex: selectedColor,
            context: modelContext
        ) {
        case .added:
            HapticsService.add()
            dismiss()
        case .duplicate:
            errorMessage = "This store already exists."
            HapticsService.selection()
        case .invalid:
            errorMessage = "Enter a store name."
        }
    }
}
