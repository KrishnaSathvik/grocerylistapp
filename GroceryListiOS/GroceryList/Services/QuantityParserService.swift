import Foundation

enum QuantityParserService {
    struct Result: Equatable, Sendable {
        let quantityValue: Int?
        let quantityText: String?
        let itemText: String
    }

    static func parse(_ raw: String) -> Result {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return Result(quantityValue: nil, quantityText: nil, itemText: "")
        }

        let patterns: [(String, ([String]) -> Result?)] = [
            (#"^(\d+)\s*[xX]\s+(.+)$"#, { mapIntegerQty(qty: $0[0], text: $0[1], requireRange: false) }),
            (#"^[xX](\d+)\s+(.+)$"#, { mapIntegerQty(qty: $0[0], text: $0[1], requireRange: false) }),
            (#"^(.+?)\s+[xX](\d+)$"#, { mapIntegerQty(qty: $0[1], text: $0[0], requireRange: false) }),
            (#"(?i)^(.+?)\s+qty\s+(\d+)$"#, { mapIntegerQty(qty: $0[1], text: $0[0], requireRange: false) }),
            (#"^(\d+(?:\.\d+)?)(g|kg|oz|ml|l)\s+(.+)$"#, mapAttachedUnitQty),
            (#"^(\d+(?:\.\d+)?)\s*(lb|lbs|oz|g|kg|pack|packs|dozen|bag|bags|bottle|bottles|can|cans|box|boxes)\s+(.+)$"#, mapUnitQty),
            (#"^(\d+)\s+(.+)$"#, { mapIntegerQty(qty: $0[0], text: $0[1], requireRange: true) }),
            (#"^(.+?)\s+(\d+)$"#, { mapIntegerQty(qty: $0[1], text: $0[0], requireRange: true) }),
        ]

        for (pattern, mapper) in patterns {
            if let groups = captureGroups(pattern: pattern, in: trimmed, options: [.caseInsensitive]),
               let result = mapper(groups) {
                return result
            }
        }

        return Result(quantityValue: nil, quantityText: nil, itemText: trimmed)
    }

    private static func mapIntegerQty(qty: String, text: String, requireRange: Bool) -> Result? {
        guard let value = Int(qty) else { return nil }
        if requireRange && !(value > 1 && value < 100) { return nil }
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }
        return Result(
            quantityValue: value > 1 ? value : nil,
            quantityText: nil,
            itemText: cleaned
        )
    }

    private static func mapUnitQty(_ groups: [String]) -> Result? {
        guard groups.count >= 3 else { return nil }
        let amount = groups[0]
        let unit = groups[1].lowercased()
        let rest = groups[2].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rest.isEmpty else { return nil }

        let quantityText = "\(amount) \(unit)"
        let intValue = Int(amount.split(separator: ".").first ?? "")
        return Result(
            quantityValue: intValue.flatMap { $0 > 1 ? $0 : nil },
            quantityText: quantityText,
            itemText: rest
        )
    }

    private static func mapAttachedUnitQty(_ groups: [String]) -> Result? {
        guard groups.count >= 3 else { return nil }
        let amount = groups[0]
        let unit = groups[1].lowercased()
        let rest = groups[2].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rest.isEmpty else { return nil }

        let quantityText = "\(amount)\(unit)"
        let intValue = Int(amount.split(separator: ".").first ?? "")
        return Result(
            quantityValue: intValue.flatMap { $0 > 1 ? $0 : nil },
            quantityText: quantityText,
            itemText: rest
        )
    }

    private static func captureGroups(
        pattern: String,
        in text: String,
        options: NSRegularExpression.Options = []
    ) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range), match.numberOfRanges > 1 else {
            return nil
        }

        var groups: [String] = []
        for index in 1 ..< match.numberOfRanges {
            guard let swiftRange = Range(match.range(at: index), in: text) else { return nil }
            groups.append(String(text[swiftRange]))
        }
        return groups
    }
}
