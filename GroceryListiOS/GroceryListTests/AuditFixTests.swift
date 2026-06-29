import XCTest
@testable import GroceryList

final class ShareTextFormatterTests: XCTestCase {
    func testPreviewLineIncludesTextQuantity() {
        let item = GroceryItem(
            name: "rice",
            quantityText: "2 lb",
            categoryId: "pantry"
        )
        XCTAssertEqual(ShareTextFormatter.previewLine(for: item), "2 lb rice")
    }

    func testFormatIncludesTextQuantity() {
        let list = GroceryList(name: "Test")
        let item = GroceryItem(
            name: "rice",
            quantityText: "2 lb",
            categoryId: "pantry",
            list: list
        )
        list.items = [item]
        let text = ShareTextFormatter.format(list: list)
        XCTAssertTrue(text.contains("2 lb rice"))
    }
}

final class AppSettingsCategoryOrderTests: XCTestCase {
    override func tearDown() {
        AppSettings.resetCategoryOrder()
        super.tearDown()
    }

    func testCategoryOrderPersists() {
        AppSettings.categoryOrder = ["asian", "produce", "dairy"]
        XCTAssertEqual(AppSettings.categoryOrder, ["asian", "produce", "dairy"])
    }

    func testResetCategoryOrderRestoresDefault() {
        AppSettings.categoryOrder = ["snacks", "produce"]
        AppSettings.resetCategoryOrder()
        XCTAssertEqual(AppSettings.categoryOrder, AppSettings.defaultCategoryOrder)
    }
}

final class GroceryItemServiceQuantityTextTests: XCTestCase {
    @MainActor
    func testUpdateItemPreservesTextQuantityWhenEditingCategory() throws {
        let container = try ModelContainerSetup.makeContainer(inMemory: true)
        let context = container.mainContext
        let list = GroceryList(name: "Test")
        context.insert(list)

        let item = GroceryItem(
            name: "rice",
            quantityText: "2 lb",
            categoryId: "pantry",
            list: list
        )
        context.insert(item)
        list.items.append(item)

        var draft = ItemEditDraft(item: item)
        draft.categoryId = "asian"
        GroceryItemService.updateItem(item, draft: draft, context: context)

        XCTAssertEqual(item.quantityText, "2 lb")
        XCTAssertNil(item.quantityValue)
        XCTAssertEqual(item.categoryId, "asian")
    }
}

final class GroceryListServiceTests: XCTestCase {
    @MainActor
    func testDuplicateListCopiesItems() throws {
        let container = try ModelContainerSetup.makeContainer(inMemory: true)
        let context = container.mainContext
        let list = GroceryList(name: "Original")
        context.insert(list)
        let item = GroceryItem(name: "Milk", categoryId: "dairy", list: list)
        context.insert(item)
        list.items.append(item)

        let copy = GroceryListService.duplicateList(list, context: context)
        XCTAssertNotNil(copy)
        XCTAssertEqual(copy?.items.count, 1)
        XCTAssertEqual(copy?.items.first?.name, "Milk")
        XCTAssertEqual(copy?.name, "Original Copy")
    }
}

final class CategoryLearningResetTests: XCTestCase {
    @MainActor
    func testResetAllClearsRules() throws {
        let container = try ModelContainerSetup.makeContainer(inMemory: true)
        let context = container.mainContext
        CategoryLearningService.record(normalizedName: "widget", categoryId: "misc", context: context)
        XCTAssertFalse(CategoryLearningService.fetchRules(context: context).isEmpty)

        CategoryLearningService.resetAll(context: context)
        XCTAssertTrue(CategoryLearningService.fetchRules(context: context).isEmpty)
    }
}
