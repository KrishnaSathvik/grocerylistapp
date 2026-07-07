import SwiftUI
import SwiftData
import UIKit

struct ShareActiveListView: View {
    @Environment(\.modelContext) private var modelContext

    let list: GroceryList

    @State private var sharePayload: SharePayload?

    private var shareItems: [GroceryItem] {
        list.items.filter { !$0.isArchived }
    }

    private var shareCode: String? {
        ListCodec.shareLinkString(for: list)
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
        .settingsSubpageStyle()
        .sheet(item: $sharePayload) { payload in
            ActivityShareSheet(items: payload.items) {
                sharePayload = nil
            }
        }
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
                    .accessibilityHint("Scan to open the list in Groceries or import in a browser")
            }

            Text("Scan to import in the app, or open in Safari if they don't have it yet.")
                .font(AppTypography.metadata)
                .foregroundStyle(AppColors.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .appCard()
    }

    @ViewBuilder
    private var actionCard: some View {
        if shareCode != nil {
            VStack(spacing: 12) {
                Button {
                    sharePayload = SharePayload(
                        items: GroceryListShareBuilder.activityItems(for: list, context: modelContext)
                    )
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share List")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityLabel("Share list as text with import link")

                Text("Sends a readable list by text. Use the QR code above so they can import into the app.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 2)
            }
            .appCard()
        }
    }
}

private struct SharePayload: Identifiable {
    let id = UUID()
    let items: [Any]
}

#Preview {
    NavigationStack {
        ShareActiveListView(list: GroceryList(name: "Weekly Groceries"))
    }
}
