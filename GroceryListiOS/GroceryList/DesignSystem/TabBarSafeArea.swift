import SwiftUI

private enum TabBarLayout {
    /// Clears the floating tab bar so scroll content stays readable.
    static let extraBottomPadding: CGFloat = 72
}

extension View {
    /// Extra scroll padding so tab-bar content is not visually crowded.
    func tabBarSafePadding() -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: TabBarLayout.extraBottomPadding)
        }
    }
}
