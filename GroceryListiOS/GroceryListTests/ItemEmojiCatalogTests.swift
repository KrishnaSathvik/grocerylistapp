import XCTest
@testable import GroceryList

final class ItemEmojiCatalogTests: XCTestCase {
    func testExactMatchMilk() {
        XCTAssertEqual(ItemEmojiCatalog.emoji(for: "milk"), "🥛")
    }

    func testPartialMatchChickenBreast() {
        XCTAssertEqual(ItemEmojiCatalog.emoji(for: "organic chicken breast"), "🍗")
    }

    func testGochujangMatch() {
        XCTAssertEqual(ItemEmojiCatalog.emoji(for: "gochujang"), "🌶️")
    }

    func testUnknownReturnsNil() {
        XCTAssertNil(ItemEmojiCatalog.emoji(for: "xyzzyunknown"))
    }
}
