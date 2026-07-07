import Foundation
import SwiftData

enum ActiveListResolver {
    static func resolve(from lists: [GroceryList]) -> GroceryList? {
        if let idString = AppSettings.activeListId,
           let id = UUID(uuidString: idString),
           let match = lists.first(where: { $0.id == id }) {
            return match
        }
        return lists.first
    }

    static func setActive(_ list: GroceryList) {
        AppSettings.activeListId = list.id.uuidString
    }

    static func clearActive() {
        AppSettings.activeListId = nil
    }

    static var activeListId: UUID? {
        guard let idString = AppSettings.activeListId else { return nil }
        return UUID(uuidString: idString)
    }
}
