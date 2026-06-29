import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MyListsView()
                .tabItem {
                    Label("Lists", systemImage: AppIcons.lists)
                }
                .tag(0)

            StoreTabView()
                .tabItem {
                    Label("Store", systemImage: AppIcons.store)
                }
                .tag(1)

            CategoriesTabView()
                .tabItem {
                    Label("Categories", systemImage: AppIcons.categories)
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("More", systemImage: AppIcons.settings)
                }
                .tag(3)
        }
        .tint(AppColors.accentPrimary)
        .accessibilityLabel("Main navigation")
    }
}

#Preview {
    MainTabView()
        .modelContainer(try! ModelContainerSetup.makeContainer(inMemory: true))
}
