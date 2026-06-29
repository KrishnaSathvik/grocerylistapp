import SwiftUI
import SwiftData
import UIKit

enum StoreLogoResolver {
    private static let aliases: [String: String] = [
        "grebes": "gerbes",
    ]

    static func logoDomain(storeId: String?, displayLabel: String?) -> String? {
        guard let resolvedId = resolvedStoreId(storeId: storeId, displayLabel: displayLabel) else {
            return nil
        }
        return SeedData.storeDomain(for: resolvedId)
    }

    /// Canonical store id used for bundled `store-{id}` assets.
    static func resolvedStoreId(storeId: String?, displayLabel: String?) -> String? {
        let stores = SeedData.loadStoreDefinitions()
        let candidates = [
            storeId,
            displayLabel,
            storeId.flatMap { aliases[normalizedKey($0)] },
            displayLabel.flatMap { aliases[normalizedKey($0)] },
        ].compactMap { $0 }

        for candidate in candidates {
            let key = normalizedKey(candidate)
            if let store = stores.first(where: {
                normalizedKey($0.id) == key || normalizedKey($0.label) == key
            }) {
                return store.id
            }
        }
        return storeId
    }

    /// Bundled asset name when `store-{id}.imageset` exists in the catalog.
    static func bundledAssetName(storeId: String?, displayLabel: String?) -> String? {
        guard let resolvedId = resolvedStoreId(storeId: storeId, displayLabel: displayLabel) else {
            return nil
        }
        let name = "store-\(resolvedId)"
        return UIImage(named: name) != nil ? name : nil
    }

    private static func normalizedKey(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
    }
}

struct StoreLogoView: View {
    @Environment(\.modelContext) private var modelContext

    let storeId: String?
    var displayLabel: String?
    var size: CGFloat = 32
    var cornerRadius: CGFloat = 8

    private var bundledAssetName: String? {
        StoreLogoResolver.bundledAssetName(storeId: storeId, displayLabel: displayLabel)
    }

    private var hasBundledLogo: Bool {
        bundledAssetName != nil
    }

    private var resolvedStoreId: String? {
        storeId ?? displayLabel
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(badgeBackground)

            if let assetName = bundledAssetName {
                bundledLogo(named: assetName)
            } else {
                customBadge
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(AppColors.cardBorder.opacity(hasBundledLogo ? 0.65 : 0.45), lineWidth: 0.5)
        )
        .shadow(color: AppColors.cardShadow.opacity(0.16), radius: 3, y: 1)
    }

    private var badgeBackground: Color {
        if hasBundledLogo { return AppColors.backgroundPrimary }
        return accentColor.opacity(0.18)
    }

    private var accentColor: Color {
        AppColors.colorHex(resolvedAccentHex)
    }

    @ViewBuilder
    private func bundledLogo(named assetName: String) -> some View {
        if let uiImage = CatalogBadgeImage.trimmed(named: assetName) ?? UIImage(named: assetName) {
            let logoSize = CatalogBadgeImage.iconSize(forContainer: size, assetName: assetName)
            Image(uiImage: uiImage)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: logoSize, height: logoSize)
        }
    }

    @ViewBuilder
    private var customBadge: some View {
        Image(systemName: resolvedIconSymbol)
            .font(.system(size: size * 0.46, weight: .semibold))
            .foregroundStyle(accentColor)
    }

    private var resolvedIconSymbol: String {
        if let storeId,
           let symbol = StoreService.iconSymbol(for: storeId, context: modelContext),
           !symbol.isEmpty {
            return symbol
        }
        return StoreBranding.iconSymbol(for: label)
    }

    private var resolvedAccentHex: String {
        if let storeId, let hex = StoreService.colorHex(for: storeId, context: modelContext) {
            return hex
        }
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
}

#Preview {
    HStack(spacing: 12) {
        StoreLogoView(storeId: "costco", size: 44, cornerRadius: 12)
        StoreLogoView(storeId: "walmart", size: 44, cornerRadius: 12)
        StoreLogoView(storeId: "local-market", displayLabel: "Local Market", size: 44, cornerRadius: 12)
    }
    .padding()
    .background(AppColors.backgroundGrouped)
    .modelContainer(try! ModelContainerSetup.makeContainer(inMemory: true))
}
