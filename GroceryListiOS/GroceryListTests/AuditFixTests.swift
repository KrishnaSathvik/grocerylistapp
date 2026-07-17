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

    @MainActor
    func testFormatUsesCustomStoreLabel() throws {
        let container = try ModelContainerSetup.makeContainer(inMemory: true)
        let context = container.mainContext
        _ = StoreService.addCustomStore(label: "Local Market", context: context)
        guard let storeId = StoreService.storeId(forLabel: "Local Market", context: context) else {
            XCTFail("Expected custom store")
            return
        }

        let list = GroceryList(name: "Test")
        context.insert(list)
        let item = GroceryItem(name: "bread", categoryId: "bakery", storeId: storeId, list: list)
        context.insert(item)
        list.items = [item]

        let text = ShareTextFormatter.format(list: list, context: context)
        XCTAssertTrue(text.contains("Local Market:"))
        XCTAssertFalse(text.contains("local-market:"))
    }

    @MainActor
    func testFormatPlainListIsGroceryOnly() throws {
        let container = try ModelContainerSetup.makeContainer(inMemory: true)
        let context = container.mainContext
        let list = GroceryList(name: "Weekly")
        context.insert(list)
        let item = GroceryItem(name: "milk", categoryId: "dairy", list: list)
        context.insert(item)
        list.items = [item]

        let text = ShareTextFormatter.formatPlainList(list: list, context: context)
        XCTAssertTrue(text.hasPrefix("Weekly\n"))
        XCTAssertTrue(text.contains("☐ milk"))
        XCTAssertFalse(text.contains("App Store"))
        XCTAssertFalse(text.contains("apps.apple.com"))
        XCTAssertFalse(text.contains("smartgrocerylists.app"))
        XCTAssertFalse(text.contains("remaining"))
    }

    @MainActor
    func testFormatPlainListIncludesStoreSections() throws {
        let container = try ModelContainerSetup.makeContainer(inMemory: true)
        let context = container.mainContext
        let list = GroceryList(name: "Weekly")
        context.insert(list)
        let eggs = GroceryItem(name: "eggs", categoryId: "dairy", storeId: "costco", list: list)
        let chicken = GroceryItem(name: "chicken", categoryId: "meat", storeId: "walmart", list: list)
        context.insert(eggs)
        context.insert(chicken)
        list.items = [eggs, chicken]

        let text = ShareTextFormatter.formatPlainList(list: list, context: context)
        XCTAssertTrue(text.contains("Costco:"))
        XCTAssertTrue(text.contains("Walmart:"))
        XCTAssertTrue(text.contains("☐ eggs"))
        XCTAssertTrue(text.contains("☐ chicken"))
    }

    @MainActor
    func testFormatForMessagesIsListOnly() throws {
        let container = try ModelContainerSetup.makeContainer(inMemory: true)
        let context = container.mainContext
        let list = GroceryList(name: "Weekly")
        context.insert(list)
        let item = GroceryItem(name: "milk", categoryId: "dairy", list: list)
        context.insert(item)
        list.items = [item]

        let text = ShareTextFormatter.formatForMessages(list: list, context: context)
        XCTAssertFalse(text.contains("Weekly"))
        XCTAssertFalse(text.contains("GLIST1"))
        XCTAssertFalse(text.contains("smartgrocerylists.app"))
        XCTAssertTrue(text.contains("☐ milk"))
        XCTAssertTrue(text.contains("App Store"))
        XCTAssertTrue(text.contains("apps.apple.com"))
    }

    @MainActor
    func testFormatForSharingIncludesImportLinkAndAppStore() throws {
        let container = try ModelContainerSetup.makeContainer(inMemory: true)
        let context = container.mainContext
        let list = GroceryList(name: "Weekly")
        context.insert(list)
        let item = GroceryItem(name: "milk", categoryId: "dairy", list: list)
        context.insert(item)
        list.items = [item]

        let text = ShareTextFormatter.formatForSharing(
            list: list,
            context: context,
            includeListTitle: true,
            includeURLsInBody: true,
            includeBrandHeader: true
        )
        XCTAssertTrue(text.hasPrefix("Weekly\n"))
        XCTAssertTrue(text.contains("smartgrocerylists.app"))
    }

    @MainActor
    func testShareItemSourceIsListOnly() throws {
        let container = try ModelContainerSetup.makeContainer(inMemory: true)
        let context = container.mainContext
        let list = GroceryList(name: "Weekly Groceries")
        context.insert(list)
        let item = GroceryItem(name: "eggs", categoryId: "dairy", storeId: "costco", list: list)
        context.insert(item)
        list.items = [item]

        let source = GroceryListShareItemSource(list: list, context: context)
        XCTAssertFalse(source.bodyText.contains("Weekly Groceries"))
        XCTAssertTrue(source.bodyText.contains("☐ eggs"))
        XCTAssertFalse(source.bodyText.contains("GLIST1"))
        XCTAssertFalse(source.bodyText.contains("smartgrocerylists.app"))
        XCTAssertTrue(source.bodyText.contains("apps.apple.com"))
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

    @MainActor
    func testUpdateItemReDetectsCategoryWhenNameFixed() throws {
        let container = try ModelContainerSetup.makeContainer(inMemory: true)
        let context = container.mainContext
        let list = GroceryList(name: "Test")
        context.insert(list)

        let item = GroceryItem(
            name: "salomn",
            normalizedName: "salomn",
            categoryId: "misc",
            list: list
        )
        context.insert(item)
        list.items.append(item)

        var draft = ItemEditDraft(item: item)
        draft.name = "Salmon"
        GroceryItemService.updateItem(item, draft: draft, context: context)

        XCTAssertEqual(item.name, "Salmon")
        XCTAssertEqual(item.categoryId, "seafood")
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

final class FocusedShoppingAddTests: XCTestCase {
    @MainActor
    func testAddFromStoreDetailPrefillsStore() throws {
        let container = try ModelContainerSetup.makeContainer(inMemory: true)
        let context = container.mainContext
        let list = GroceryList(name: "Test")
        context.insert(list)

        let created = GroceryItemService.addItems(
            name: "milk",
            to: list,
            context: context,
            prefilledStoreId: "costco",
            prefilledCategoryId: nil
        )

        XCTAssertEqual(created.count, 1)
        XCTAssertEqual(created.first?.storeId, "costco")
        XCTAssertEqual(created.first?.name.lowercased(), "milk")
    }

    @MainActor
    func testAddFromCategoryDetailPrefillsCategory() throws {
        let container = try ModelContainerSetup.makeContainer(inMemory: true)
        let context = container.mainContext
        let list = GroceryList(name: "Test")
        context.insert(list)

        let created = GroceryItemService.addItems(
            name: "milk",
            to: list,
            context: context,
            prefilledStoreId: nil,
            prefilledCategoryId: "dairy"
        )

        XCTAssertEqual(created.count, 1)
        XCTAssertEqual(created.first?.categoryId, "dairy")
    }
}

final class CategoryLearningResetTests: XCTestCase {
    @MainActor
    func testResetAllClearsRules() throws {
        let container = try ModelContainerSetup.makeContainer(inMemory: true)
        let context = container.mainContext
        CategoryLearningService.record(normalizedName: "widget", categoryId: "dairy", context: context)
        XCTAssertFalse(CategoryLearningService.fetchRules(context: context).isEmpty)

        CategoryLearningService.resetAll(context: context)
        XCTAssertTrue(CategoryLearningService.fetchRules(context: context).isEmpty)
    }
}
