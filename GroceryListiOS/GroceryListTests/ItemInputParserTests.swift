import XCTest
@testable import GroceryList

final class ItemInputParserTests: XCTestCase {
    func testCombinedQuantityStoreAndCategory() {
        let parsed = ItemInputParser.parse("2 lb chicken @costco")

        XCTAssertEqual(parsed.name, "chicken")
        XCTAssertEqual(parsed.quantityText, "2 lb")
        XCTAssertEqual(parsed.quantityValue, 2)
        XCTAssertEqual(parsed.storeId, "costco")
        XCTAssertEqual(parsed.categoryId, "meat")
        XCTAssertNil(parsed.customStoreLabel)
    }

    func testIntegerQuantityWithStoreTag() {
        let parsed = ItemInputParser.parse("2 milk @hmart")

        XCTAssertEqual(parsed.name, "milk")
        XCTAssertEqual(parsed.quantityValue, 2)
        XCTAssertEqual(parsed.storeId, "hmart")
        XCTAssertEqual(parsed.categoryId, "dairy")
    }

    func testNaturalLanguageStorePhrase() {
        let stores: [SeedData.StoreDefinition] = [
            .init(id: "walmart", label: "Walmart", domain: "walmart.com", color: "#0071dc"),
        ]
        let parsed = ItemInputParser.parse("milk from walmart", stores: stores)

        XCTAssertEqual(parsed.name, "milk")
        XCTAssertEqual(parsed.storeId, "walmart")
    }

    func testAtStoreShortcutRemainsBackwardCompatible() {
        let stores: [SeedData.StoreDefinition] = [
            .init(id: "costco", label: "Costco", domain: "costco.com", color: "#e31837"),
        ]
        let parsed = ItemInputParser.parse("milk @costco", stores: stores)

        XCTAssertEqual(parsed.name, "milk")
        XCTAssertEqual(parsed.storeId, "costco")
        XCTAssertNil(parsed.customStoreLabel)
    }
}
