import SwiftUI
import UIKit

struct ShareListSheet: View {
    @Environment(\.dismiss) private var dismiss

    let list: GroceryList
    @State private var sharePayload: SharePayload?
    @State private var showQR = false
    @State private var toastMessage: String?

    private var shareItems: [GroceryItem] {
        list.items.filter { !$0.isArchived }
    }

    private var previewText: String {
        ShareTextFormatter.format(list: list)
    }

    private var previewLines: [String] {
        let active = shareItems.filter { !$0.isCompleted }.sorted { $0.sortOrder < $1.sortOrder }
        return active.prefix(5).map { item in
            let prefix = ShareTextFormatter.previewLine(for: item)
            return prefix
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    summaryCard

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Share As")
                            .font(AppTypography.metadata.weight(.semibold))
                            .foregroundStyle(AppColors.inkSecondary)

                        HStack(spacing: 12) {
                            shareActionCard(title: "Copy as\nText", icon: AppIcons.clipboard, tint: AppColors.accentPrimary, action: copyText)
                            shareActionCard(title: "Show QR\nCode", icon: AppIcons.qrCode, tint: AppColors.accentSuccess, action: showQRCode)
                            shareActionCard(title: "More", icon: AppIcons.more, tint: AppColors.colorHex("#8B6F8E"), action: shareViaSystem)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Share Preview")
                            .font(AppTypography.metadata.weight(.semibold))
                            .foregroundStyle(AppColors.inkSecondary)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(list.name)
                                .font(AppTypography.itemTitle)
                                .foregroundStyle(AppColors.ink)
                            Divider()
                            ForEach(Array(previewLines.enumerated()), id: \.offset) { _, line in
                                Text("• \(line)")
                                    .font(AppTypography.metadata)
                                    .foregroundStyle(AppColors.ink)
                            }
                            let remaining = max(0, shareItems.filter { !$0.isCompleted }.count - 5)
                            if remaining > 0 {
                                Text("… and \(remaining) more item\(remaining == 1 ? "" : "s")")
                                    .font(AppTypography.metadata)
                                    .foregroundStyle(AppColors.inkSecondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .appCard()
                    }

                    Button {
                        shareViaSystem()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: AppIcons.share)
                            Text("Share with Others")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .adaptiveScreenContent()
                .padding(.bottom, 24)
            }
            .background(AppColors.backgroundGrouped)
            .navigationTitle("Share List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
            }
            .sheet(isPresented: $showQR) {
                if let code = ListCodec.sharePayloadText(for: list) {
                    QRCodeDisplaySheet(code: code, listName: list.name)
                }
            }
            .sheet(item: $sharePayload) { payload in
                ActivityShareSheet(items: payload.items) {
                    sharePayload = nil
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
        }
        .presentationDetents([.large])
    }

    private var summaryCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppColors.colorHex(list.tintHex).opacity(0.16))
                    .frame(width: 56, height: 56)
                Image(systemName: list.iconName)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(AppColors.colorHex(list.tintHex))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("LIST NAME")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppColors.inkSecondary)
                Text(list.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppColors.ink)
                Text("\(list.activeItemCount) items")
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.inkSecondary)
            }
            Spacer(minLength: 0)
        }
        .appCard()
    }

    private func shareActionCard(title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(tint)
                    .frame(width: 48, height: 48)
                    .background(tint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.ink)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppColors.backgroundPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppColors.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func copyText() {
        UIPasteboard.general.string = previewText
        showToast("Copied!")
    }

    private func showQRCode() {
        guard ListCodec.sharePayloadText(for: list) != nil else {
            showToast("List too large to share")
            return
        }
        showQR = true
    }

    private func shareViaSystem() {
        sharePayload = SharePayload(items: [ShareTextFormatter.format(list: list)])
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

private struct SharePayload: Identifiable {
    let id = UUID()
    let items: [Any]
}

#Preview {
    ShareListSheet(list: GroceryList(name: "Weekly Groceries"))
}
