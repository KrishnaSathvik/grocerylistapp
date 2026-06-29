import UIKit

enum CatalogAssetAvailability {
    /// True when a bundled image exists and is not a tiny grey stub placeholder.
    static func isUsable(_ assetName: String) -> Bool {
        guard let image = UIImage(named: assetName),
              let cgImage = image.cgImage else {
            return false
        }
        return cgImage.width >= 100 && cgImage.height >= 100
    }
}
