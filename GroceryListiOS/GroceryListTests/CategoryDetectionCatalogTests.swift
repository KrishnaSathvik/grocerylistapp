import XCTest
@testable import GroceryList

final class CategoryDetectionCatalogTests: XCTestCase {
  private var keywords: [String: [String]] {
    GroceryCatalog.categoryKeywords
  }

  func testFloralAndCollisionFixes() {
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "flowers", keywords: keywords), "floral")
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "bouquet", keywords: keywords), "floral")
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "tulips", keywords: keywords), "floral")
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "roses", keywords: keywords), "floral")
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "rosé wine", keywords: keywords), "drinks")
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "rose wine", keywords: keywords), "drinks")
  }

  func testPantryBreakfastAndHouseholdFixes() {
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "corn flakes", keywords: keywords), "pantry")
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "frosted flakes", keywords: keywords), "pantry")
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "half-and-half", keywords: keywords), "dairy")
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "maple syrup", keywords: keywords), "pantry")
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "dishwasher pods", keywords: keywords), "household")
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "disinfecting wipes", keywords: keywords), "household")
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "baby wipes", keywords: keywords), "baby")
  }

  func testSnacksPetFrozenFixes() {
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "poop bags", keywords: keywords), "pet")
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "protein bars", keywords: keywords), "snacks")
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "gum", keywords: keywords), "snacks")
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "curry paste", keywords: keywords), "condiments")
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "tahini", keywords: keywords), "condiments")
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "smoothie blends", keywords: keywords), "frozen")
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "mozzarella sticks", keywords: keywords), "frozen")
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "veggie burgers", keywords: keywords), "frozen")
  }

  func testProduceTokensUnaffectedBySubstringCollisions() {
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "cauliflower", keywords: keywords), "produce")
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "sunflower seeds", keywords: keywords), "pantry")
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "plantain", keywords: keywords), "produce")
  }

  func testLongestPhraseAndTokenBoundaryCollisions() {
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "plant-based burger", keywords: keywords), "frozen")
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "almond milk", keywords: keywords), "drinks")
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "oat milk", keywords: keywords), "drinks")
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "soy milk", keywords: keywords), "drinks")
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "plant milk", keywords: keywords), "drinks")
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "2% milk", keywords: keywords), "dairy")
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "waffles", keywords: keywords), "bakery")
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "frozen waffles", keywords: keywords), "frozen")
    XCTAssertEqual(CategoryDetectionService.detectCategory(for: "sunflowers", keywords: keywords), "floral")
  }

  func testTokenMatcherRejectsSubstringInsideSingleToken() {
    let tokens = CategoryDetectionService.tokens(in: "plantain")
    XCTAssertFalse(CategoryDetectionService.keywordMatches(nameTokens: tokens, keyword: "plant"))
    XCTAssertTrue(CategoryDetectionService.keywordMatches(nameTokens: tokens, keyword: "plantain"))

    let cornflakes = CategoryDetectionService.tokens(in: "cornflakes")
    XCTAssertFalse(CategoryDetectionService.keywordMatches(nameTokens: cornflakes, keyword: "corn"))
    XCTAssertTrue(
      CategoryDetectionService.keywordMatches(
        nameTokens: CategoryDetectionService.tokens(in: "corn flakes"),
        keyword: "corn flakes"
      )
    )
  }

  func testFloralCategoryInCatalog() {
    XCTAssertEqual(GroceryCatalog.category(for: "floral")?.displayName, "Floral")
    XCTAssertEqual(GroceryCatalog.category(for: "floral")?.assetName, "category-floral")
    XCTAssertTrue(GroceryCatalog.defaultCategoryOrder.contains("floral"))
  }
}
