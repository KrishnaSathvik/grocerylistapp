import XCTest
@testable import GroceryList

final class ListCodecTests: XCTestCase {
    private let webFixtureBase64 = "W3sidCI6Im1pbGsiLCJxIjoyLCJjIjoiZGFpcnkiLCJzIjoiY29zdGNvIn0seyJ0IjoiZWdncyIsImMiOiJkYWlyeSIsImsiOjF9XQ=="
    private let webFixtureURL = "https://smartgrocerylists.app/app/#import=W3sidCI6Im1pbGsiLCJxIjoyLCJjIjoiZGFpcnkiLCJzIjoiY29zdGNvIn0seyJ0IjoiZWdncyIsImMiOiJkYWlyeSIsImsiOjF9XQ=="

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

    func testShareURLUsesWebBaseAndQueryParam() {
        let items = [GroceryItem(name: "milk", categoryId: "dairy")]
        guard let url = ListCodec.shareURL(for: items) else {
            XCTFail("Expected share URL")
            return
        }
        XCTAssertEqual(url.host, ListCodec.shareHost)
        XCTAssertEqual(url.path, ListCodec.sharePath)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        XCTAssertNotNil(components?.queryItems?.first(where: { $0.name == ListCodec.importQueryKey })?.value)
    }

    func testDecodeWebFixtureFromQueryURL() {
        let url = "https://smartgrocerylists.app/app?import=\(webFixtureBase64)"
        let items = ListCodec.parseImportPayload(from: url)
        XCTAssertEqual(items?.count, 2)
        XCTAssertEqual(items?.first?.name, "milk")
    }

    func testParseSharedListFindsURLInsidePastedMessage() {
        let message = """
        Weekly Groceries
        Tuesday, July 7

        Walmart:
          ☐ milk

        https://smartgrocerylists.app/app?import=\(webFixtureBase64)
        """
        let parsed = ListCodec.parseSharedList(from: message)
        XCTAssertEqual(parsed?.items.count, 2)
        XCTAssertEqual(parsed?.items.first?.name, "milk")
    }

    func testSharePayloadTextUsesShareLink() {
        let list = GroceryList(name: "Weekly Groceries")
        list.items = [
            GroceryItem(name: "milk", quantityValue: 2, categoryId: "dairy", storeId: "walmart"),
        ]

        guard let payload = ListCodec.sharePayloadText(for: list) else {
            XCTFail("Expected share payload")
            return
        }

        XCTAssertTrue(payload.hasPrefix("https://"))
        XCTAssertTrue(payload.contains("import="))
        let parsed = ListCodec.parseImportPayload(from: payload)
        XCTAssertEqual(parsed?.first?.name, "milk")
        XCTAssertEqual(parsed?.first?.storeId, "walmart")
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

    func testInvalidSharedListTextReturnsNil() {
        XCTAssertNil(ListCodec.parseSharedList(from: "this is not a shared list code"))
    }

    func testParsePlainTextListWithBracketCheckboxes() {
        let text = """
        Weekly Groceries
        [ ] milk
        [ ] eggs
        [ ] butter
        [ ] chicken
        """

        let parsed = ListCodec.parseSharedList(from: text)
        XCTAssertEqual(parsed?.listName, "Weekly Groceries")
        XCTAssertEqual(parsed?.items.map(\.name), ["milk", "eggs", "butter", "chicken"])
    }

    func testParsePlainTextListFromCopyAsTextFormat() {
        let text = """
        Weekly Groceries

        ☐ milk
        ☐ 2 lb rice
        ☐ eggs
        """

        let parsed = PlainTextListParser.parse(text)
        XCTAssertEqual(parsed?.listName, "Weekly Groceries")
        XCTAssertEqual(parsed?.items.count, 3)
        XCTAssertEqual(parsed?.items.first?.name, "milk")
        XCTAssertEqual(parsed?.items[1].name, "rice")
        XCTAssertEqual(parsed?.items[1].quantityText, "2 lb")
    }

    func testParsePlainTextListPreservesStoreSections() {
        let text = """
        Weekly Groceries

        Costco:
          ☐ eggs
          ☐ buttermilk
        Walmart:
          ☐ chicken
        """

        let parsed = PlainTextListParser.parse(text)
        XCTAssertEqual(parsed?.listName, "Weekly Groceries")
        XCTAssertEqual(parsed?.items.count, 3)
        XCTAssertEqual(parsed?.items[0].name, "eggs")
        XCTAssertEqual(parsed?.items[0].storeId, "costco")
        XCTAssertEqual(parsed?.items[1].storeId, "costco")
        XCTAssertEqual(parsed?.items[2].name, "chicken")
        XCTAssertEqual(parsed?.items[2].storeId, "walmart")
    }

    @MainActor
    func testShareCodeImportPreservesTextQuantityAndNotes() throws {
        let list = GroceryList(name: "Pantry Run")
        let rice = GroceryItem(
            name: "rice",
            quantityText: "2 lb",
            categoryId: "pantry",
            storeId: "costco",
            notes: "basmati preferred"
        )
        list.items = [rice]

        guard let code = ListCodec.shareCode(for: list),
              let parsed = ListCodec.parseSharedList(from: code) else {
            XCTFail("Expected parsed share code")
            return
        }

        let container = try ModelContainerSetup.makeContainer(inMemory: true)
        let context = container.mainContext
        let importedList = GroceryList(name: "Imported")
        context.insert(importedList)

        ListImportService.replaceItems(parsed.items, in: importedList, context: context)

        let imported = try XCTUnwrap(importedList.items.first)
        XCTAssertEqual(imported.name, "rice")
        XCTAssertNil(imported.quantityValue)
        XCTAssertEqual(imported.quantityText, "2 lb")
        XCTAssertEqual(imported.notes, "basmati preferred")
        XCTAssertEqual(imported.categoryId, "pantry")
        XCTAssertEqual(imported.storeId, "costco")
        XCTAssertFalse(imported.isCompleted)
    }

    func testShareMessageUsesNaturalSenderVoice() {
        XCTAssertEqual(
            ShareLinkService.shareMessage(for: "Weekly Groceries"),
            "Here's my grocery list — Weekly Groceries"
        )
        XCTAssertFalse(
            ShareLinkService.shareMessage(for: "Weekly Groceries").contains("was shared with you")
        )
    }

    func testShareActivityItemsIncludeURLSeparately() {
        let url = URL(string: "https://smartgrocerylists.app/s/AbC123")!
        let items = ShareLinkService.shareActivityItems(for: "Weekly Groceries", url: url)
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0] as? String, "Here's my grocery list — Weekly Groceries")
        XCTAssertEqual(items[1] as? URL, url)
    }
}
