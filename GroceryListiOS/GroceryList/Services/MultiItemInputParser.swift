import Foundation

enum MultiItemInputParser {
    static func parse(
        _ raw: String,
        learningRules: [CategoryLearningRule] = [],
        stores: [SeedData.StoreDefinition]? = nil
    ) -> [ParsedItemInput] {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let storeList = stores ?? SeedData.loadStoreDefinitions()
        let segments = splitIntoSegments(trimmed, stores: storeList)

        if segments.count <= 1 {
            return [ItemInputParser.parse(trimmed, learningRules: learningRules, stores: storeList)]
        }

        let parsed = parseSegments(segments, learningRules: learningRules, stores: storeList)
        let valid = parsed.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        if valid.isEmpty {
            return [ItemInputParser.parse(trimmed, learningRules: learningRules, stores: storeList)]
        }

        return valid
    }

    // MARK: - Splitting

    private static func splitIntoSegments(
        _ raw: String,
        stores: [SeedData.StoreDefinition]
    ) -> [String] {
        let (masked, restore) = maskProtectedPhrases(raw, stores: stores)
        let primaryParts = splitOnPrimaryDelimiters(masked)
        let andParts = primaryParts.flatMap { splitOnAnd($0) }

        return andParts
            .map { restore($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func splitOnPrimaryDelimiters(_ text: String) -> [String] {
        var segments: [String] = []
        var current = ""

        for character in text {
            switch character {
            case "\n", ",", ";", "+":
                if !current.isEmpty {
                    segments.append(current)
                    current = ""
                }
            default:
                current.append(character)
            }
        }

        if !current.isEmpty {
            segments.append(current)
        }

        return segments
    }

    private static func splitOnAnd(_ text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: #"(?i)\s+and\s+"#) else {
            return [text]
        }

        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)
        guard !matches.isEmpty else { return [text] }

        var segments: [String] = []
        var lastIndex = text.startIndex

        for match in matches {
            guard let matchRange = Range(match.range, in: text) else { continue }
            let segment = String(text[lastIndex ..< matchRange.lowerBound])
            if !segment.isEmpty {
                segments.append(segment)
            }
            lastIndex = matchRange.upperBound
        }

        let tail = String(text[lastIndex...])
        if !tail.isEmpty {
            segments.append(tail)
        }

        return segments.isEmpty ? [text] : segments
    }

    private static func maskProtectedPhrases(
        _ text: String,
        stores: [SeedData.StoreDefinition]
    ) -> (String, (String) -> String) {
        var masked = text
        var replacements: [(token: String, original: String)] = []

        let protectedPhrases = protectedStorePhrases(stores: stores)
        for (index, phrase) in protectedPhrases.enumerated() {
            let token = "\u{E000}STORE\(index)\u{E001}"
            masked = masked.replacingOccurrences(
                of: phrase,
                with: token,
                options: [.caseInsensitive]
            )
            replacements.append((token: token, original: phrase))
        }

        let restore: (String) -> String = { value in
            replacements.reduce(value) { current, replacement in
                current.replacingOccurrences(of: replacement.token, with: replacement.original)
            }
        }

        return (masked, restore)
    }

    private static func protectedStorePhrases(stores: [SeedData.StoreDefinition]) -> [String] {
        StoreAliasService.protectedPhrases(for: stores)
    }

    // MARK: - Segment parsing

    private static func parseSegments(
        _ segments: [String],
        learningRules: [CategoryLearningRule],
        stores: [SeedData.StoreDefinition]
    ) -> [ParsedItemInput] {
        let decomposed = segments.map { segment -> (itemText: String, phrase: StoreDetectionService.StorePhrase) in
            let phrase = StoreDetectionService.parseStorePhrase(segment, stores: stores)
            return (phrase.cleanText, phrase)
        }

        let storeIndices = decomposed.enumerated().compactMap { index, item in
            item.phrase.hasStore ? index : nil
        }

        let sharedStorePhrase: StoreDetectionService.StorePhrase? = {
            guard decomposed.count > 1,
                  storeIndices.count == 1,
                  storeIndices[0] == decomposed.count - 1 else {
                return nil
            }
            return decomposed.last?.phrase
        }()

        return decomposed.map { item in
            let phrase: StoreDetectionService.StorePhrase
            if item.phrase.hasStore {
                phrase = item.phrase
            } else if let sharedStorePhrase {
                phrase = sharedStorePhrase
            } else {
                phrase = item.phrase
            }

            return ItemInputParser.parse(
                itemText: item.itemText,
                storePhrase: phrase,
                learningRules: learningRules,
                stores: stores
            )
        }
    }
}
