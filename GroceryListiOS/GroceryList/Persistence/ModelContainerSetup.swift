import Foundation
import SwiftData

enum ModelContainerSetup {
    static let schema = Schema([
        GroceryList.self,
        GroceryItem.self,
        GroceryStore.self,
        CategoryLearningRule.self,
    ])

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// Deletes the on-disk SwiftData store so the app can recover from corruption.
    static func resetPersistentStore() throws {
        let configuration = ModelConfiguration(schema: schema)
        let url = configuration.url
        let fileManager = FileManager.default
        let related = [
            url,
            url.appendingPathExtension("wal"),
            url.appendingPathExtension("shm"),
        ]
        for fileURL in related where fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }
}
