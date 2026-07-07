import Compression
import Foundation

struct ParsedSharedList: Equatable, Sendable {
    let listName: String?
    let items: [ImportedListItem]
}

struct ImportedListItem: Equatable, Sendable, Identifiable {
    let id: UUID
    let name: String
    let quantityValue: Int?
    let quantityText: String?
    let categoryId: String
    let storeId: String?
    let notes: String?
    let isCompleted: Bool

    init(
        id: UUID = UUID(),
        name: String,
        quantityValue: Int?,
        quantityText: String? = nil,
        categoryId: String,
        storeId: String?,
        notes: String? = nil,
        isCompleted: Bool
    ) {
        self.id = id
        self.name = name
        self.quantityValue = quantityValue
        self.quantityText = quantityText
        self.categoryId = categoryId
        self.storeId = storeId
        self.notes = notes
        self.isCompleted = isCompleted
    }
}

enum ListCodec {
    static let shareHost = "smartgrocerylists.app"
    static let sharePath = "/app"
    static let shortSharePathPrefix = "/s/"
    /// Legacy hash URLs still accepted on import.
    static let shareBaseURL = "https://\(shareHost)\(sharePath)/"
    static let maxLinkItems = 50
    static let importQueryKey = "import"
    static let importFragmentPrefix = "#import="
    static let sharedPayloadPrefix = "GLIST1:"

    private struct SharedGroceryListPayload: Codable {
        let version: Int
        let type: String
        let listName: String
        let createdAt: Date
        let items: [SharedGroceryItem]
    }

    private struct SharedGroceryItem: Codable {
        let name: String
        let quantity: Int?
        let quantityText: String?
        let categoryId: String?
        let storeId: String?
        let notes: String?
        let isCompleted: Bool
    }

    private struct SlimItem: Codable {
        let t: String
        let q: Int?
        let c: String?
        let s: String?
        let k: Int?
    }

    static func encode(items: [GroceryItem]) -> String? {
        let active = items.filter { !$0.isArchived }
        guard !active.isEmpty, active.count <= maxLinkItems else { return nil }

        let slim: [SlimItem] = active.map { item in
            SlimItem(
                t: item.name,
                q: {
                    guard let qty = item.quantityValue, qty > 1 else { return nil }
                    return qty
                }(),
                c: item.categoryId == "misc" ? nil : item.categoryId,
                s: item.storeId,
                k: item.isCompleted ? 1 : nil
            )
        }

        guard let data = try? JSONEncoder().encode(slim) else { return nil }
        return data.base64EncodedString()
    }

    static func decode(_ encoded: String) -> [ImportedListItem]? {
        let trimmed = encoded.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        var base64 = trimmed
        if let payload = extractPayload(from: trimmed) {
            base64 = payload
        }

        guard let data = Data(base64Encoded: base64),
              let json = String(data: data, encoding: .utf8),
              let slim = try? JSONDecoder().decode([SlimItem].self, from: Data(json.utf8)),
              !slim.isEmpty else {
            return nil
        }

        return slim.map { entry in
            ImportedListItem(
                name: entry.t,
                quantityValue: {
                    guard let qty = entry.q, qty > 1 else { return nil }
                    return qty
                }(),
                categoryId: entry.c ?? "misc",
                storeId: entry.s,
                isCompleted: entry.k == 1
            )
        }
    }

    static func shareURL(for items: [GroceryItem]) -> URL? {
        guard let encoded = encode(items: items) else { return nil }
        var components = URLComponents()
        components.scheme = "https"
        components.host = shareHost
        components.path = sharePath
        components.queryItems = [URLQueryItem(name: importQueryKey, value: encoded)]
        return components.url
    }

    static func shareLinkURL(for list: GroceryList) -> URL? {
        shareURL(for: list.items.filter { !$0.isArchived })
    }

    static func shareLinkString(for list: GroceryList) -> String? {
        shareLinkURL(for: list)?.absoluteString
    }

    static func shortShareURL(for id: String) -> URL? {
        let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: "https://\(shareHost)\(shortSharePathPrefix)\(trimmed)")
    }

    static func extractShortShareId(from raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let url = URL(string: trimmed), let host = url.host?.lowercased(), host.contains(shareHost) {
            let path = url.path
            if path.hasPrefix(shortSharePathPrefix) {
                let id = String(path.dropFirst(shortSharePathPrefix.count))
                return id.isEmpty ? nil : id
            }
        }

        guard let range = trimmed.range(of: shortSharePathPrefix) else { return nil }
        let suffix = trimmed[range.upperBound...]
        let id = suffix
            .split(whereSeparator: { $0.isWhitespace || $0 == "?" || $0 == "#" || $0 == "/" })
            .first
            .map(String.init) ?? ""
        return id.isEmpty ? nil : id
    }

    static func parseImportPayload(from raw: String) -> [ImportedListItem]? {
        parseSharedList(from: raw)?.items
    }

    static func parseSharedList(from raw: String) -> ParsedSharedList? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let embedded = embeddedSharePayload(in: trimmed) {
            return embedded
        }

        if trimmed.hasPrefix(sharedPayloadPrefix) {
            return decodeSharedPayload(trimmed)
        }

        if let payload = extractPayload(from: trimmed),
           let items = decode(payload),
           !items.isEmpty {
            return ParsedSharedList(listName: nil, items: items)
        }

        guard let items = decode(trimmed), !items.isEmpty else {
            return PlainTextListParser.parse(trimmed)
        }
        return ParsedSharedList(listName: nil, items: items)
    }

    /// Finds import payloads hidden inside a pasted message, link, or legacy code.
    private static func embeddedSharePayload(in raw: String) -> ParsedSharedList? {
        if let glistRange = raw.range(of: sharedPayloadPrefix) {
            let suffix = String(raw[glistRange.lowerBound...])
            let token = suffix
                .split(whereSeparator: \.isWhitespace)
                .first
                .map(String.init) ?? suffix
            if let parsed = decodeSharedPayload(token.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return parsed
            }
        }

        if let url = firstShareURL(in: raw),
           let payload = extractPayload(from: url),
           let items = decode(payload),
           !items.isEmpty {
            return ParsedSharedList(listName: nil, items: items)
        }

        if let importRange = raw.range(of: "Import code:", options: [.caseInsensitive, .backwards]) {
            let codeOnly = raw[importRange.upperBound...]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if codeOnly.hasPrefix(sharedPayloadPrefix),
               let parsed = decodeSharedPayload(codeOnly) {
                return parsed
            }
        }

        return nil
    }

    private static func firstShareURL(in text: String) -> String? {
        for prefix in ["https://\(shareHost)", "http://\(shareHost)"] {
            guard let range = text.range(of: prefix) else { continue }
            let suffix = text[range.lowerBound...]
            let token = suffix
                .split(whereSeparator: \.isWhitespace)
                .first
                .map(String.init) ?? String(suffix)
            let cleaned = token.trimmingCharacters(in: CharacterSet(charactersIn: ".,);]\"'"))
            if cleaned.contains(shareHost) {
                return cleaned
            }
        }
        return nil
    }

    static func shareCode(for list: GroceryList) -> String? {
        let active = list.items.filter { !$0.isArchived }
        guard !active.isEmpty, active.count <= maxLinkItems else { return nil }

        let payload = SharedGroceryListPayload(
            version: 1,
            type: "grocery-list",
            listName: list.name,
            createdAt: .now,
            items: active.map { item in
                SharedGroceryItem(
                    name: item.name,
                    quantity: {
                        guard let qty = item.quantityValue, qty > 1 else { return nil }
                        return qty
                    }(),
                    quantityText: item.quantityText,
                    categoryId: item.categoryId == "misc" ? nil : item.categoryId,
                    storeId: item.storeId,
                    notes: item.notes,
                    isCompleted: item.isCompleted
                )
            }
        )

        guard let json = try? JSONEncoder().encode(payload),
              let compressed = compress(json) else {
            return nil
        }

        return "\(sharedPayloadPrefix)\(base64URLEncode(compressed))"
    }

    /// Public share link encoded in QR codes and universal links.
    static func sharePayloadText(for list: GroceryList) -> String? {
        shareLinkString(for: list)
    }

    /// Rich paste-only payload with list name, notes, and quantity text.
    static func sharePasteCode(for list: GroceryList) -> String? {
        shareCode(for: list)
    }

    private static func decodeSharedPayload(_ raw: String) -> ParsedSharedList? {
        let encoded = String(raw.dropFirst(sharedPayloadPrefix.count))
        guard let compressed = base64URLDecode(encoded),
              let json = decompress(compressed),
              let payload = try? JSONDecoder().decode(SharedGroceryListPayload.self, from: json),
              payload.type == "grocery-list",
              payload.version == 1,
              !payload.items.isEmpty,
              payload.items.count <= maxLinkItems else {
            return nil
        }

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
                isCompleted: entry.isCompleted
            )
        }

        return ParsedSharedList(listName: payload.listName, items: items)
    }

    private static func compress(_ data: Data) -> Data? {
        try? (data as NSData).compressed(using: .zlib) as Data
    }

    private static func decompress(_ data: Data) -> Data? {
        try? (data as NSData).decompressed(using: .zlib) as Data
    }

    private static func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func base64URLDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padding = (4 - base64.count % 4) % 4
        base64 += String(repeating: "=", count: padding)
        return Data(base64Encoded: base64)
    }

    private static func extractPayload(from raw: String) -> String? {
        if raw.contains(importFragmentPrefix) {
            let parts = raw.components(separatedBy: importFragmentPrefix)
            return parts.last?.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let components = URLComponents(string: raw) else { return nil }

        if let queryValue = components.queryItems?
            .first(where: { $0.name == importQueryKey })?
            .value?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !queryValue.isEmpty {
            return queryValue
        }

        if let fragment = components.fragment, fragment.hasPrefix("import=") {
            return String(fragment.dropFirst("import=".count))
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return nil
    }
}
