import SwiftUI

struct ImportConfirmSheet: View {
    @Environment(\.dismiss) private var dismiss

    let items: [ImportedListItem]
    let onAdd: () -> Void
    let onReplace: () -> Void

    private var previewItems: [ImportedListItem] {
        Array(items.prefix(12))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "tray.and.arrow.down.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(AppColors.accentSuccess)
                        .padding(.top, 8)
                        .accessibilityHidden(true)

                    VStack(spacing: 6) {
                        Text("Import grocery list")
                            .font(AppTypography.onboardingTitle)
                            .foregroundStyle(AppColors.ink)
                        Text("\(items.count) item\(items.count == 1 ? "" : "s") ready to import")
                            .font(AppTypography.metadata)
                            .foregroundStyle(AppColors.inkSecondary)
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(previewItems.enumerated()), id: \.element.id) { index, item in
                            if index > 0 {
                                Divider().padding(.leading, 16)
                            }
                            ImportedItemPreviewRow(item: item)
                        }

                        if items.count > previewItems.count {
                            Divider().padding(.leading, 16)
                            Text("+ \(items.count - previewItems.count) more item\(items.count - previewItems.count == 1 ? "" : "s")")
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
                        Button("Add to Current List") {
                            onAdd()
                            dismiss()
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Button("Replace Current List") {
                            onReplace()
                            dismiss()
                        }
                        .font(AppTypography.largeButton)
                        .foregroundStyle(AppColors.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AppColors.backgroundPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius, style: .continuous)
                                .stroke(AppColors.cardBorder, lineWidth: 1)
                        )
                        .accessibilityLabel("Replace current list with imported items")

                        Button("Cancel") {
                            dismiss()
                        }
                        .font(AppTypography.button)
                        .foregroundStyle(AppColors.inkSecondary)
                        .accessibilityLabel("Cancel import")
                    }
                    .padding(.bottom, 24)
                }
                .adaptiveScreenContent()
            }
            .background(AppColors.backgroundGrouped)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    ImportConfirmSheet(
        items: [
            ImportedListItem(name: "Milk", quantityValue: 2, categoryId: "dairy", storeId: "costco", isCompleted: false),
            ImportedListItem(name: "Eggs", quantityValue: nil, categoryId: "dairy", storeId: nil, isCompleted: true),
        ],
        onAdd: {},
        onReplace: {}
    )
}
