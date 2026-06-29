import SwiftUI

private enum TabBarLayout {
    static let phoneExtraBottomPadding: CGFloat = 72
    static let tabletExtraBottomPadding: CGFloat = 12
}

private struct TabBarSafePaddingModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    func body(content: Content) -> some View {
        let extraPadding = horizontalSizeClass == .regular
            ? TabBarLayout.tabletExtraBottomPadding
            : TabBarLayout.phoneExtraBottomPadding

        content.safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: extraPadding)
        }
    }
}

extension View {
    /// Extra scroll padding so tab-bar content is not visually crowded.
    func tabBarSafePadding() -> some View {
        modifier(TabBarSafePaddingModifier())
    }
}
