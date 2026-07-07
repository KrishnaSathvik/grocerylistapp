import Foundation
import SwiftData

enum CategoryLearningService {
    static func normalize(_ text: String) -> String {
        text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func fetchRules(context: ModelContext) -> [CategoryLearningRule] {
        let descriptor = FetchDescriptor<CategoryLearningRule>(
            sortBy: [SortDescriptor(\CategoryLearningRule.updatedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    static func record(
        normalizedName: String,
        categoryId: String,
        context: ModelContext
    ) {
        let key = normalize(normalizedName)
        guard !key.isEmpty, categoryId != "misc" else { return }

        let descriptor = FetchDescriptor<CategoryLearningRule>(
            predicate: #Predicate { $0.normalizedItemName == key }
        )

        if let existing = try? context.fetch(descriptor).first {
            existing.categoryId = categoryId
            existing.useCount += 1
            existing.updatedAt = .now
        } else {
            context.insert(
                CategoryLearningRule(
                    normalizedItemName: key,
                    categoryId: categoryId
                )
            )
        }
        PersistenceService.save(context: context, operation: "record category learning")
    }

    static func learnedCategory(
        for text: String,
        rules: [CategoryLearningRule]
    ) -> String? {
        let normalized = normalize(text)
        guard !normalized.isEmpty else { return nil }

        if let exact = rules.first(where: {
            $0.normalizedItemName == normalized && $0.categoryId != "misc"
        }) {
            return exact.categoryId
        }

        var bestRule: CategoryLearningRule?
        var bestLength = 0

        for rule in rules {
            guard rule.categoryId != "misc" else { continue }
            let learnedName = rule.normalizedItemName
            guard !learnedName.isEmpty else { continue }

            let matches = normalized.contains(learnedName) || learnedName.contains(normalized)
            guard matches, learnedName.count > bestLength else { continue }

            bestRule = rule
            bestLength = learnedName.count
        }

        return bestRule?.categoryId
    }

    static func resetAll(context: ModelContext) {
        let descriptor = FetchDescriptor<CategoryLearningRule>()
        let rules = (try? context.fetch(descriptor)) ?? []
        for rule in rules {
            context.delete(rule)
        }
        PersistenceService.save(context: context, operation: "reset category learning")
    }
}
