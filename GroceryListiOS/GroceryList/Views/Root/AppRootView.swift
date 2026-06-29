import SwiftUI
import SwiftData

struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ImportCoordinator.self) private var importCoordinator

    @AppStorage(AppSettings.Keys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @AppStorage(AppSettings.Keys.preferredColorScheme) private var colorSchemeRaw = AppColorSchemePreference.system.rawValue

    @Query(
        filter: #Predicate<GroceryList> { !$0.isArchived },
        sort: [SortDescriptor(\GroceryList.sortOrder), SortDescriptor(\GroceryList.name)]
    )
    private var lists: [GroceryList]

    private var colorScheme: ColorScheme? {
        AppColorSchemePreference(rawValue: colorSchemeRaw)?.colorScheme
    }

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
        }
        .preferredColorScheme(colorScheme)
        .onOpenURL { url in
            _ = importCoordinator.load(from: url.absoluteString)
        }
        .sheet(isPresented: importSheetPresented) {
            if let items = importCoordinator.pendingItems {
                ImportConfirmSheet(
                    items: items,
                    onAdd: { applyImport(replace: false, items: items) },
                    onReplace: { applyImport(replace: true, items: items) }
                )
            }
        }
        .alert("Import", isPresented: Binding(
            get: { importCoordinator.statusMessage != nil && importCoordinator.pendingItems == nil },
            set: { if !$0 { importCoordinator.clearStatus() } }
        )) {
            Button("OK", role: .cancel) { importCoordinator.clearStatus() }
        } message: {
            Text(importCoordinator.statusMessage ?? "")
        }
    }

    private var importSheetPresented: Binding<Bool> {
        Binding(
            get: { importCoordinator.pendingItems != nil },
            set: { if !$0 { importCoordinator.clearPending() } }
        )
    }

    private func applyImport(replace: Bool, items: [ImportedListItem]) {
        guard let list = ActiveListResolver.resolve(from: lists) else {
            importCoordinator.statusMessage = "Create a list before importing."
            importCoordinator.clearPending()
            return
        }

        if replace {
            ListImportService.replaceItems(items, in: list, context: modelContext)
        } else {
            ListImportService.addItems(items, to: list, context: modelContext)
        }
        importCoordinator.clearPending()
        HapticsService.importSuccess()
    }
}

#Preview("Onboarding") {
    AppRootView()
        .modelContainer(try! ModelContainerSetup.makeContainer(inMemory: true))
        .environment(ImportCoordinator())
}

#Preview("Main") {
    AppRootView()
        .modelContainer(try! ModelContainerSetup.makeContainer(inMemory: true))
        .environment(ImportCoordinator())
        .onAppear { AppSettings.hasCompletedOnboarding = true }
}
