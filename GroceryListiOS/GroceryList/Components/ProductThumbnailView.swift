import SwiftUI
import UIKit

/// Shows a bundled product or category illustration when available — never placeholders or broken icons in list UI.
struct ProductThumbnailView: View {
    let assetName: String?
    var size: CGFloat = AppSpacing.thumbnailSize
    var showStubAssets: Bool = false

    var body: some View {
        if let assetName,
           shouldShow(assetName),
           let uiImage = UIImage(named: assetName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .accessibilityHidden(true)
        }
    }

    private func shouldShow(_ assetName: String) -> Bool {
        if showStubAssets { return UIImage(named: assetName) != nil }
        return CatalogAssetAvailability.isUsable(assetName)
    }
}
