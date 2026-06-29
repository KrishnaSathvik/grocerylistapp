import SwiftUI

enum AppColors {
    // MARK: - Core palette

    static let backgroundPrimary = Color(light: "#FFFFFF", dark: "#111114")
    static let backgroundGrouped = Color(light: "#F5F5F7", dark: "#000000")
    static let backgroundElevated = Color(light: "#FFFFFF", dark: "#1C1C1E")
    static let ink = Color(light: "#1A1F36", dark: "#F5F5F7")
    static let inkSecondary = Color(light: "#6B7280", dark: "#98989D")
    static let accentLink = Color(light: "#007AFF", dark: "#0A84FF")
    /// Primary CTA — dark navy per design references.
    static let accentPrimary = Color(light: "#1A1F36", dark: "#F5F5F7")
    static let accentSuccess = Color(light: "#4A7C59", dark: "#5E9A6E")
    static let accentDestructive = Color(light: "#FF3B30", dark: "#FF453A")
    static let filterSelected = Color(light: "#1A1F36", dark: "#F5F5F7")
    static let filterUnselected = Color(light: "#ECECF0", dark: "#2C2C2E")
    static let addBarBackground = Color(light: "#FFFFFF", dark: "#1C1C1E")
    static let cardBorder = Color(light: "#E5E7EB", dark: "#38383A")
    static let cardShadow = Color.black.opacity(0.08)
    static let heroGradientTop = Color(light: "#E8F5EC", dark: "#142118")

    // MARK: - Category tints

    static func categoryTint(for categoryId: String) -> Color {
        if let hex = CategoryService.colorHex(for: categoryId) {
            return colorHex(hex).opacity(0.14)
        }
        switch categoryId {
        case "produce": return colorHex("#E8F5E9")
        case "dairy": return colorHex("#E8F4FD")
        case "meat": return colorHex("#FDE8E8")
        case "seafood": return colorHex("#E3F2FD")
        case "bakery": return colorHex("#FFF3E0")
        case "deli": return colorHex("#FBE9E7")
        case "frozen": return colorHex("#E8EAF6")
        case "pantry": return colorHex("#FFF3E0")
        case "snacks": return colorHex("#FCE4EC")
        case "condiments": return colorHex("#FFF8E1")
        case "drinks": return colorHex("#E0F2F1")
        case "household": return colorHex("#ECEFF1")
        case "health": return colorHex("#F3E5F5")
        case "baby": return colorHex("#FCE4EC")
        case "pet": return colorHex("#E8F5E9")
        case "asian": return colorHex("#F3E5F5")
        default: return colorHex("#F3F4F6")
        }
    }

    static func colorHex(_ hex: String) -> Color {
        Color(hex: hex)
    }

    // MARK: - Store header tints

    static func storeHeaderTint(for storeId: String?) -> Color {
        guard let storeId else { return colorHex("#F3F4F6").opacity(0.9) }
        if let hex = SeedData.storeColorHex(for: storeId) {
            return colorHex(hex).opacity(0.12)
        }
        switch storeId {
        case "costco": return colorHex("#FDE8E8")
        case "hmart": return colorHex("#E8EAF6")
        default: return colorHex("#F3F4F6")
        }
    }
}

extension Color {
    init(light: String, dark: String) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: dark)
                : UIColor(hex: light)
        })
    }

    init(hex: String) {
        self.init(uiColor: UIColor(hex: hex))
    }
}

private extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255
        let b = CGFloat(rgb & 0x0000FF) / 255

        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
