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

        if let exact = bestExactMatch(nameTokens: nameTokens, keywordMap: keywordMap) {
            return exact
        }

        if let productCategory = bestFuzzyProductMatch(nameTokens: nameTokens) {
            return productCategory
        }

        return bestFuzzyKeywordMatch(nameTokens: nameTokens, keywordMap: keywordMap) ?? "misc"
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

    // MARK: - Private

    private struct MatchCandidate: Comparable {
        let categoryId: String
        let keywordLength: Int
        let editDistance: Int

        static func < (lhs: MatchCandidate, rhs: MatchCandidate) -> Bool {
            if lhs.keywordLength != rhs.keywordLength {
                return lhs.keywordLength < rhs.keywordLength
            }
            if lhs.editDistance != rhs.editDistance {
                return lhs.editDistance > rhs.editDistance
            }
            return lhs.categoryId > rhs.categoryId
        }
    }

    private static func bestExactMatch(
        nameTokens: [String],
        keywordMap: [String: [String]]
    ) -> String? {
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

        return bestCategory
    }

    private static func bestFuzzyProductMatch(nameTokens: [String]) -> String? {
        var best: MatchCandidate?

        for product in GroceryCatalog.products {
            for keyword in product.keywords {
                guard let distance = fuzzyPhraseDistance(nameTokens: nameTokens, keyword: keyword) else { continue }
                let candidate = MatchCandidate(
                    categoryId: product.categoryId,
                    keywordLength: keyword.count,
                    editDistance: distance
                )
                if best == nil || candidate > best! {
                    best = candidate
                }
            }
        }

        return best?.categoryId
    }

    private static func bestFuzzyKeywordMatch(
        nameTokens: [String],
        keywordMap: [String: [String]]
    ) -> String? {
        var best: MatchCandidate?

        for (categoryId, categoryKeywords) in keywordMap {
            for keyword in categoryKeywords {
                guard let distance = fuzzyPhraseDistance(nameTokens: nameTokens, keyword: keyword) else { continue }
                let candidate = MatchCandidate(
                    categoryId: categoryId,
                    keywordLength: keyword.count,
                    editDistance: distance
                )
                if best == nil || candidate > best! {
                    best = candidate
                }
            }
        }

        return best?.categoryId
    }

    static func productFuzzyPhraseDistance(nameTokens: [String], keyword: String) -> Int? {
        fuzzyPhraseDistance(nameTokens: nameTokens, keyword: keyword)
    }

    private static func fuzzyPhraseDistance(nameTokens: [String], keyword: String) -> Int? {
        let keywordTokens = tokens(in: keyword)
        guard !keywordTokens.isEmpty, keywordTokens.count <= nameTokens.count else { return nil }

        let maxStart = nameTokens.count - keywordTokens.count
        var bestDistance: Int?

        for start in 0...maxStart {
            var phraseDistance = 0
            var phraseMatches = true

            for index in 0..<keywordTokens.count {
                let nameToken = nameTokens[start + index]
                let keywordToken = keywordTokens[index]

                if nameToken == keywordToken {
                    continue
                }

                guard let tokenDistance = fuzzyTokenDistance(nameToken, keywordToken) else {
                    phraseMatches = false
                    break
                }
                phraseDistance += tokenDistance
            }

            guard phraseMatches else { continue }
            bestDistance = min(bestDistance ?? phraseDistance, phraseDistance)
        }

        return bestDistance
    }

    private static func fuzzyTokenDistance(_ token: String, _ keyword: String) -> Int? {
        guard token.count >= 4, keyword.count >= 4 else { return nil }
        guard token.first == keyword.first else { return nil }
        guard abs(token.count - keyword.count) <= 2 else { return nil }

        let distance = levenshteinDistance(token, keyword)
        let maxLength = max(token.count, keyword.count)
        let threshold: Int
        switch maxLength {
        case ...5:
            threshold = 1
        case 6...8:
            threshold = 2
        default:
            threshold = max(2, maxLength / 4)
        }

        guard distance > 0, distance <= threshold else { return nil }
        return distance
    }

    private static func levenshteinDistance(_ lhs: String, _ rhs: String) -> Int {
        let left = Array(lhs)
        let right = Array(rhs)
        if left.isEmpty { return right.count }
        if right.isEmpty { return left.count }

        var previous = Array(0...right.count)
        var current = Array(repeating: 0, count: right.count + 1)

        for (i, leftChar) in left.enumerated() {
            current[0] = i + 1
            for (j, rightChar) in right.enumerated() {
                let insertion = previous[j + 1] + 1
                let deletion = current[j] + 1
                let substitution = previous[j] + (leftChar == rightChar ? 0 : 1)
                current[j + 1] = min(insertion, deletion, substitution)
            }
            swap(&previous, &current)
        }

        return previous[right.count]
    }
}
