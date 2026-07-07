import Foundation

enum PlainTextListParser {
    private static let itemLinePattern = #"^\s*(?:☐|☑|✓|✔|\[ \]|\[x\]|\[X\]|\[✓\]|-|\*|•)\s+(.+)$"#
    private static let storeHeaderPattern = #"^(.+?):\s*$"#

    private static let skippedLinePatterns: [String] = [
        #"^groceries\s*[—-]\s*smart lists$"#,
        #"^\d+\s+items?\s+(remaining|selected)$"#,
        #"^don't have the app\??$"#,
        #"^get groceries"#,
        #"^https?://"#,
        #"^apps\.apple\.com"#,
        #"^—+$"#,
        #"^-+$"#,
        #"^[A-Za-z]+day,\s+[A-Za-z]+\s+\d{1,2}$"#,
    ]

    static func parse(_ raw: String) -> ParsedSharedList? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.contains("smartgrocerylists.app") || trimmed.hasPrefix("GLIST1:") {
            return nil
        }

        let lines = trimmed.components(separatedBy: .newlines)
        var listName: String?
        var items: [ImportedListItem] = []
        var inCompletedSection = false
        var currentStoreId: String?

        let itemRegex = try? NSRegularExpression(pattern: itemLinePattern, options: [])
        let storeHeaderRegex = try? NSRegularExpression(pattern: storeHeaderPattern, options: [])
        let skippedRegexes = skippedLinePatterns.compactMap { try? NSRegularExpression(pattern: $0, options: [.caseInsensitive]) }
        let stores = SeedData.loadStoreDefinitions()

        for line in lines {
            let cleaned = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleaned.isEmpty else { continue }

            if isSkippedLine(cleaned, regexes: skippedRegexes) {
                continue
            }

            if cleaned.compare("Picked up:", options: .caseInsensitive) == .orderedSame {
                inCompletedSection = true
                currentStoreId = nil
                continue
            }

            if let storeHeader = matchStoreHeader(cleaned, regex: storeHeaderRegex) {
                inCompletedSection = false
                currentStoreId = resolveStoreId(forHeader: storeHeader, stores: stores)
                continue
            }

            if let itemText = matchItemLine(cleaned, regex: itemRegex) {
                let quantity = QuantityParserService.parse(itemText)
                let categoryId = CategoryDetectionService.detectCategory(for: quantity.itemText)
                items.append(
                    ImportedListItem(
                        name: quantity.itemText,
                        quantityValue: quantity.quantityValue,
                        quantityText: quantity.quantityText,
                        categoryId: categoryId,
                        storeId: inCompletedSection ? nil : currentStoreId,
                        isCompleted: inCompletedSection
                    )
                )
                continue
            }

            if listName == nil, !cleaned.hasPrefix("☐"), !cleaned.hasPrefix("[") {
                listName = cleaned
            }
        }

        guard !items.isEmpty else { return nil }
        return ParsedSharedList(listName: listName, items: items)
    }

    private static func isSkippedLine(_ line: String, regexes: [NSRegularExpression]) -> Bool {
        let range = NSRange(line.startIndex..., in: line)
        return regexes.contains { $0.firstMatch(in: line, range: range) != nil }
    }

    private static func matchItemLine(_ line: String, regex: NSRegularExpression?) -> String? {
        guard let regex,
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              let capture = Range(match.range(at: 1), in: line) else {
            return nil
        }
        let text = String(line[capture]).trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }

    private static func matchStoreHeader(_ line: String, regex: NSRegularExpression?) -> String? {
        guard let regex,
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              let capture = Range(match.range(at: 1), in: line) else {
            return nil
        }
        let label = String(line[capture]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !label.isEmpty else { return nil }
        if label.compare("Picked up", options: .caseInsensitive) == .orderedSame {
            return nil
        }
        return label
    }

    private static func resolveStoreId(
        forHeader label: String,
        stores: [SeedData.StoreDefinition]
    ) -> String? {
        if label.compare("Other", options: .caseInsensitive) == .orderedSame {
            return nil
        }
        return StoreDetectionService.resolveStoreId(query: label, stores: stores)
    }
}
