import SwiftUI
import UIKit

/// Shows a bundled product or category illustration when available — never placeholders or broken icons in list UI.
struct ProductThumbnailView: View {
    let assetName: String?
    var size: CGFloat = AppSpacing.thumbnailSize
    var showStubAssets: Bool = false
    /// When true, trims transparent padding and fills the badge area consistently (category/store badges).
    var badgeFill: Bool = false

    var body: some View {
        if let assetName,
           shouldShow(assetName),
           let uiImage = resolvedImage(named: assetName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: renderedSize, height: renderedSize)
                .accessibilityHidden(true)
        }
    }

    private var renderedSize: CGFloat {
        badgeFill ? CatalogBadgeImage.iconSize(forContainer: size, assetName: assetName) : size
    }

    private func resolvedImage(named assetName: String) -> UIImage? {
        if badgeFill {
            return CatalogBadgeImage.trimmed(named: assetName)
        }
        return UIImage(named: assetName)
    }

    private func shouldShow(_ assetName: String) -> Bool {
        if showStubAssets { return UIImage(named: assetName) != nil }
        return CatalogAssetAvailability.isUsable(assetName)
    }
}
