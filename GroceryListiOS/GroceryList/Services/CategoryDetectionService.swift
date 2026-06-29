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
        // Longest contiguous token-phrase match (mirrors src/detectCategory.js).
        let keywordMap = keywords
            ?? (GroceryCatalog.categoryKeywords.isEmpty ? nil : GroceryCatalog.categoryKeywords)
            ?? SeedData.loadCategories()?.keywords
            ?? [:]
        let nameTokens = tokens(in: text)
        guard !nameTokens.isEmpty else { return "misc" }

        var bestCategory: String?
        var bestLength = 0

        for (categoryId, categoryKeywords) in keywordMap {
            for keyword in categoryKeywords {
                let normalizedKeyword = keyword.lowercased()
                guard keywordMatches(nameTokens: nameTokens, keyword: normalizedKeyword) else { continue }
                if normalizedKeyword.count > bestLength {
                    bestCategory = categoryId
                    bestLength = normalizedKeyword.count
                }
            }
        }

        return bestCategory ?? "misc"
    }

    // MARK: - Token matching

    static func tokens(in value: String) -> [String] {
        value
            .lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
    }

    static func keywordMatches(nameTokens: [String], keyword: String) -> Bool {
        let keywordTokens = tokens(in: keyword)
        guard !keywordTokens.isEmpty, keywordTokens.count <= nameTokens.count else { return false }

        if keywordTokens == nameTokens {
            return true
        }

        let maxStart = nameTokens.count - keywordTokens.count
        for start in 0...maxStart {
            let candidate = Array(nameTokens[start ..< start + keywordTokens.count])
            if candidate == keywordTokens {
                return true
            }
        }
        return false
    }
}
