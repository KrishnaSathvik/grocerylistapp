import SwiftUI
import SwiftData
import UIKit

struct ShareActiveListView: View {
    let list: GroceryList

    @State private var toastMessage: String?

    private var shareItems: [GroceryItem] {
        list.items.filter { !$0.isArchived }
    }

    private var shareCode: String? {
        ListCodec.sharePayloadText(for: list)
    }

    private var shareText: String {
        ShareTextFormatter.format(list: list)
    }

    private var isEmpty: Bool {
        shareItems.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if isEmpty {
                    emptyState
                } else {
                    heroSection
                    actionButtons
                    explanation
                }
            }
            .padding(AppSpacing.screenHorizontal)
            .padding(.vertical, 16)
            .padding(.bottom, 8)
        }
        .background(AppColors.backgroundGrouped)
        .navigationTitle("Share Active List")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            if let toastMessage {
                Text(toastMessage)
                    .font(AppTypography.metadata.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppColors.ink.opacity(0.92))
                    .clipShape(Capsule())
                    .padding(.bottom, 24)
                    .accessibilityLabel(toastMessage)
            }
        }
        .settingsSubpageStyle()
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 44))
                .foregroundStyle(AppColors.inkSecondary)
            Text("Nothing to share yet")
                .font(AppTypography.itemTitle)
                .foregroundStyle(AppColors.ink)
            Text("Add items before sharing this list.")
                .font(AppTypography.metadata)
                .foregroundStyle(AppColors.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private var heroSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text(list.name)
                    .font(AppTypography.onboardingTitle)
                    .foregroundStyle(AppColors.ink)
                    .multilineTextAlignment(.center)

                Text("\(shareItems.count) item\(shareItems.count == 1 ? "" : "s")")
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.inkSecondary)

                Text("No account required. The other person gets their own copy.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.inkSecondary)
                    .multilineTextAlignment(.center)
            }

            if let code = shareCode, let image = QRCodeGenerator.image(for: code, dimension: 240) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 240, height: 240)
                    .padding(16)
                    .background(AppColors.backgroundPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(AppColors.cardBorder, lineWidth: 1)
                    )
                    .accessibilityLabel("QR code for \(list.name)")
                    .accessibilityHint("Scan on another iPhone to import this list")
            }

            Text("Scan this code on another iPhone to import the list.")
                .font(AppTypography.metadata)
                .foregroundStyle(AppColors.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var actionButtons: some View {
        if let code = shareCode {
            VStack(spacing: 10) {
                ShareLink(
                    item: shareText,
                    subject: Text(list.name),
                    message: Text(code)
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up.fill")
                        Text("Share List")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityLabel("Share list")

                Button("Copy Code") {
                    copyCode(code)
                }
                .font(AppTypography.button)
                .foregroundStyle(AppColors.accentPrimary)
                .accessibilityLabel("Copy shared list code")
            }
        }
    }

    private var explanation: some View {
        Text("Show this QR code to someone nearby, or send the list through Messages, AirDrop, WhatsApp, or email.")
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.inkSecondary)
            .multilineTextAlignment(.center)
            .padding(.top, 4)
    }

    private func copyCode(_ code: String) {
        UIPasteboard.general.string = code
        showToast("Code copied")
        HapticsService.selection()
    }

    private func showToast(_ message: String) {
        toastMessage = message
        Task {
            try? await Task.sleep(for: .seconds(2))
            if toastMessage == message {
                toastMessage = nil
            }
        }
    }
}

#Preview {
    NavigationStack {
        ShareActiveListView(list: GroceryList(name: "Weekly Groceries"))
    }
}
