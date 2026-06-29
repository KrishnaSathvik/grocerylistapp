import XCTest
@testable import GroceryList

final class CategoryLearningServiceTests: XCTestCase {
    private let sampleKeywords: [String: [String]] = [
        "dairy": ["milk", "paneer"],
        "pantry": ["rice", "basmati"],
    ]

    private func makeRule(name: String, categoryId: String) -> CategoryLearningRule {
        CategoryLearningRule(normalizedItemName: name, categoryId: categoryId)
    }

    func testExactLearnedRuleOverridesKeywords() {
        let rules = [makeRule(name: "milk", categoryId: "pantry")]

        let category = CategoryDetectionService.detectCategory(
            for: "milk",
            keywords: sampleKeywords,
            learningRules: rules
        )

        XCTAssertEqual(category, "pantry")
    }

    func testPartialLearnedRuleMatchesContainedName() {
        let rules = [makeRule(name: "oat", categoryId: "pantry")]

        let category = CategoryDetectionService.detectCategory(
            for: "oat milk",
            keywords: sampleKeywords,
            learningRules: rules
        )

        XCTAssertEqual(category, "pantry")
    }

    func testLongestPartialLearnedRuleWins() {
        let rules = [
            makeRule(name: "oat", categoryId: "misc"),
            makeRule(name: "oat milk", categoryId: "pantry"),
        ]

        let category = CategoryDetectionService.detectCategory(
            for: "oat milk",
            keywords: sampleKeywords,
            learningRules: rules
        )

        XCTAssertEqual(category, "pantry")
    }

    func testUnknownItemFallsBackToKeywordsWithoutRules() {
        let category = CategoryDetectionService.detectCategory(
            for: "paneer",
            keywords: sampleKeywords,
            learningRules: []
        )

        XCTAssertEqual(category, "dairy")
    }

    func testLearnedCategoryExactMatch() {
        let rules = [makeRule(name: "widget", categoryId: "produce")]

        XCTAssertEqual(
            CategoryLearningService.learnedCategory(for: "widget", rules: rules),
            "produce"
        )
    }

    func testLearnedCategoryReturnsNilWhenNoMatch() {
        let rules = [makeRule(name: "widget", categoryId: "produce")]

        XCTAssertNil(CategoryLearningService.learnedCategory(for: "gadget", rules: rules))
    }

    func testItemInputParserUsesLearningRules() {
        let rules = [makeRule(name: "milk", categoryId: "pantry")]

        let parsed = ItemInputParser.parse("2 milk", learningRules: rules)

        XCTAssertEqual(parsed.categoryId, "pantry")
    }
}
