import Foundation

struct AppIconOption: Identifiable, Equatable {
    let id: String
    let label: String
    let previewAssetName: String
    /// `nil` selects the primary app icon.
    let alternateIconName: String?

    var accessibilityLabel: String {
        "\(label) app icon"
    }

    static let classic = AppIconOption(
        id: "classic",
        label: "Grocery Bag",
        previewAssetName: "app-icon-preview-classic",
        alternateIconName: nil
    )

    static let all: [AppIconOption] = [
        .classic,
        AppIconOption(
            id: "sage-bag",
            label: "Sage Grocery Bag",
            previewAssetName: "app-icon-preview-sage-bag",
            alternateIconName: "AppIconSageBag"
        ),
        AppIconOption(
            id: "navy-cart",
            label: "Navy Cart",
            previewAssetName: "app-icon-preview-navy-cart",
            alternateIconName: "AppIconNavyCart"
        ),
        AppIconOption(
            id: "produce",
            label: "Fresh Produce",
            previewAssetName: "app-icon-preview-produce",
            alternateIconName: "AppIconProduce"
        ),
        AppIconOption(
            id: "cream",
            label: "Cream Minimal",
            previewAssetName: "app-icon-preview-cream",
            alternateIconName: "AppIconCream"
        ),
        AppIconOption(
            id: "dark",
            label: "Dark Mode",
            previewAssetName: "app-icon-preview-dark",
            alternateIconName: "AppIconDark"
        ),
    ]

    static func matching(alternateIconName: String?) -> AppIconOption {
        all.first { $0.alternateIconName == alternateIconName } ?? .classic
    }
}
