import SwiftUI
import UIKit

struct ShareListSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let list: GroceryList
    @State private var linkSharePayload: SharePayload?
    @State private var showQR = false
    @State private var toastMessage: String?
    @State private var shortShareURL: URL?
    @State private var isCreatingLink = false

    private var shareItems: [GroceryItem] {
        list.items.filter { !$0.isArchived }
    }

    private var itemCountText: String {
        "\(shareItems.count) item\(shareItems.count == 1 ? "" : "s")"
    }

    private var isEmpty: Bool {
        shareItems.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if isEmpty {
                        emptyState
                    } else {
                        listSummaryCard
                        shareActionsCard
                        moreOptionsCard
                    }
                }
                .padding(.vertical, 16)
                .padding(.bottom, 8)
                .adaptiveScreenContent()
            }
            .background(AppColors.backgroundGrouped)
            .navigationTitle(list.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showQR) {
                if let link = qrLink {
                    QRCodeDisplaySheet(code: link, listName: list.name)
                }
            }
            .sheet(item: $linkSharePayload) { payload in
                ActivityShareSheet(items: payload.items) {
                    linkSharePayload = nil
                }
            }
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
                }
            }
            .task {
                shortShareURL = await ShareLinkService.createShortLink(for: list, context: modelContext)
            }
        }
        .adaptiveSheetPresentation(.page)
    }

    private var qrLink: String? {
        shortShareURL?.absoluteString ?? ListCodec.shareLinkString(for: list)
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
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppColors.colorHex(list.tintHex).opacity(0.14))
                        .frame(width: 38, height: 38)
                    Image(systemName: list.iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppColors.colorHex(list.tintHex))
                }

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

            Text("They can import their own editable copy.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.inkSecondary)
        }
        .appCard()
    }

    private var shareActionsCard: some View {
        VStack(spacing: 12) {
            Button {
                shareListLink()
            } label: {
                HStack(spacing: 8) {
                    if isCreatingLink {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: AppIcons.share)
                    }
                    Text("Send Link")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isCreatingLink)
        }
        .appCard()
    }

    private var moreOptionsCard: some View {
        VStack(spacing: 0) {
            ShareOptionRow(
                title: "Show QR Code",
                subtitle: "Same link, scannable.",
                icon: AppIcons.qrCode,
                tint: AppColors.accentSuccess
            ) {
                showQRCode()
            }

            SettingsDivider()

            ShareOptionRow(
                title: "Copy as Text",
                subtitle: "Just the grocery list — not importable.",
                icon: AppIcons.clipboard,
                tint: AppColors.accentPrimary
            ) {
                copyAsText()
            }
        }
        .appCard(padding: 0)
    }

    private func shareListLink() {
        guard !shareItems.isEmpty else { return }
        isCreatingLink = true
        Task {
            let url: URL?
            if let cached = shortShareURL {
                url = cached
            } else {
                let created = await ShareLinkService.createShortLink(for: list, context: modelContext)
                shortShareURL = created
                url = created
            }
            isCreatingLink = false
            guard let url else {
                showToast("List too large to share")
                return
            }
            linkSharePayload = SharePayload(
                items: ShareLinkService.shareActivityItems(for: list.name, url: url)
            )
        }
    }

    private func showQRCode() {
        guard qrLink != nil else {
            showToast("List too large to share")
            return
        }
        showQR = true
    }

    private func copyAsText() {
        UIPasteboard.general.string = GroceryListShareBuilder.copyText(for: list, context: modelContext)
        showToast("Copied!")
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

private struct ShareOptionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tint.opacity(0.14))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(tint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(AppColors.ink)
                    Text(subtitle)
                        .font(AppTypography.metadata)
                        .foregroundStyle(AppColors.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: AppIcons.chevron)
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppColors.inkSecondary.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

private struct SharePayload: Identifiable {
    let id = UUID()
    let items: [Any]
}

#Preview {
    ShareListSheet(list: GroceryList(name: "Weekly Groceries"))
}
