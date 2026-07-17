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
        // Bare/alias matches may surface the store display label; resolution is case-insensitive.
        XCTAssertEqual(phrase.query?.lowercased(), "walmart")
        XCTAssertFalse(phrase.isExplicit)
        XCTAssertEqual(
            StoreDetectionService.resolveStoreId(query: phrase.query, stores: stores),
            "walmart"
        )
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

    func testResolveHEBAlias() {
        let extendedStores = stores + [.init(id: "heb", label: "H-E-B", domain: "heb.com", color: "#ee1c2e")]
        XCTAssertEqual(StoreDetectionService.resolveStoreId(query: "heb", stores: extendedStores), "heb")
        XCTAssertEqual(StoreDetectionService.resolveStoreId(query: "h e b", stores: extendedStores), "heb")
    }

    func testParseBarePanAsiaAlias() {
        let extendedStores = stores + [.init(id: "panasia", label: "Pan Asia Supermarket", domain: "panasia.com", color: "#c62828")]
        let phrase = StoreDetectionService.parseStorePhrase("chicken pan asia", stores: extendedStores)
        XCTAssertEqual(phrase.cleanText, "chicken")
        XCTAssertEqual(phrase.query, "Pan Asia")
        XCTAssertEqual(StoreDetectionService.resolveStoreId(query: phrase.query, stores: extendedStores), "panasia")
    }

    func testParseBareSamsClubAlias() {
        let extendedStores = stores + [.init(id: "samsclub", label: "Sam's Club", domain: "samsclub.com", color: "#0060a9")]
        let phrase = StoreDetectionService.parseStorePhrase("paper towels sams club", stores: extendedStores)
        XCTAssertEqual(phrase.cleanText, "paper towels")
        XCTAssertEqual(StoreDetectionService.resolveStoreId(query: "sams", stores: extendedStores), "samsclub")
    }

    func testTitleCaseStoreLabel() {
        XCTAssertEqual(StoreDetectionService.titleCaseStoreLabel("indian store"), "Indian Store")
    }

    func testDefaultStoreIdFromCostcoRun() {
        XCTAssertEqual(
            StoreDetectionService.defaultStoreId(forListName: "Costco Run", stores: stores),
            "costco"
        )
    }

    func testDefaultStoreIdFromWalmartList() {
        XCTAssertEqual(
            StoreDetectionService.defaultStoreId(forListName: "Walmart List", stores: stores),
            "walmart"
        )
    }

    func testDefaultStoreIdIgnoresGenericListNames() {
        XCTAssertNil(
            StoreDetectionService.defaultStoreId(forListName: "Weekly Groceries", stores: stores)
        )
    }
}
