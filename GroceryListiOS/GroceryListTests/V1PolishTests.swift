import XCTest
import UIKit
@testable import GroceryList

final class V1PolishShareFormatterTests: XCTestCase {
    func testFormatSelectedItemsIncludesOnlySelection() {
        let list = GroceryList(name: "Weekly Groceries")
        let milk = GroceryItem(name: "Milk", categoryId: "dairy", sortOrder: 0, list: list)
        let eggs = GroceryItem(name: "Eggs", categoryId: "dairy", sortOrder: 1, list: list)
        let bread = GroceryItem(name: "Bread", categoryId: "bakery", sortOrder: 2, list: list)
        list.items = [milk, eggs, bread]

        let text = ShareTextFormatter.formatSelectedItems([milk, eggs], listName: list.name)
        XCTAssertTrue(text.contains("Milk"))
        XCTAssertTrue(text.contains("Eggs"))
        XCTAssertFalse(text.contains("Bread"))
        XCTAssertTrue(text.contains("2 items selected"))
    }
}

final class V1PolishActiveListResolverTests: XCTestCase {
    override func tearDown() {
        AppSettings.activeListId = nil
        super.tearDown()
    }

    func testSetActiveUpdatesResolvedList() {
        let first = GroceryList(name: "Weekly Groceries")
        let second = GroceryList(name: "Costco Run")
        ActiveListResolver.setActive(first)
        ActiveListResolver.setActive(second)

        XCTAssertEqual(ActiveListResolver.resolve(from: [first, second])?.id, second.id)
        XCTAssertEqual(ActiveListResolver.activeListId, second.id)
    }
}

final class V1PolishReorderPersistenceTests: XCTestCase {
    @MainActor
    func testMoveActiveItemsPersistsOrder() throws {
        let container = try ModelContainerSetup.makeContainer(inMemory: true)
        let context = container.mainContext
        let list = GroceryList(name: "Test")
        context.insert(list)

        let first = GroceryItem(name: "Milk", categoryId: "dairy", sortOrder: 0, list: list)
        let second = GroceryItem(name: "Eggs", categoryId: "dairy", sortOrder: 1, list: list)
        let third = GroceryItem(name: "Bread", categoryId: "bakery", sortOrder: 2, list: list)
        context.insert(first)
        context.insert(second)
        context.insert(third)
        list.items = [first, second, third]
        try context.save()

        GroceryItemService.moveItems(in: list, from: IndexSet(integer: 2), to: 0, activeOnly: true, context: context)

        let ordered = list.items
            .filter { !$0.isArchived && !$0.isCompleted }
            .sorted { $0.sortOrder < $1.sortOrder }
            .map(\.name)

        XCTAssertEqual(ordered, ["Bread", "Milk", "Eggs"])
    }
}

final class V1PolishCustomStoreTests: XCTestCase {
    @MainActor
    func testAddCustomStorePersists() throws {
        let container = try ModelContainerSetup.makeContainer(inMemory: true)
        let context = container.mainContext

        let result = StoreService.addCustomStore(label: "Local Market", context: context)
        guard case .added(let created) = result else {
            XCTFail("Expected store to be added")
            return
        }
        XCTAssertEqual(created.label, "Local Market")

        let stores = StoreService.allStores(context: context)
        XCTAssertTrue(stores.contains(where: { $0.label == "Local Market" && $0.isCustom }))
    }
}

final class V1PolishStoreLogoTests: XCTestCase {
    func testKnownStoresResolveBundledAssets() {
        let cases = ["costco", "walmart", "gerbes", "target", "hmart", "raleys", "frys", "kingsoopers", "fredmeyer", "marianos", "jewelosco", "ingles"]
        for storeId in cases {
            XCTAssertNotNil(
                StoreLogoResolver.bundledAssetName(storeId: storeId, displayLabel: nil),
                "Expected bundled asset for \(storeId)"
            )
        }
    }

    func testGrebesAliasResolvesGerbesBundledAsset() {
        XCTAssertEqual(
            StoreLogoResolver.resolvedStoreId(storeId: "grebes", displayLabel: nil),
            "gerbes"
        )
        XCTAssertEqual(
            StoreLogoResolver.bundledAssetName(storeId: "grebes", displayLabel: nil),
            "store-gerbes"
        )
    }

    func testStoreLogoResolverNormalizesLabels() {
        XCTAssertEqual(
            StoreLogoResolver.resolvedStoreId(storeId: nil, displayLabel: "  walmart  "),
            "walmart"
        )
        XCTAssertEqual(
            StoreLogoResolver.resolvedStoreId(storeId: nil, displayLabel: "Grebes"),
            "gerbes"
        )
    }
}

final class V1PolishImportPreviewTests: XCTestCase {
    @MainActor
    func testImportAddAppendsWithoutRemovingExisting() throws {
        let container = try ModelContainerSetup.makeContainer(inMemory: true)
        let context = container.mainContext
        let list = GroceryList(name: "Test")
        context.insert(list)
        let existing = GroceryItem(name: "Milk", categoryId: "dairy", sortOrder: 0, list: list)
        context.insert(existing)
        list.items = [existing]

        let imported = [
            ImportedListItem(name: "Eggs", quantityValue: nil, categoryId: "dairy", storeId: nil, isCompleted: false),
        ]
        ListImportService.addItems(imported, to: list, context: context)

        XCTAssertEqual(list.items.count, 2)
        XCTAssertTrue(list.items.contains(where: { $0.name == "Milk" }))
        XCTAssertTrue(list.items.contains(where: { $0.name == "Eggs" }))
    }

    @MainActor
    func testImportReplaceRemovesExistingItems() throws {
        let container = try ModelContainerSetup.makeContainer(inMemory: true)
        let context = container.mainContext
        let list = GroceryList(name: "Test")
        context.insert(list)
        let existing = GroceryItem(name: "Milk", categoryId: "dairy", sortOrder: 0, list: list)
        context.insert(existing)
        list.items = [existing]

        let imported = [
            ImportedListItem(name: "Eggs", quantityValue: nil, categoryId: "dairy", storeId: nil, isCompleted: false),
        ]
        ListImportService.replaceItems(imported, in: list, context: context)

        XCTAssertEqual(list.items.count, 1)
        XCTAssertEqual(list.items.first?.name, "Eggs")
    }
}

final class V1PolishProductFallbackTests: XCTestCase {
    func testUnknownProductReturnsNilAsset() {
        XCTAssertNil(ProductImageCatalog.assetName(for: "quinoa salad"))
    }

    func testKnownProductReturnsCatalogAssetName() {
        XCTAssertEqual(ProductImageCatalog.assetName(for: "whole milk"), "product-milk-whole")
        XCTAssertEqual(ProductImageCatalog.assetName(for: "brown eggs"), "product-eggs-brown")
    }

    func testResolverFallsBackToCategoryAsset() {
        let resolution = ItemAssetResolver.resolve(itemName: "cilantro")
        XCTAssertEqual(resolution.kind, .product)
        XCTAssertEqual(resolution.categoryId, "produce")
        XCTAssertEqual(resolution.assetName, "product-cilantro")
    }

    func testResolverCategoryFallbackForUnknownItem() {
        let resolution = ItemAssetResolver.resolve(itemName: "widget xyz")
        XCTAssertEqual(resolution.kind, .category)
        XCTAssertEqual(resolution.assetName, "category-misc")
    }

    func testBundledAssetFallsBackToCategoryWhenProductMissing() {
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "widget xyz"), "category-misc")
    }

    func testBundledProduceProductsUseProductAssets() {
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "cilantro"), "product-cilantro")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "bananas"), "product-bananas")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "tomatoes"), "product-tomatoes")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "avocado"), "product-avocados")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "lemon"), "product-lemons")
    }

    func testBundledBakeryProductsUseProductAssets() {
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "bread"), "product-bread-loaf")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "bagels"), "product-bagels")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "tortillas"), "product-tortillas")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "naan"), "product-naan")
    }

    func testBundledDairyProductsUseProductAssets() {
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "milk"), "product-milk-whole")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "oat milk"), "product-milk-oat")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "brown eggs"), "product-eggs-brown")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "eggs"), "product-eggs-white")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "butter"), "product-butter")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "cheese"), "product-cheese")
    }

    func testEggProductDoesNotMatchUnrelatedItems() {
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "large eggs"), "product-eggs-white")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "dozen eggs"), "product-eggs-white")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "eggplant"), "product-eggs-white")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "bandaid"), "product-eggs-white")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "bandage"), "product-eggs-white")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "frozen veggies"), "product-eggs-white")
    }

    func testBundledMeatProductsUseProductAssets() {
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "chicken"), "product-chicken-breast")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "ground beef"), "product-ground-beef")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "steak"), "product-steak")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "bacon"), "product-bacon")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "pork chops"), "product-pork")
    }

    func testBundledPantryAndCondimentProductsUseProductAssets() {
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "basmati rice"), "product-rice-basmati")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "white rice"), "product-rice-white")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "pasta"), "product-pasta")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "flour"), "product-flour")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "olive oil"), "product-olive-oil")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "gochujang"), "product-gochujang")
        // Exact "flour" must not lose to fuzzy "flowers"
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "flour"), "product-flowers")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "flowers"), "product-flowers")
    }

    func testBundledDrinksAndSeafoodProductsUseProductAssets() {
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "coffee"), "product-coffee")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "tea"), "product-tea")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "water"), "product-water")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "orange juice"), "product-orange-juice")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "salmon"), "product-salmon")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "shrimp"), "product-shrimp")
    }

    func testBundledFinalBatchProductsUseProductAssets() {
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "yogurt"), "product-yogurt")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "kimchi"), "product-kimchi")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "ice cream"), "product-ice-cream")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "chips"), "product-chips")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "dish soap"), "product-dish-soap")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "dog food"), "product-dog-food")
    }

    func testTierABProductThumbnailsResolve() {
        let cases: [(String, String)] = [
            ("flowers", "product-flowers"),
            ("corn flakes", "product-cereal"),
            ("lettuce", "product-lettuce"),
            ("canned soup", "product-soup"),
            ("toothpaste", "product-toothpaste"),
            ("shampoo", "product-shampoo"),
            ("sausage", "product-sausage"),
            ("cat food", "product-cat-food"),
            ("peanut butter", "product-peanut-butter"),
            ("granola bars", "product-granola-bars"),
            ("ground turkey", "product-ground-turkey"),
            ("beer", "product-beer"),
            ("hummus", "product-hummus"),
            ("frozen vegetables", "product-frozen-vegetables"),
            ("baby wipes", "product-baby-wipes"),
        ]
        for (item, asset) in cases {
            XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: item), asset, item)
        }
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "disinfecting wipes"), "product-baby-wipes")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "eggplant"), "product-eggs-white")
    }

    func testSpecificProductBatchResolves() {
        let cases: [(String, String)] = [
            ("coconut milk", "product-milk-coconut"),
            ("sweetened condensed milk", "product-milk-condensed"),
            ("egg noodles", "product-egg-noodles"),
            ("paneer", "product-paneer"),
            ("apple cider vinegar", "product-apple-cider-vinegar"),
            ("tomato sauce", "product-tomato-sauce"),
            ("green onions", "product-green-onions"),
            ("sweet potatoes", "product-sweet-potatoes"),
            ("lime", "product-limes"),
            ("roti", "product-roti"),
            ("paratha", "product-paratha"),
            ("pita bread", "product-pita"),
            ("rotisserie chicken", "product-rotisserie-chicken"),
            ("chicken broth", "product-chicken-broth"),
            ("chicken drumsticks", "product-chicken-drumsticks"),
            ("rice noodles", "product-rice-noodles"),
            ("rice vinegar", "product-rice-vinegar"),
            ("pasta sauce", "product-pasta-sauce"),
            ("coconut water", "product-coconut-water"),
            ("cranberry juice", "product-cranberry-juice"),
            ("root beer", "product-root-beer"),
            ("ginger ale", "product-ginger-ale"),
            ("pizza rolls", "product-pizza-rolls"),
            ("conditioner", "product-conditioner"),
            ("diaper cream", "product-diaper-cream"),
            ("disinfecting wipes", "product-disinfecting-wipes"),
        ]
        for (item, asset) in cases {
            XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: item), asset, item)
        }
    }

    func testPhaseB1EssentialProduceResolves() {
        let cases: [(String, String)] = [
            ("oranges", "product-oranges"),
            ("mandarin", "product-oranges"),
            ("grapes", "product-grapes"),
            ("strawberries", "product-strawberries"),
            ("blueberries", "product-blueberries"),
            ("watermelon", "product-watermelon"),
            ("cantaloupe", "product-melon"),
            ("cherries", "product-cherries"),
            ("peach", "product-peaches"),
            ("nectarine", "product-peaches"),
            ("pear", "product-pears"),
            ("pineapple", "product-pineapple"),
            ("mango", "product-mangoes"),
            ("aam", "product-mangoes"),
            ("kiwi", "product-kiwi"),
            ("coconut", "product-coconut"),
            ("pomegranate", "product-pomegranate"),
            ("anaar", "product-pomegranate"),
            ("papaya", "product-papaya"),
            ("carrots", "product-carrots"),
            ("sweet potatoes", "product-sweet-potatoes"),
            ("corn on the cob", "product-corn"),
            ("broccoli", "product-broccoli"),
            ("cauliflower", "product-cauliflower"),
            ("gobi", "product-cauliflower"),
            ("cucumber", "product-cucumbers"),
            ("zucchini", "product-zucchini"),
            ("bell pepper", "product-bell-peppers"),
            ("capsicum", "product-bell-peppers"),
            ("jalapeno", "product-hot-peppers"),
            ("green chili", "product-hot-peppers"),
            ("eggplant", "product-eggplant"),
            ("baingan", "product-eggplant"),
            ("mushrooms", "product-mushrooms"),
            ("garlic", "product-garlic"),
            ("ginger", "product-ginger"),
            ("green beans", "product-green-beans"),
            ("cabbage", "product-cabbage"),
            ("celery", "product-celery"),
            ("radishes", "product-radishes"),
            ("asparagus", "product-asparagus"),
            ("green peas", "product-green-peas"),
            ("matar", "product-green-peas"),
            ("okra", "product-okra"),
            ("bhindi", "product-okra"),
            ("pumpkin", "product-pumpkin"),
            ("plantain", "product-plantains"),
            ("raw banana", "product-plantains"),
            ("bottle gourd", "product-bottle-gourd"),
            ("lauki", "product-bottle-gourd"),
        ]
        for (item, asset) in cases {
            XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: item), asset, item)
        }
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "corn flakes"), "product-cereal")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "banana bread"), "product-banana-bread")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "coconut milk"), "product-milk-coconut")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "ginger ale"), "product-ginger-ale")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "onion powder"), "product-onions")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "garlic powder"), "product-garlic")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "eggplant"), "product-eggs-white")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "chicken drumsticks"), "product-chicken-wings")
    }

    func testSpecificProductsDoNotReuseBroadAssets() {
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "egg noodles"), "product-eggs-white")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "coconut milk"), "product-milk-whole")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "apple cider vinegar"), "product-apples")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "tomato sauce"), "product-tomatoes")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "tuna steak"), "product-steak")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "rice noodles"), "product-rice-white")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "root beer"), "product-beer")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "chicken broth"), "product-chicken-breast")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "disinfecting wipes"), "product-baby-wipes")
    }

    func testResolverPrefersCurrentNameOverStaleStoredAsset() {
        let resolution = ItemAssetResolver.resolve(
            itemName: "coconut milk",
            storedAssetName: "product-milk-whole"
        )
        XCTAssertEqual(resolution.assetName, "product-milk-coconut")
        XCTAssertEqual(resolution.productId, "milk-coconut")
    }
}

final class V1PolishImageAssetMigrationTests: XCTestCase {
    @MainActor
    func testReconcileUpdatesStaleCachedProductAssets() throws {
        let container = try ModelContainerSetup.makeContainer(inMemory: true)
        let context = container.mainContext
        let list = GroceryList(name: "Migration")
        context.insert(list)

        let staleCases: [(String, String, String)] = [
            ("coconut milk", "product-milk-whole", "product-milk-coconut"),
            ("egg noodles", "product-eggs-white", "product-egg-noodles"),
            ("apple cider vinegar", "product-apples", "product-apple-cider-vinegar"),
            ("root beer", "product-beer", "product-root-beer"),
            ("mango", "category-produce", "product-mangoes"),
            ("cucumber", "category-produce", "product-cucumbers"),
            ("broccoli", "category-produce", "product-broccoli"),
            ("okra", "category-produce", "product-okra"),
            ("lauki", "category-produce", "product-bottle-gourd"),
        ]

        var items: [GroceryItem] = []
        for (offset, entry) in staleCases.enumerated() {
            let item = GroceryItem(
                name: entry.0,
                normalizedName: entry.0,
                categoryId: "misc",
                imageAssetName: entry.1,
                sortOrder: offset,
                list: list
            )
            context.insert(item)
            items.append(item)
        }
        list.items = items

        let quantityBefore = items.map(\.quantityValue)
        let categoryBefore = items.map(\.categoryId)
        let storeBefore = items.map(\.storeId)
        let completedBefore = items.map(\.isCompleted)
        let notesBefore = items.map(\.notes)
        let createdBefore = items.map(\.createdAt)
        let sortBefore = items.map(\.sortOrder)

        let updated = GroceryItemService.reconcileImageAssets(in: list, context: context)
        XCTAssertEqual(updated, staleCases.count)

        for (index, entry) in staleCases.enumerated() {
            XCTAssertEqual(items[index].imageAssetName, entry.2, entry.0)
            XCTAssertEqual(
                ItemAssetResolver.bundledAssetName(
                    itemName: items[index].name,
                    storedAssetName: items[index].imageAssetName
                ),
                entry.2,
                entry.0
            )
        }

        XCTAssertEqual(items.map(\.quantityValue), quantityBefore)
        XCTAssertEqual(items.map(\.categoryId), categoryBefore)
        XCTAssertEqual(items.map(\.storeId), storeBefore)
        XCTAssertEqual(items.map(\.isCompleted), completedBefore)
        XCTAssertEqual(items.map(\.notes), notesBefore)
        XCTAssertEqual(items.map(\.createdAt), createdBefore)
        XCTAssertEqual(items.map(\.sortOrder), sortBefore)
        XCTAssertEqual(items.map(\.list?.id), Array(repeating: list.id, count: items.count))
    }
}

final class V1PolishCategoryIconTests: XCTestCase {
    func testCategoryResolverNormalizesLabelsAndPunctuation() {
        XCTAssertEqual(GroceryCatalog.category(for: "  dairy  ")?.id, "dairy")
        XCTAssertEqual(GroceryCatalog.category(for: "Dairy & Eggs")?.id, "dairy")
        XCTAssertEqual(GroceryCatalog.category(for: "Produce")?.assetName, "category-produce")
    }

    func testCategoryIconRenderingResolvesKnownAssets() {
        XCTAssertEqual(CategoryIconRendering.resolvedAssetName(for: "dairy"), "category-dairy")
        XCTAssertEqual(CategoryIconRendering.resolvedAssetName(for: "Dairy & Eggs"), "category-dairy")
        XCTAssertEqual(CategoryIconRendering.resolvedAssetName(for: "produce"), "category-produce")
        XCTAssertEqual(CategoryIconRendering.resolvedAssetName(for: "floral"), "category-floral")
    }

    func testFloralCategoryAssetIsBundled() {
        XCTAssertTrue(CatalogAssetAvailability.isUsable("category-floral"))
        XCTAssertEqual(GroceryCatalog.category(for: "floral")?.displayName, "Floral")
    }

    func testBadgeTrimProducesConsistentVisibleFill() throws {
        let dairy = try XCTUnwrap(CatalogBadgeImage.trimmed(named: "category-dairy"))
        let produce = try XCTUnwrap(CatalogBadgeImage.trimmed(named: "category-produce"))

        let dairyFill = Self.visibleFillRatio(for: dairy)
        let produceFill = Self.visibleFillRatio(for: produce)

        XCTAssertGreaterThan(dairyFill, 0.85)
        XCTAssertGreaterThan(produceFill, 0.85)
        XCTAssertEqual(dairyFill, produceFill, accuracy: 0.08)
    }

    private static func visibleFillRatio(for image: UIImage) -> CGFloat {
        guard let cgImage = image.cgImage,
              let data = cgImage.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else {
            return 0
        }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow
        guard bytesPerPixel >= 4, width > 0, height > 0 else { return 0 }

        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0

        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * bytesPerPixel
                if bytes[offset + 3] > 12 {
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
        }

        guard maxX >= minX, maxY >= minY else { return 0 }
        let visible = CGFloat((maxX - minX + 1) * (maxY - minY + 1))
        return visible / CGFloat(width * height)
    }
}

final class V1PolishCategoryEditTests: XCTestCase {
    @MainActor
    func testUpdateItemSupportsListMoveAndNotes() throws {
        let container = try ModelContainerSetup.makeContainer(inMemory: true)
        let context = container.mainContext
        let source = GroceryList(name: "Source")
        let target = GroceryList(name: "Target")
        context.insert(source)
        context.insert(target)

        let item = GroceryItem(name: "Yogurt", categoryId: "dairy", sortOrder: 0, list: source)
        context.insert(item)
        source.items = [item]

        var draft = ItemEditDraft(item: item)
        draft.notes = "Greek, plain"
        draft.listId = target.id
        draft.categoryId = "dairy"
        draft.storeId = "costco"
        GroceryItemService.updateItem(item, draft: draft, context: context)

        XCTAssertEqual(item.notes, "Greek, plain")
        XCTAssertEqual(item.list?.id, target.id)
        XCTAssertEqual(item.storeId, "costco")
    }
}
