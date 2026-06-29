import Foundation

enum ItemEmojiCatalog {
    private struct Entry: Codable {
        let keyword: String
        let emoji: String
    }

    private static let entries: [Entry] = loadEntries()

    static func emoji(for text: String) -> String? {
        let lower = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !lower.isEmpty else { return nil }

        if let exact = entries.first(where: { $0.keyword == lower }) {
            return exact.emoji
        }

        var best: Entry?
        for entry in entries {
            let keyword = entry.keyword
            guard lower.contains(keyword) || keyword.contains(lower) else { continue }
            if best == nil || keyword.count > best!.keyword.count {
                best = entry
            }
        }
        return best?.emoji
    }

    private static func loadEntries() -> [Entry] {
        guard let url = Bundle.main.url(forResource: "item_emoji_map", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Entry].self, from: data) else {
            return []
        }
        return decoded
    }
}
