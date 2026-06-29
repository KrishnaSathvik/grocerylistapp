import SwiftUI
import UIKit

enum OnboardingTheme {
    static let pageSpring = Animation.spring(response: 0.5, dampingFraction: 0.86)
    static let contentSpring = Animation.spring(response: 0.45, dampingFraction: 0.82)
    static let heroSpring = Animation.spring(response: 0.55, dampingFraction: 0.84)

    /// Prominent centered onboarding app title.
    static var brandHeadline: Font {
        .system(size: 30, weight: .bold, design: .rounded)
    }

    struct Page {
        let title: String
        let subtitle: String
        let imageName: String
    }

    static let pages: [Page] = [
        Page(
            title: "Shop smarter",
            subtitle: "Type groceries in any order. We sort them into the right categories automatically.",
            imageName: "onboarding_shop_smarter"
        ),
        Page(
            title: "Add naturally",
            subtitle: "Type “2 eggs from Walmart” and we’ll detect the item, quantity, category, and store.",
            imageName: "onboarding_add_naturally"
        ),
        Page(
            title: "Every view you need",
            subtitle: "Switch between Lists, Store, and Categories without reorganizing anything.",
            imageName: "onboarding_every_view"
        ),
        Page(
            title: "Share anywhere",
            subtitle: "Send lists to family or import them back. Works offline — no account required.",
            imageName: "onboarding_share_anywhere"
        ),
    ]
}

struct OnboardingMeshBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppColors.heroGradientTop,
                    AppColors.backgroundGrouped,
                    Color(light: "#F0F4FF", dark: "#0A0A0C")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(AppColors.accentSuccess.opacity(0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 80)
                .offset(x: -120, y: -200)

            Circle()
                .fill(Color(light: "#D6E8FF", dark: "#1A2A3A").opacity(0.35))
                .frame(width: 220, height: 220)
                .blur(radius: 70)
                .offset(x: 140, y: 80)
        }
    }
}

struct OnboardingPageDots: View {
    @Environment(\.colorScheme) private var colorScheme

    let count: Int
    let current: Int

    private let activeWidth: CGFloat = 24
    private let inactiveSize: CGFloat = 6
    private let dotHeight: CGFloat = 6

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(
                        index == current
                            ? AppColors.accentPrimary
                            : AppColors.inkTertiary.opacity(colorScheme == .dark ? 0.55 : 0.35)
                    )
                    .frame(
                        width: index == current ? activeWidth : inactiveSize,
                        height: dotHeight
                    )
                    .animation(.easeInOut(duration: 0.22), value: current)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Onboarding progress")
        .accessibilityValue("Page \(current + 1) of \(count)")
    }
}
