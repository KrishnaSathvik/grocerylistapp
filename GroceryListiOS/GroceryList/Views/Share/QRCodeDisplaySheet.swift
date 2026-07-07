import SwiftUI
import UIKit

struct QRCodeDisplaySheet: View {
    @Environment(\.dismiss) private var dismiss
    let code: String
    let listName: String
    @State private var copied = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text(listName)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(AppColors.ink)
                        .multilineTextAlignment(.center)

                    Text("Scan to import this list")
                        .font(AppTypography.metadata)
                        .foregroundStyle(AppColors.inkSecondary)
                }

                if let image = QRCodeGenerator.image(for: code, dimension: 260) {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .padding(14)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .accessibilityLabel("QR code for \(listName)")
                }

                Text("Point their camera at this code, or copy the link below.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Button(copied ? "Copied!" : "Copy Link") {
                    UIPasteboard.general.string = code
                    copied = true
                    HapticsService.selection()
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityLabel("Copy share link")

                Spacer(minLength: 0)
            }
            .adaptiveScreenContent()
            .padding(.top, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(AppColors.backgroundGrouped)
            .navigationTitle("QR Code")
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
        code: "https://smartgrocerylists.app/s/AbC123",
        listName: "Weekly Groceries"
    )
}
