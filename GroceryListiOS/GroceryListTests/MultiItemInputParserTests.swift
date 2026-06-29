import XCTest
@testable import GroceryList

final class MultiItemInputParserTests: XCTestCase {
    private let stores: [SeedData.StoreDefinition] = [
        .init(id: "costco", label: "Costco", domain: "costco.com", color: "#e31837"),
        .init(id: "walmart", label: "Walmart", domain: "walmart.com", color: "#0071dc"),
        .init(id: "traderjoes", label: "Trader Joe's", domain: "traderjoes.com", color: "#ba2026"),
        .init(id: "wholefoods", label: "Whole Foods Market", domain: "wholefoodsmarket.com", color: "#00674b"),
        .init(id: "hmart", label: "H Mart", domain: "hmart.com", color: "#e12229"),
    ]

    func testTwoItemsWithDifferentStores() {
        let items = MultiItemInputParser.parse(
            "eggs 2 from walmart and milk from costco",
            stores: stores
        )

        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].name, "eggs")
        XCTAssertEqual(items[0].quantityValue, 2)
        XCTAssertEqual(items[0].storeId, "walmart")
        XCTAssertEqual(items[1].name, "milk")
        XCTAssertNil(items[1].quantityValue)
        XCTAssertEqual(items[1].storeId, "costco")
    }

    func testCommaSeparatedItems() {
        let items = MultiItemInputParser.parse(
            "2 eggs from walmart, milk from costco",
            stores: stores
        )

        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].name, "eggs")
        XCTAssertEqual(items[0].quantityValue, 2)
        XCTAssertEqual(items[0].storeId, "walmart")
        XCTAssertEqual(items[1].name, "milk")
        XCTAssertEqual(items[1].storeId, "costco")
    }

    func testSharedTrailingStore() {
        let items = MultiItemInputParser.parse(
            "eggs and milk from costco",
            stores: stores
        )

        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].name, "eggs")
        XCTAssertEqual(items[0].storeId, "costco")
        XCTAssertEqual(items[1].name, "milk")
        XCTAssertEqual(items[1].storeId, "costco")
    }

    func testTraderJoesAlias() {
        let items = MultiItemInputParser.parse(
            "bread from trader joes",
            stores: stores
        )

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].name, "bread")
        XCTAssertEqual(items[0].storeId, "traderjoes")
    }

    func testAtStoreShortcut() {
        let parsed = ItemInputParser.parse("milk @costco", stores: stores)

        XCTAssertEqual(parsed.name, "milk")
        XCTAssertEqual(parsed.storeId, "costco")
    }

    func testCustomStoreFromExplicitPhrase() {
        let parsed = ItemInputParser.parse("milk from indian store", stores: stores)

        XCTAssertEqual(parsed.name, "milk")
        XCTAssertNil(parsed.storeId)
        XCTAssertEqual(parsed.customStoreLabel, "Indian Store")
    }

    func testBareKnownStore() {
        let parsed = ItemInputParser.parse("milk costco", stores: stores)

        XCTAssertEqual(parsed.name, "milk")
        XCTAssertEqual(parsed.storeId, "costco")
        XCTAssertNil(parsed.customStoreLabel)
    }

    func testDoesNotCreateAmbiguousCustomStore() {
        let parsed = ItemInputParser.parse("milk indian", stores: stores)

        XCTAssertEqual(parsed.name, "milk indian")
        XCTAssertNil(parsed.storeId)
        XCTAssertNil(parsed.customStoreLabel)
    }

    func testQuantityOnly() {
        let parsed = ItemInputParser.parse("bananas 6", stores: stores)

        XCTAssertEqual(parsed.name, "bananas")
        XCTAssertEqual(parsed.quantityValue, 6)
    }

    func testCustomStoreFromLocalMarket() {
        let parsed = ItemInputParser.parse("random thing from local market", stores: stores)

        XCTAssertEqual(parsed.name, "random thing")
        XCTAssertEqual(parsed.customStoreLabel, "Local Market")
    }

    func testNewlineSeparatedItems() {
        let items = MultiItemInputParser.parse(
            """
            eggs from walmart
            milk from costco
            bread from trader joes
            """,
            stores: stores
        )

        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(items[0].storeId, "walmart")
        XCTAssertEqual(items[1].storeId, "costco")
        XCTAssertEqual(items[2].storeId, "traderjoes")
    }

    func testEmptyInputReturnsEmptyArray() {
        XCTAssertTrue(MultiItemInputParser.parse("", stores: stores).isEmpty)
        XCTAssertTrue(MultiItemInputParser.parse("   ", stores: stores).isEmpty)
    }

    func testQtyPattern() {
        let parsed = ItemInputParser.parse("eggs qty 2", stores: stores)

        XCTAssertEqual(parsed.name, "eggs")
        XCTAssertEqual(parsed.quantityValue, 2)
    }
}
