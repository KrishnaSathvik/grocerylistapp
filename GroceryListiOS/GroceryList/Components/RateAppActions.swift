import StoreKit
import SwiftUI

enum AppConfig {
    /// App Store ID for Groceries Smart Lists
    static let appStoreId: String? = "6785659442"

    static let feedbackEmail = "grocerylistapp.support@gmail.com"
    static let marketingPageURL = URL(string: "https://smartgrocerylists.app/")
    static let supportPageURL = URL(string: "https://smartgrocerylists.app/support")
    static let privacyPolicyURL = URL(string: "https://smartgrocerylists.app/privacy")

    static var appStoreURL: URL? {
        guard let appStoreId, !appStoreId.isEmpty else { return nil }
        return URL(string: "https://apps.apple.com/app/id\(appStoreId)")
    }
}

struct RateAppButton: View {
    @Environment(\.requestReview) private var requestReview

    var title: String = "Rate Groceries — Smart Lists"
    var icon: String = "star.fill"
    var iconColor: Color = AppColors.accentPrimary
    var subtitle: String? = nil

    var body: some View {
        Button {
            requestReview()
        } label: {
            SettingsRow(
                title: title,
                subtitle: subtitle,
                icon: icon,
                iconColor: iconColor
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Rate Groceries — Smart Lists on the App Store")
    }
}

struct OpenAppStoreButton: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        if let url = AppConfig.appStoreURL {
            Button {
                openURL(url)
            } label: {
                SettingsRow(
                    title: "Open App Store",
                    subtitle: "View Groceries — Smart Lists on the App Store.",
                    icon: "arrow.up.right.square",
                    iconColor: AppColors.colorHex("#8B6F8E")
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open Groceries — Smart Lists on the App Store")
        }
    }
}
