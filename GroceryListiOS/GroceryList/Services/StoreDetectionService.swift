import Foundation

enum StoreDetectionService {
    struct StoreTag: Equatable, Sendable {
        let query: String?
        let cleanText: String
    }

    struct StorePhrase: Equatable, Sendable {
        let query: String?
        let cleanText: String
        let isExplicit: Bool

        var hasStore: Bool {
            guard let query else { return false }
            return !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    static func parseStoreTag(_ raw: String) -> StoreTag {
        let phrase = parseStorePhrase(raw, stores: SeedData.loadStoreDefinitions())
        return StoreTag(query: phrase.query, cleanText: phrase.cleanText)
    }

    static func parseStorePhrase(
        _ raw: String,
        stores: [SeedData.StoreDefinition]
    ) -> StorePhrase {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return StorePhrase(query: nil, cleanText: "", isExplicit: false)
        }

        if let atTag = parseAtTag(trimmed) {
            return StorePhrase(query: atTag.query, cleanText: atTag.cleanText, isExplicit: true)
        }

        if let explicit = parseExplicitPreposition(trimmed) {
            return StorePhrase(
                query: explicit.storeName,
                cleanText: explicit.cleanText,
                isExplicit: true
            )
        }

        if let bare = parseBareKnownStore(trimmed, stores: stores) {
            return StorePhrase(
                query: bare.storeName,
                cleanText: bare.cleanText,
                isExplicit: false
            )
        }

        return StorePhrase(query: nil, cleanText: trimmed, isExplicit: false)
    }

    /// Detects a default store from list names like "Costco Run" or "Walmart List".
    static func defaultStoreId(forListName rawName: String, stores: [SeedData.StoreDefinition]) -> String? {
        let normalized = normalizeStoreKey(rawName)
        guard !normalized.isEmpty else { return nil }

        let genericSuffixes: Set<String> = [
            "run", "list", "trip", "shop", "shopping", "haul", "errand", "errands", "pickup", "order", "stop"
        ]

        let rankedStores = stores.sorted {
            normalizeStoreKey($0.label).count > normalizeStoreKey($1.label).count
        }

        for store in rankedStores {
            let storeKeys = [normalizeStoreKey(store.label), normalizeStoreKey(store.id)].filter { !$0.isEmpty }
            for storeKey in storeKeys {
                if normalized == storeKey {
                    return store.id
                }

                if normalized.hasPrefix(storeKey + " ") {
                    let remainder = String(normalized.dropFirst(storeKey.count + 1))
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    let firstWord = remainder.split(separator: " ").first.map(String.init) ?? ""
                    if remainder.isEmpty || genericSuffixes.contains(firstWord) || genericSuffixes.contains(remainder) {
                        return store.id
                    }
                }

                if normalized.hasSuffix(" " + storeKey) {
                    let prefix = String(normalized.dropLast(storeKey.count + 1))
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    let prefixWords = prefix.split(separator: " ")
                    if prefixWords.count <= 2,
                       genericSuffixes.contains(String(prefixWords.last ?? "")) || prefixWords.count == 1 {
                        return store.id
                    }
                }
            }
        }

        return nil
    }

    static func resolveStoreId(
        query: String?,
        stores: [SeedData.StoreDefinition]
    ) -> String? {
        guard let query, !query.isEmpty else { return nil }

        let normalizedQuery = normalizeStoreKey(query)

        if let exact = stores.first(where: { normalizeStoreKey($0.id) == normalizedQuery }) {
            return exact.id
        }
        if let labelMatch = stores.first(where: { normalizeStoreKey($0.label) == normalizedQuery }) {
            return labelMatch.id
        }

        let ranked = stores.compactMap { store -> (String, Int)? in
            guard storeMatchesQuery(store, query: query) else { return nil }
            return (store.id, matchScore(store: store, query: query))
        }
        .sorted { $0.1 > $1.1 }

        return ranked.first?.0
    }

    static func titleCaseStoreLabel(_ raw: String) -> String {
        raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: \.isWhitespace)
            .map { word in
                let lower = word.lowercased()
                return lower.prefix(1).uppercased() + lower.dropFirst()
            }
            .joined(separator: " ")
    }

    static func normalizeStoreKey(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "-", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    // MARK: - Private

    private static func parseAtTag(_ raw: String) -> StoreTag? {
        guard let regex = try? NSRegularExpression(pattern: #"@(\S*)$"#),
              let match = regex.firstMatch(in: raw, range: NSRange(raw.startIndex..., in: raw)),
              let queryRange = Range(match.range(at: 1), in: raw),
              let fullRange = Range(match.range, in: raw) else {
            return nil
        }

        let query = String(raw[queryRange]).lowercased()
        let clean = String(raw[..<fullRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        return StoreTag(query: query, cleanText: clean)
    }

    private struct ExplicitMatch {
        let cleanText: String
        let storeName: String
    }

    private static func parseExplicitPreposition(_ raw: String) -> ExplicitMatch? {
        guard let regex = try? NSRegularExpression(
            pattern: #"(?i)^(.+?)\s+(?:from|at|in)\s+(.+)$"#
        ),
        let match = regex.firstMatch(in: raw, range: NSRange(raw.startIndex..., in: raw)),
        let itemRange = Range(match.range(at: 1), in: raw),
        let storeRange = Range(match.range(at: 2), in: raw) else {
            return nil
        }

        let itemText = String(raw[itemRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        let storeName = String(raw[storeRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !itemText.isEmpty, !storeName.isEmpty else { return nil }
        return ExplicitMatch(cleanText: itemText, storeName: storeName)
    }

    private struct BareStoreMatch {
        let cleanText: String
        let storeName: String
    }

    private static func parseBareKnownStore(
        _ raw: String,
        stores: [SeedData.StoreDefinition]
    ) -> BareStoreMatch? {
        let sortedStores = stores.sorted {
            normalizeStoreKey($0.label).count > normalizeStoreKey($1.label).count
        }

        for store in sortedStores {
            let candidates = [
                normalizeStoreKey(store.label),
                normalizeStoreKey(store.id),
            ]

            for candidate in candidates where !candidate.isEmpty {
                guard let match = trailingStoreMatch(in: raw, storeKey: candidate) else { continue }
                return BareStoreMatch(cleanText: match.cleanText, storeName: match.storeName)
            }
        }

        return nil
    }

    private static func trailingStoreMatch(in raw: String, storeKey: String) -> BareStoreMatch? {
        let normalizedRaw = normalizeStoreKey(raw)
        guard normalizedRaw.hasSuffix(storeKey) else { return nil }

        let prefixLength = normalizedRaw.count - storeKey.count
        guard prefixLength > 0 else { return nil }

        let prefixNormalized = String(normalizedRaw.prefix(prefixLength))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prefixNormalized.isEmpty else { return nil }

        let rawWords = raw.split(whereSeparator: \.isWhitespace)
        let storeWordCount = storeKey.split(separator: " ").count
        guard rawWords.count > storeWordCount else { return nil }

        let itemWords = rawWords.dropLast(storeWordCount)
        let storeWords = rawWords.suffix(storeWordCount)
        let itemText = itemWords.joined(separator: " ")
        let storeName = storeWords.joined(separator: " ")
        guard !itemText.isEmpty else { return nil }

        return BareStoreMatch(cleanText: itemText, storeName: storeName)
    }

    private static func storeMatchesQuery(
        _ store: SeedData.StoreDefinition,
        query: String
    ) -> Bool {
        let normalizedQuery = normalizeStoreKey(query)
        let normalizedLabel = normalizeStoreKey(store.label)
        let normalizedId = normalizeStoreKey(store.id)

        if normalizedQuery == normalizedLabel || normalizedQuery == normalizedId {
            return true
        }
        if normalizedLabel.hasPrefix(normalizedQuery) || normalizedId.hasPrefix(normalizedQuery) {
            return true
        }
        if normalizedQuery.hasPrefix(normalizedLabel) || normalizedQuery.hasPrefix(normalizedId) {
            return true
        }

        let queryTokens = normalizedQuery.split(separator: " ")
        let labelTokens = normalizedLabel.split(separator: " ")
        guard !queryTokens.isEmpty, !labelTokens.isEmpty else { return false }

        return queryTokens.allSatisfy { queryToken in
            labelTokens.contains { labelToken in
                labelToken.hasPrefix(queryToken) || queryToken.hasPrefix(labelToken)
            }
        }
    }

    private static func matchScore(store: SeedData.StoreDefinition, query: String) -> Int {
        let normalizedQuery = normalizeStoreKey(query)
        let normalizedLabel = normalizeStoreKey(store.label)
        let normalizedId = normalizeStoreKey(store.id)

        if normalizedQuery == normalizedLabel || normalizedQuery == normalizedId {
            return 1000 + normalizedLabel.count
        }
        if normalizedLabel.hasPrefix(normalizedQuery) || normalizedId.hasPrefix(normalizedQuery) {
            return 500 + normalizedQuery.count
        }
        return normalizedQuery.count
    }
}
