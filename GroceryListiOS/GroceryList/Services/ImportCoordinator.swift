import Foundation

@Observable
@MainActor
final class ImportCoordinator {
    var pendingItems: [ImportedListItem]?
    var pendingListName: String?
    var statusMessage: String?

    func load(from raw: String) -> Bool {
        if ListCodec.extractShortShareId(from: raw) != nil {
            return false
        }
        return loadResolved(ListCodec.parseSharedList(from: raw))
    }

    func loadAsync(from raw: String) async -> Bool {
        if let shortId = ListCodec.extractShortShareId(from: raw),
           let parsed = await ShareLinkService.fetchSharedList(id: shortId) {
            return loadResolved(parsed)
        }
        return load(from: raw)
    }

    private func loadResolved(_ parsed: ParsedSharedList?) -> Bool {
        guard let parsed, !parsed.items.isEmpty else {
            statusMessage = "This doesn't look like a Groceries — Smart Lists sharing link."
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
