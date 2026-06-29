import StoreKit
import SwiftUI

enum AppConfig {
    /// Set after the app is created in App Store Connect.
    static let appStoreId: String? = nil

    static let feedbackEmail = "grocerylistapp.support@gmail.com"
    static let marketingPageURL = URL(string: "https://grocerylistapp.vercel.app/home")
    static let supportPageURL = URL(string: "https://grocerylistapp.vercel.app/support")
    static let privacyPolicyURL = URL(string: "https://grocerylistapp.vercel.app/privacy")

    static var appStoreURL: URL? {
        guard let appStoreId, !appStoreId.isEmpty else { return nil }
        return URL(string: "https://apps.apple.com/app/id\(appStoreId)")
    }
}

struct RateAppButton: View {
    @Environment(\.requestReview) private var requestReview

    var title: String = "Rate Grocery List"
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
        .accessibilityLabel("Rate Grocery List on the App Store")
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
                    subtitle: "View Grocery List on the App Store.",
                    icon: "arrow.up.right.square",
                    iconColor: AppColors.colorHex("#8B6F8E")
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open Grocery List on the App Store")
        }
    }
}
