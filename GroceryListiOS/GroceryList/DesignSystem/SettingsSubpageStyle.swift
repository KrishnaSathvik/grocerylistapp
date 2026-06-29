import SwiftUI

extension View {
    /// Hides the tab bar on pushed settings subpages and adds bottom scroll padding.
    func settingsSubpageStyle() -> some View {
        toolbar(.hidden, for: .tabBar)
            .tabBarSafePadding()
    }
}
