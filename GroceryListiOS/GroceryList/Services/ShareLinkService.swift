import Foundation
import SwiftData

enum ShareLinkService {
    private static let apiURL = URL(string: "https://smartgrocerylists.app/api/share")!

    private struct SharePayload: Encodable {
        let name: String
        let items: [ShareItem]
    }

    private struct ShareItem: Encodable {
        let name: String
        let quantity: Int?
        let quantityText: String?
        let categoryId: String?
        let storeId: String?
        let notes: String?
        let completed: Bool
    }

    private struct CreateResponse: Decodable {
        let id: String
        let url: String
    }

    private struct RemoteSharePayload: Decodable {
        let name: String
        let items: [RemoteShareItem]
    }

    private struct RemoteShareItem: Decodable {
        let name: String
        let quantity: Int?
        let quantityText: String?
        let categoryId: String?
        let storeId: String?
        let notes: String?
        let completed: Bool?
    }

    static func createShortLink(for list: GroceryList, context: ModelContext) async -> URL? {
        guard let payload = buildPayload(for: list) else { return nil }

        guard let body = try? JSONEncoder().encode(payload) else {
            return ListCodec.shareLinkURL(for: list)
        }

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = 12

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return ListCodec.shareLinkURL(for: list)
            }

            if (200...299).contains(http.statusCode),
               let decoded = try? JSONDecoder().decode(CreateResponse.self, from: data),
               let shareURL = URL(string: decoded.url) {
                return shareURL
            }

            return ListCodec.shareLinkURL(for: list)
        } catch {
            return ListCodec.shareLinkURL(for: list)
        }
    }

    static func fetchSharedList(id: String) async -> ParsedSharedList? {
        let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let url = URL(string: "https://smartgrocerylists.app/api/share/\(trimmed)") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 12

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return nil
            }

            let payload = try JSONDecoder().decode(RemoteSharePayload.self, from: data)
            let items = payload.items.map { entry in
                ImportedListItem(
                    name: entry.name,
                    quantityValue: {
                        guard let qty = entry.quantity, qty > 1 else { return nil }
                        return qty
                    }(),
                    quantityText: entry.quantityText,
                    categoryId: entry.categoryId ?? "misc",
                    storeId: entry.storeId,
                    notes: entry.notes,
                    isCompleted: entry.completed ?? false
                )
            }
            guard !items.isEmpty else { return nil }
            return ParsedSharedList(listName: payload.name, items: items)
        } catch {
            return nil
        }
    }

    static func shareMessage(for listName: String) -> String {
        let trimmed = listName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? "Grocery list" : trimmed
        return "Here's my grocery list — \(name)"
    }

    static func shareActivityItems(for listName: String, url: URL) -> [Any] {
        [shareMessage(for: listName), url]
    }

    private static func buildPayload(for list: GroceryList) -> SharePayload? {
        let active = list.items.filter { !$0.isArchived }
        guard !active.isEmpty, active.count <= ListCodec.maxLinkItems else { return nil }

        return SharePayload(
            name: list.name,
            items: active.map { item in
                ShareItem(
                    name: item.name,
                    quantity: {
                        guard let qty = item.quantityValue, qty > 1 else { return nil }
                        return qty
                    }(),
                    quantityText: item.quantityText,
                    categoryId: item.categoryId == "misc" ? nil : item.categoryId,
                    storeId: item.storeId,
                    notes: item.notes,
                    completed: item.isCompleted
                )
            }
        )
    }
}
