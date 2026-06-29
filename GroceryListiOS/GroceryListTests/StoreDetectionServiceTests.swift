import XCTest
@testable import GroceryList

final class StoreDetectionServiceTests: XCTestCase {
    private let stores: [SeedData.StoreDefinition] = [
        .init(id: "costco", label: "Costco", domain: "costco.com", color: "#e31837"),
        .init(id: "walmart", label: "Walmart", domain: "walmart.com", color: "#0071dc"),
        .init(id: "hmart", label: "H Mart", domain: "hmart.com", color: "#e12229"),
        .init(id: "traderjoes", label: "Trader Joe's", domain: "traderjoes.com", color: "#ba2026"),
        .init(id: "wholefoods", label: "Whole Foods Market", domain: "wholefoodsmarket.com", color: "#00674b"),
    ]

    func testParseStoreTagExtractsQuery() {
        let tag = StoreDetectionService.parseStoreTag("milk @cost")
        XCTAssertEqual(tag.query, "cost")
        XCTAssertEqual(tag.cleanText, "milk")
    }

    func testParseStoreTagWithoutTagReturnsOriginal() {
        let tag = StoreDetectionService.parseStoreTag("2 milk")
        XCTAssertNil(tag.query)
        XCTAssertEqual(tag.cleanText, "2 milk")
    }

    func testParseStorePhraseFromPreposition() {
        let phrase = StoreDetectionService.parseStorePhrase("milk from costco", stores: stores)
        XCTAssertEqual(phrase.cleanText, "milk")
        XCTAssertEqual(phrase.query, "costco")
        XCTAssertTrue(phrase.isExplicit)
    }

    func testParseStorePhraseAtPreposition() {
        let phrase = StoreDetectionService.parseStorePhrase("milk at costco", stores: stores)
        XCTAssertEqual(phrase.cleanText, "milk")
        XCTAssertEqual(phrase.query, "costco")
        XCTAssertTrue(phrase.isExplicit)
    }

    func testParseStorePhraseBareKnownStore() {
        let phrase = StoreDetectionService.parseStorePhrase("eggs 12 walmart", stores: stores)
        XCTAssertEqual(phrase.cleanText, "eggs 12")
        XCTAssertEqual(phrase.query, "walmart")
        XCTAssertFalse(phrase.isExplicit)
    }

    func testResolveExactStoreId() {
        XCTAssertEqual(StoreDetectionService.resolveStoreId(query: "costco", stores: stores), "costco")
    }

    func testResolveExactStoreLabel() {
        XCTAssertEqual(StoreDetectionService.resolveStoreId(query: "h mart", stores: stores), "hmart")
    }

    func testResolveTraderJoesAlias() {
        XCTAssertEqual(StoreDetectionService.resolveStoreId(query: "trader joes", stores: stores), "traderjoes")
    }

    func testResolveWholeFoodsAlias() {
        XCTAssertEqual(StoreDetectionService.resolveStoreId(query: "whole foods", stores: stores), "wholefoods")
    }

    func testResolvePrefixMatch() {
        XCTAssertEqual(StoreDetectionService.resolveStoreId(query: "trad", stores: stores), "traderjoes")
    }

    func testResolveEmptyQueryReturnsNil() {
        XCTAssertNil(StoreDetectionService.resolveStoreId(query: "", stores: stores))
        XCTAssertNil(StoreDetectionService.resolveStoreId(query: nil, stores: stores))
    }

    func testTitleCaseStoreLabel() {
        XCTAssertEqual(StoreDetectionService.titleCaseStoreLabel("indian store"), "Indian Store")
    }
}
