import SwiftUI

struct StoreLogoView: View {
    let storeId: String?
    var displayLabel: String?
    var size: CGFloat = 32
    var cornerRadius: CGFloat = 8

    var body: some View {
        Group {
            if let storeId, let url = faviconURL(for: storeId) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .padding(6)
                            .frame(maxWidth: size - 8, maxHeight: size - 8)
                    case .failure:
                        fallbackBadge
                    default:
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            } else {
                fallbackBadge
            }
        }
        .frame(width: size, height: size)
        .background(AppColors.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var fallbackBadge: some View {
        let symbol = customStoreSymbol
        let hex = customAccentHex
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(AppColors.colorHex(hex).opacity(0.16))
            Image(systemName: symbol)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(AppColors.colorHex(hex))
        }
    }

    private var customStoreSymbol: String {
        StoreBranding.iconSymbol(for: label)
    }

    private var customAccentHex: String {
        if let storeId, let hex = SeedData.storeColorHex(for: storeId) {
            return hex
        }
        return StoreBranding.colorHex(for: label)
    }

    private var label: String {
        if let displayLabel, !displayLabel.isEmpty {
            return displayLabel
        }
        return SeedData.storeLabel(for: storeId)
    }

    private var accentHex: String {
        guard let storeId else { return "#6B7280" }
        return SeedData.storeColorHex(for: storeId) ?? StoreBranding.colorHex(for: label)
    }

    private func faviconURL(for storeId: String) -> URL? {
        guard let domain = SeedData.storeDomain(for: storeId) else { return nil }
        return URL(string: "https://www.google.com/s2/favicons?domain=\(domain)&sz=64")
    }
}

#Preview {
    HStack(spacing: 12) {
        StoreLogoView(storeId: "costco")
        StoreLogoView(storeId: "hmart")
        StoreLogoView(storeId: nil)
    }
    .padding()
}
