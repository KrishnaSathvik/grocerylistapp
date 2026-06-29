import Foundation

enum CategoryDetectionService {
    static func detectCategory(
        for text: String,
        keywords: [String: [String]]? = nil,
        learningRules: [CategoryLearningRule] = []
    ) -> String {
        if let learned = CategoryLearningService.learnedCategory(for: text, rules: learningRules) {
            return learned
        }
        return detectFromKeywords(for: text, keywords: keywords)
    }

    static func detectFromKeywords(
        for text: String,
        keywords: [String: [String]]? = nil
    ) -> String {
        let keywordMap = keywords
            ?? (GroceryCatalog.categoryKeywords.isEmpty ? nil : GroceryCatalog.categoryKeywords)
            ?? SeedData.loadCategories()?.keywords
            ?? [:]
        let lower = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !lower.isEmpty else { return "misc" }

        var bestCategory: String?
        var bestLength = 0

        for (categoryId, categoryKeywords) in keywordMap {
            for keyword in categoryKeywords {
                let normalizedKeyword = keyword.lowercased()
                guard lower == normalizedKeyword || lower.contains(normalizedKeyword) else { continue }
                if normalizedKeyword.count > bestLength {
                    bestCategory = categoryId
                    bestLength = normalizedKeyword.count
                }
            }
        }

        return bestCategory ?? "misc"
    }
}
