import SwiftUI
import UIKit

struct QRCodeDisplaySheet: View {
    @Environment(\.dismiss) private var dismiss
    let code: String
    let listName: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(listName)
                    .font(AppTypography.itemTitle)
                    .foregroundStyle(AppColors.ink)

                if let image = QRCodeGenerator.image(for: code, dimension: 260) {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 260, height: 260)
                        .padding(16)
                        .background(AppColors.backgroundPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .accessibilityLabel("QR code for \(listName)")
                }

                Text("Scan this code on another iPhone to import the list.")
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Button("Copy Code") {
                    UIPasteboard.general.string = code
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .accessibilityLabel("Copy shared list code")

                Spacer()
            }
            .padding(.top, 24)
            .frame(maxWidth: .infinity)
            .background(AppColors.backgroundGrouped)
            .navigationTitle("Share List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    QRCodeDisplaySheet(
        code: "GLIST1:abc123",
        listName: "Weekly Groceries"
    )
}
