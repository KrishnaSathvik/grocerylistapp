import Foundation

enum StoreAliasService {
    struct AliasMatch: Equatable, Sendable {
        let storeId: String
        let storeLabel: String
        let matchedAlias: String
        let cleanText: String
        let storeName: String
    }

    /// Extra aliases beyond auto-generated label variants.
    private static let builtInAliases: [String: [String]] = [
        "heb": ["heb", "h e b", "h-e-b"],
        "panasia": ["pan asia", "pan asia supermarket"],
        "wholefoods": ["whole foods", "whole foods market"],
        "traderjoes": ["trader joes", "trader joeys", "trader joe's"],
        "samsclub": ["sams", "sams club", "sam's club"],
        "walmart": ["wal mart", "wal-mart"],
        "costco": ["costco wholesale"],
        "hmart": ["h mart", "h-mart"],
        "patelbros": ["patel brothers", "patel bros"],
        "99ranch": ["99 ranch", "99 ranch market"],
        "sprouts": ["sprouts farmers market", "sprouts market"],
        "amazon": ["amazon fresh"],
    ]

    private static let genericSuffixes = [
        "supermarket", "market", "wholesale", "grocery", "groceries", "store", "fresh", "club", "foods"
    ]

    static func normalizeKey(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "&", with: " and ")
            .replacingOccurrences(of: "-", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func aliases(for store: SeedData.StoreDefinition) -> [String] {
        var keys = Set<String>()

        keys.insert(normalizeKey(store.label))
        keys.insert(normalizeKey(store.id.replacingOccurrences(of: "-", with: " ")))

        if let builtIn = builtInAliases[store.id] {
            for alias in builtIn {
                keys.insert(normalizeKey(alias))
            }
        }

        let labelKey = normalizeKey(store.label)
        let words = labelKey.split(separator: " ").map(String.init)

        if words.count >= 2 {
            keys.insert(words.prefix(2).joined(separator: " "))
        }
        if words.count >= 3 {
            keys.insert(words.prefix(3).joined(separator: " "))
        }

        for suffix in genericSuffixes {
            if labelKey.hasSuffix(" \(suffix)") {
                keys.insert(String(labelKey.dropLast(suffix.count + 1)))
            }
        }

        return keys
            .filter { !$0.isEmpty }
            .sorted { $0.count > $1.count }
    }

    static func protectedPhrases(for stores: [SeedData.StoreDefinition]) -> [String] {
        var phrases = Set<String>()
        for store in stores {
            phrases.insert(store.label)
            phrases.insert(store.id.replacingOccurrences(of: "-", with: " "))
            if let builtIn = builtInAliases[store.id] {
                for alias in builtIn {
                    phrases.insert(alias)
                }
            }
            let words = store.label.split(separator: " ").map(String.init)
            if words.count >= 2 {
                phrases.insert(words.prefix(2).joined(separator: " "))
            }
        }
        return phrases.sorted { $0.count > $1.count }
    }

    static func resolveStoreId(query: String, stores: [SeedData.StoreDefinition]) -> String? {
        let normalizedQuery = normalizeKey(query)
        guard !normalizedQuery.isEmpty else { return nil }

        for store in stores {
            for alias in aliases(for: store) where alias == normalizedQuery {
                return store.id
            }
        }

        if normalizedQuery.count <= 3 {
            return nil
        }

        return nil
    }

    static func findTrailingAlias(in raw: String, stores: [SeedData.StoreDefinition]) -> AliasMatch? {
        let normalizedRaw = normalizeKey(raw)
        guard !normalizedRaw.isEmpty else { return nil }

        var best: AliasMatch?

        for store in stores {
            for alias in aliases(for: store) where !alias.isEmpty {
                guard normalizedRaw.hasSuffix(alias) else { continue }

                let prefixLength = normalizedRaw.count - alias.count
                guard prefixLength > 0 else { continue }

                let prefixNormalized = String(normalizedRaw.prefix(prefixLength))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                guard !prefixNormalized.isEmpty else { continue }

                guard let cleanText = stripAliasFromRaw(raw, alias: alias) else { continue }

                let candidate = AliasMatch(
                    storeId: store.id,
                    storeLabel: store.label,
                    matchedAlias: alias,
                    cleanText: cleanText,
                    storeName: displayStoreName(for: alias, store: store)
                )

                if best == nil || alias.count > best!.matchedAlias.count {
                    best = candidate
                }
            }
        }

        return best
    }

    private static func displayStoreName(for alias: String, store: SeedData.StoreDefinition) -> String {
        if normalizeKey(store.label) == alias || normalizeKey(store.id) == alias {
            return store.label
        }
        return StoreDetectionService.titleCaseStoreLabel(alias)
    }

    private static func stripAliasFromRaw(_ raw: String, alias: String) -> String? {
        let rawWords = raw.split(whereSeparator: \.isWhitespace).map(String.init)
        let aliasWordCount = alias.split(separator: " ").count
        guard rawWords.count > aliasWordCount else { return nil }

        let tailWords = rawWords.suffix(aliasWordCount)
        let tailNormalized = normalizeKey(tailWords.joined(separator: " "))
        guard tailNormalized == alias else { return nil }

        let itemWords = rawWords.dropLast(aliasWordCount)
        let itemText = itemWords.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !itemText.isEmpty else { return nil }
        return itemText
    }
}
