import SwiftUI
import SwiftData

@main
struct GroceryListApp: App {
    @State private var containerState = ContainerState()

    init() {
        AppAppearance.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                switch containerState.phase {
                case .ready(let container):
                    AppRootView()
                        .environment(ImportCoordinator())
                        .onAppear {
                            SeedData.bootstrapIfNeeded(context: container.mainContext)
                            try? container.mainContext.save()
                        }
                        .modelContainer(container)

                case .failed(let error):
                    ModelContainerErrorView(error: error) {
                        containerState.resetStore()
                    }
                }
            }
        }
    }
}

@Observable
@MainActor
final class ContainerState {
    enum Phase {
        case ready(ModelContainer)
        case failed(Error)
    }

    private(set) var phase: Phase

    init() {
        phase = Self.loadContainer()
    }

    func resetStore() {
        do {
            try ModelContainerSetup.resetPersistentStore()
            phase = Self.loadContainer()
        } catch {
            phase = .failed(error)
        }
    }

    private static func loadContainer() -> Phase {
        do {
            return .ready(try ModelContainerSetup.makeContainer())
        } catch {
            return .failed(error)
        }
    }
}
