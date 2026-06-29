import XCTest
@testable import GroceryList

final class QuantityParserServiceTests: XCTestCase {
    func testPrefixXPattern() {
        let result = QuantityParserService.parse("2x milk")
        XCTAssertEqual(result.quantityValue, 2)
        XCTAssertNil(result.quantityText)
        XCTAssertEqual(result.itemText, "milk")
    }

    func testXPrefixPattern() {
        let result = QuantityParserService.parse("x2 milk")
        XCTAssertEqual(result.quantityValue, 2)
        XCTAssertEqual(result.itemText, "milk")
    }

    func testSuffixXPattern() {
        let result = QuantityParserService.parse("milk x2")
        XCTAssertEqual(result.quantityValue, 2)
        XCTAssertEqual(result.itemText, "milk")
    }

    func testLeadingNumberPattern() {
        let result = QuantityParserService.parse("2 milk")
        XCTAssertEqual(result.quantityValue, 2)
        XCTAssertEqual(result.itemText, "milk")
    }

    func testTrailingNumberPattern() {
        let result = QuantityParserService.parse("milk 2")
        XCTAssertEqual(result.quantityValue, 2)
        XCTAssertEqual(result.itemText, "milk")
    }

    func testSingleQuantityIsNotStoredAsValue() {
        let result = QuantityParserService.parse("milk")
        XCTAssertNil(result.quantityValue)
        XCTAssertEqual(result.itemText, "milk")
    }

    func testLeadingOneIsNotQuantity() {
        let result = QuantityParserService.parse("1 milk")
        XCTAssertNil(result.quantityValue)
        XCTAssertEqual(result.itemText, "1 milk")
    }

    func testUnitPoundPattern() {
        let result = QuantityParserService.parse("2 lb chicken")
        XCTAssertEqual(result.quantityValue, 2)
        XCTAssertEqual(result.quantityText, "2 lb")
        XCTAssertEqual(result.itemText, "chicken")
    }

    func testUnitPackPattern() {
        let result = QuantityParserService.parse("1 pack eggs")
        XCTAssertNil(result.quantityValue)
        XCTAssertEqual(result.quantityText, "1 pack")
        XCTAssertEqual(result.itemText, "eggs")
    }

    func testAttachedGramPattern() {
        let result = QuantityParserService.parse("500g rice")
        XCTAssertEqual(result.quantityValue, 500)
        XCTAssertEqual(result.quantityText, "500g")
        XCTAssertEqual(result.itemText, "rice")
    }

    func testDozenPattern() {
        let result = QuantityParserService.parse("1 dozen eggs")
        XCTAssertNil(result.quantityValue)
        XCTAssertEqual(result.quantityText, "1 dozen")
        XCTAssertEqual(result.itemText, "eggs")
    }
}
