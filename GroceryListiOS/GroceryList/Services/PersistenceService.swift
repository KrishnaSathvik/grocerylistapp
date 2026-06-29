import Foundation
import SwiftData

enum PersistenceService {
    @discardableResult
    static func save(context: ModelContext, operation: String) -> Bool {
        save(operation: operation) {
            try context.save()
        }
    }

    @discardableResult
    static func save(
        operation: String,
        save: () throws -> Void,
        logger: (String) -> Void = { NSLog("%@", $0) }
    ) -> Bool {
        do {
            try save()
            return true
        } catch {
            logger("Persistence save failed during \(operation): \(error)")
            return false
        }
    }
}
