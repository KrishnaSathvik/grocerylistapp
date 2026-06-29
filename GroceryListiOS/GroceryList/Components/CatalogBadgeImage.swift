import UIKit

/// Trims transparent padding from catalog icons so badge rendering stays visually consistent.
enum CatalogBadgeImage {
    /// Baseline fill inside a badge container after transparent trim.
    static let fillRatio: CGFloat = 0.88

    private static let cache = NSCache<NSString, UIImage>()

    /// Per-asset boost for icons whose artwork still reads smaller after canvas normalization.
    static func assetFillScale(for assetName: String) -> CGFloat {
        switch assetName {
        case "category-dairy", "category-seafood": return 1.06
        default: return 1.0
        }
    }

    static func trimmed(named assetName: String) -> UIImage? {
        if let cached = cache.object(forKey: assetName as NSString) {
            return cached
        }
        guard let image = UIImage(named: assetName),
              let trimmed = trimTransparentPadding(from: image) else {
            return UIImage(named: assetName)
        }
        cache.setObject(trimmed, forKey: assetName as NSString)
        return trimmed
    }

    static func iconSize(forContainer containerSize: CGFloat, assetName: String? = nil) -> CGFloat {
        let scale = assetName.map(assetFillScale(for:)) ?? 1
        return min(containerSize * 0.96, containerSize * fillRatio * scale)
    }

    private static func trimTransparentPadding(from image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return nil }

        guard let data = cgImage.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else {
            return image
        }

        let bytesPerPixel = cgImage.bitsPerPixel / 8
        guard bytesPerPixel >= 4 else { return image }

        let bytesPerRow = cgImage.bytesPerRow
        let alphaThreshold: UInt8 = 12

        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0
        var foundVisiblePixel = false

        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * bytesPerPixel
                let alpha = bytes[offset + 3]
                guard alpha > alphaThreshold else { continue }

                foundVisiblePixel = true
                minX = min(minX, x)
                minY = min(minY, y)
                maxX = max(maxX, x)
                maxY = max(maxY, y)
            }
        }

        guard foundVisiblePixel else { return image }

        let cropRect = CGRect(
            x: minX,
            y: minY,
            width: max(1, maxX - minX + 1),
            height: max(1, maxY - minY + 1)
        )

        guard let cropped = cgImage.cropping(to: cropRect) else { return image }
        return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
    }
}
