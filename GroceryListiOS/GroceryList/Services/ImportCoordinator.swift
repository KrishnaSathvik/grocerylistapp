import Foundation

@Observable
@MainActor
final class ImportCoordinator {
    var pendingItems: [ImportedListItem]?
    var pendingListName: String?
    var statusMessage: String?

    func load(from raw: String) -> Bool {
        guard let parsed = ListCodec.parseSharedList(from: raw), !parsed.items.isEmpty else {
            statusMessage = "Couldn't read that shared list."
            return false
        }
        pendingItems = parsed.items
        pendingListName = parsed.listName
        return true
    }

    func clearPending() {
        pendingItems = nil
        pendingListName = nil
    }

    func clearStatus() {
        statusMessage = nil
    }
}
