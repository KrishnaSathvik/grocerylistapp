import XCTest
@testable import GroceryList

final class ListCodecTests: XCTestCase {
    private let webFixtureBase64 = "W3sidCI6Im1pbGsiLCJxIjoyLCJjIjoiZGFpcnkiLCJzIjoiY29zdGNvIn0seyJ0IjoiZWdncyIsImMiOiJkYWlyeSIsImsiOjF9XQ=="
    private let webFixtureURL = "https://grocerylistapp.vercel.app/#import=W3sidCI6Im1pbGsiLCJxIjoyLCJjIjoiZGFpcnkiLCJzIjoiY29zdGNvIn0seyJ0IjoiZWdncyIsImMiOiJkYWlyeSIsImsiOjF9XQ=="

    func testDecodeWebFixtureFromBase64() {
        let items = ListCodec.decode(webFixtureBase64)
        XCTAssertEqual(items?.count, 2)

        let milk = items?.first
        XCTAssertEqual(milk?.name, "milk")
        XCTAssertEqual(milk?.quantityValue, 2)
        XCTAssertEqual(milk?.categoryId, "dairy")
        XCTAssertEqual(milk?.storeId, "costco")
        XCTAssertFalse(milk?.isCompleted ?? true)

        let eggs = items?.last
        XCTAssertEqual(eggs?.name, "eggs")
        XCTAssertNil(eggs?.quantityValue)
        XCTAssertEqual(eggs?.categoryId, "dairy")
        XCTAssertTrue(eggs?.isCompleted ?? false)
    }

    func testDecodeWebFixtureFromFullURL() {
        let items = ListCodec.parseImportPayload(from: webFixtureURL)
        XCTAssertEqual(items?.count, 2)
        XCTAssertEqual(items?.first?.name, "milk")
    }

    func testEncodeDecodeRoundTrip() {
        let list = GroceryList(name: "Test")
        let items = [
            GroceryItem(name: "paneer", quantityValue: 2, categoryId: "dairy", storeId: "hmart"),
            GroceryItem(name: "widget", categoryId: "misc", isCompleted: true),
        ]
        list.items = items

        guard let encoded = ListCodec.encode(items: list.items) else {
            XCTFail("Expected encoded payload")
            return
        }

        let decoded = ListCodec.decode(encoded)
        XCTAssertEqual(decoded?.count, 2)
        XCTAssertEqual(decoded?.first?.name, "paneer")
        XCTAssertEqual(decoded?.first?.quantityValue, 2)
        XCTAssertEqual(decoded?.first?.categoryId, "dairy")
        XCTAssertEqual(decoded?.first?.storeId, "hmart")
        XCTAssertEqual(decoded?.last?.name, "widget")
        XCTAssertEqual(decoded?.last?.categoryId, "misc")
        XCTAssertTrue(decoded?.last?.isCompleted ?? false)
    }

    func testEncodeReturnsNilWhenOverLimit() {
        let items = (0..<51).map { index in
            GroceryItem(name: "Item \(index)")
        }
        XCTAssertNil(ListCodec.encode(items: items))
    }

    func testShareURLUsesWebBaseAndFragment() {
        let items = [GroceryItem(name: "milk", categoryId: "dairy")]
        guard let url = ListCodec.shareURL(for: items) else {
            XCTFail("Expected share URL")
            return
        }
        XCTAssertTrue(url.absoluteString.hasPrefix(ListCodec.shareBaseURL))
        XCTAssertTrue(url.absoluteString.contains("#import="))
    }

    func testShareCodeRoundTrip() {
        let list = GroceryList(name: "Weekly Groceries")
        list.items = [
            GroceryItem(name: "milk", quantityValue: 2, categoryId: "dairy"),
            GroceryItem(name: "eggs", categoryId: "dairy", isCompleted: true),
        ]

        guard let code = ListCodec.shareCode(for: list) else {
            XCTFail("Expected share code")
            return
        }

        XCTAssertTrue(code.hasPrefix(ListCodec.sharedPayloadPrefix))

        guard let parsed = ListCodec.parseSharedList(from: code) else {
            XCTFail("Expected parsed shared list")
            return
        }

        XCTAssertEqual(parsed.listName, "Weekly Groceries")
        XCTAssertEqual(parsed.items.count, 2)
        XCTAssertEqual(parsed.items.first?.name, "milk")
    }
}
