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

    private var itemCountText: String {
        "\(shareItems.count) item\(shareItems.count == 1 ? "" : "s")"
    }

    private var isEmpty: Bool {
        shareItems.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isEmpty {
                    emptyState
                } else {
                    listSummaryCard
                    qrCodeCard
                    actionCard
                }
            }
            .padding(.vertical, 16)
            .padding(.bottom, 8)
            .adaptiveScreenContent()
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

    private var listSummaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppColors.accentPrimary)
                    .frame(width: 38, height: 38)
                    .background(AppColors.accentPrimary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(list.name)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(AppColors.ink)
                        .lineLimit(2)

                    Text(itemCountText)
                        .font(AppTypography.metadata)
                        .foregroundStyle(AppColors.inkSecondary)
                }

                Spacer(minLength: 0)
            }

            Text("The other person gets their own copy.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.inkSecondary)
        }
        .appCard()
    }

    private var qrCodeCard: some View {
        VStack(spacing: 14) {
            if let code = shareCode, let image = QRCodeGenerator.image(for: code, dimension: 260) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .padding(14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityLabel("QR code for \(list.name)")
                    .accessibilityHint("Scan on another iPhone to import this list")
            }

            Text("Scan this code on another iPhone to import the list.")
                .font(AppTypography.metadata)
                .foregroundStyle(AppColors.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .appCard()
    }

    @ViewBuilder
    private var actionCard: some View {
        if let code = shareCode {
            VStack(spacing: 12) {
                ShareLink(
                    item: "\(shareText)\n\nImport code:\n\(code)",
                    subject: Text(list.name)
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
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

                Text("Share through Messages, AirDrop, WhatsApp, or email.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 2)
            }
            .appCard()
        }
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
