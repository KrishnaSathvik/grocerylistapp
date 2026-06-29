import UIKit
import SwiftUI

enum AppAppearance {
    static func configure() {
        let nav = UINavigationBarAppearance()
        nav.configureWithDefaultBackground()
        nav.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
        nav.titleTextAttributes = [
            .foregroundColor: UIColor(AppColors.ink),
            .font: systemUIFont(size: 17, weight: .semibold, rounded: true),
        ]
        nav.largeTitleTextAttributes = [
            .foregroundColor: UIColor(AppColors.ink),
            .font: systemUIFont(size: 34, weight: .bold, rounded: true),
        ]

        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav

        let tab = UITabBarAppearance()
        tab.configureWithDefaultBackground()
        tab.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
        tab.backgroundColor = UIColor(AppColors.backgroundPrimary.opacity(0.92))

        let normalColor = UIColor(AppColors.inkSecondary.opacity(0.72))
        let selectedColor = UIColor(AppColors.accentPrimary)

        [tab.stackedLayoutAppearance, tab.inlineLayoutAppearance, tab.compactInlineLayoutAppearance].forEach { item in
            item.normal.iconColor = normalColor
            item.normal.titleTextAttributes = [
                .foregroundColor: normalColor,
                .font: systemUIFont(size: 10, weight: .medium),
            ]
            item.selected.iconColor = selectedColor
            item.selected.titleTextAttributes = [
                .foregroundColor: selectedColor,
                .font: systemUIFont(size: 10, weight: .semibold),
            ]
        }

        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
        UITabBar.appearance().tintColor = selectedColor
        UITabBar.appearance().unselectedItemTintColor = normalColor
    }

    private static func systemUIFont(size: CGFloat, weight: UIFont.Weight, rounded: Bool = false) -> UIFont {
        let system = UIFont.systemFont(ofSize: size, weight: weight)
        guard rounded, let descriptor = system.fontDescriptor.withDesign(.rounded) else {
            return system
        }
        return UIFont(descriptor: descriptor, size: size)
    }
}
