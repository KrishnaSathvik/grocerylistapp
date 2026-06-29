import SwiftUI
import SwiftData

struct AddCustomStoreSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var storeName = ""
    @State private var errorMessage: String?
    @FocusState private var isFocused: Bool

    private var trimmed: String {
        storeName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
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

                    Text("Use this store by typing naturally, like “milk from Local Market”.")
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
                .padding(AppSpacing.screenHorizontal)
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
            }
            .onAppear { isFocused = true }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func addStore() {
        errorMessage = nil
        switch StoreService.addCustomStore(label: trimmed, context: modelContext) {
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
