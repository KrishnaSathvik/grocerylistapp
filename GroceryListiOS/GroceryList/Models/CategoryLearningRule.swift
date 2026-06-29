import Foundation
import SwiftData

@Model
final class CategoryLearningRule {
    @Attribute(.unique) var normalizedItemName: String
    var categoryId: String
    var useCount: Int
    var updatedAt: Date

    init(
        normalizedItemName: String,
        categoryId: String,
        useCount: Int = 1,
        updatedAt: Date = .now
    ) {
        self.normalizedItemName = normalizedItemName
        self.categoryId = categoryId
        self.useCount = useCount
        self.updatedAt = updatedAt
    }
}
