import XCTest
@testable import GroceryList

final class CategoryDetectionServiceTests: XCTestCase {
    private let sampleKeywords: [String: [String]] = [
        "dairy": ["milk", "paneer", "eggs"],
        "pantry": ["rice", "basmati", "basmati rice"],
        "condiments": ["gochujang", "sriracha", "soy sauce"],
        "produce": ["banana", "bananas"],
    ]

    func testPaneerDetectsDairy() {
        XCTAssertEqual(CategoryDetectionService.detectCategory(for: "paneer", keywords: sampleKeywords), "dairy")
    }

    func testGochujangDetectsCondiments() {
        XCTAssertEqual(CategoryDetectionService.detectCategory(for: "gochujang", keywords: sampleKeywords), "condiments")
    }

    func testBasmatiDetectsPantry() {
        XCTAssertEqual(CategoryDetectionService.detectCategory(for: "basmati rice", keywords: sampleKeywords), "pantry")
    }

    func testLongestKeywordWins() {
        XCTAssertEqual(CategoryDetectionService.detectCategory(for: "basmati rice", keywords: sampleKeywords), "pantry")
    }

    func testUnknownFallsBackToMisc() {
        XCTAssertEqual(CategoryDetectionService.detectCategory(for: "widget", keywords: sampleKeywords), "misc")
    }

    func testTypoSalmonDetectsSeafood() {
        let keywords = GroceryCatalog.categoryKeywords
        guard !keywords.isEmpty else {
            XCTFail("Missing grocery catalog keywords")
            return
        }

        XCTAssertEqual(CategoryDetectionService.detectCategory(for: "salomn", keywords: keywords), "seafood")
        XCTAssertEqual(CategoryDetectionService.detectCategory(for: "buter", keywords: keywords), "dairy")
    }

    func testSimilarWordWithDifferentFirstLetterStaysMisc() {
        let keywords = GroceryCatalog.categoryKeywords
        guard !keywords.isEmpty else {
            XCTFail("Missing grocery catalog keywords")
            return
        }

        XCTAssertEqual(CategoryDetectionService.detectCategory(for: "silk", keywords: keywords), "misc")
    }

    func testSeedKeywordsDetectIndianAndAsianItems() {
        guard let keywords = SeedData.loadCategories()?.keywords else {
            XCTFail("Missing category seed data")
            return
        }

        XCTAssertEqual(CategoryDetectionService.detectCategory(for: "paneer", keywords: keywords), "dairy")
        XCTAssertEqual(CategoryDetectionService.detectCategory(for: "gochujang", keywords: keywords), "condiments")
        XCTAssertEqual(CategoryDetectionService.detectCategory(for: "basmati", keywords: keywords), "pantry")
    }
}
