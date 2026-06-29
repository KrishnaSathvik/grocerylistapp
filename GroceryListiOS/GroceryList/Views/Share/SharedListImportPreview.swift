import SwiftUI

struct SharedListImportPreview: View {
    @Environment(\.dismiss) private var dismiss

    let parsed: ParsedSharedList
    let onImport: () -> Void
    let onCancel: () -> Void

    private var previewItems: [ImportedListItem] {
        Array(parsed.items.prefix(5))
    }

    private var listTitle: String {
        parsed.listName ?? "Shared List"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 6) {
                        Text("Import \(listTitle)?")
                            .font(AppTypography.onboardingTitle)
                            .foregroundStyle(AppColors.ink)
                            .multilineTextAlignment(.center)

                        Text("\(parsed.items.count) item\(parsed.items.count == 1 ? "" : "s")")
                            .font(AppTypography.metadata)
                            .foregroundStyle(AppColors.inkSecondary)
                    }
                    .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(previewItems.enumerated()), id: \.element.id) { index, item in
                            if index > 0 {
                                Divider().padding(.leading, 16)
                            }
                            Text(item.name)
                                .font(AppTypography.itemTitle)
                                .foregroundStyle(AppColors.ink)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                        }

                        if parsed.items.count > previewItems.count {
                            Divider().padding(.leading, 16)
                            Text("+ \(parsed.items.count - previewItems.count) more item\(parsed.items.count - previewItems.count == 1 ? "" : "s")")
                                .font(AppTypography.metadata)
                                .foregroundStyle(AppColors.inkSecondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                        }
                    }
                    .background(AppColors.backgroundPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous)
                            .stroke(AppColors.cardBorder, lineWidth: 1)
                    )

                    VStack(spacing: 10) {
                        Button("Import List") {
                            onImport()
                            dismiss()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .accessibilityLabel("Import list")

                        Button("Cancel") {
                            onCancel()
                            dismiss()
                        }
                        .font(AppTypography.button)
                        .foregroundStyle(AppColors.inkSecondary)
                    }
                    .padding(.bottom, 24)
                }
                .adaptiveScreenContent()
            }
            .background(AppColors.backgroundGrouped)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    SharedListImportPreview(
        parsed: ParsedSharedList(
            listName: "Weekly Groceries",
            items: [
                ImportedListItem(name: "Milk", quantityValue: 2, categoryId: "dairy", storeId: nil, isCompleted: false),
                ImportedListItem(name: "Eggs", quantityValue: nil, categoryId: "dairy", storeId: nil, isCompleted: false),
            ]
        ),
        onImport: {},
        onCancel: {}
    )
}
