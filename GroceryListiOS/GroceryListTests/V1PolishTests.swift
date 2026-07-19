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
        // B7C installed dedicated cilantro photoreal.
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "cilantro"), "product-cilantro")
        XCTAssertTrue(CatalogAssetAvailability.isUsable("product-cilantro"))
    }

    func testResolverCategoryFallbackForUnknownItem() {
        let resolution = ItemAssetResolver.resolve(itemName: "widget xyz")
        XCTAssertEqual(resolution.kind, .category)
        XCTAssertEqual(resolution.assetName, "category-misc")
    }

    func testBundledAssetFallsBackToCategoryWhenProductMissing() {
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "widget xyz"), "category-misc")
        // Canonical match remains; dedicated PNG removed → category illustration.
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "milk").assetName, "product-milk-whole")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "milk"), "category-dairy")
        XCTAssertNil(UIImage(named: "product-milk-whole"))
    }

    func testApprovedB1B2ProductsKeepDedicatedBundledAssets() {
        XCTAssertTrue(CatalogAssetAvailability.isUsable("product-mangoes"))
        XCTAssertTrue(CatalogAssetAvailability.isUsable("product-kale"))
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "mango"), "product-mangoes")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "kale"), "product-kale")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "chicken drumsticks"), "product-chicken-drumsticks")
    }

    func testLegacyProduceMatchesButFallsBackToCategory() {
        // B7C approved produce now bundle dedicated art.
        let approved: [(String, String)] = [
            ("cilantro", "product-cilantro"),
            ("bananas", "product-bananas"),
            ("avocado", "product-avocados"),
            ("lemon", "product-lemons"),
            ("apples", "product-apples"),
        ]
        for (item, product) in approved {
            XCTAssertEqual(ItemAssetResolver.resolve(itemName: item).assetName, product, item)
            XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: item), product, item)
        }
        let cases: [(String, String, String)] = [
            ("tomatoes", "product-tomatoes", "category-produce"),
            ("lettuce", "product-lettuce", "category-produce"),
            ("onions", "product-onions", "category-produce"),
            ("potatoes", "product-potatoes", "category-produce"),
            ("spinach", "product-spinach", "category-produce"),
        ]
        for (item, product, category) in cases {
            XCTAssertEqual(ItemAssetResolver.resolve(itemName: item).assetName, product, item)
            XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: item), category, item)
        }
    }

    func testLegacyBakeryMatchesButFallsBackToCategory() {
        // B7B approved bakery queue fills now bundle dedicated art.
        let approved: [(String, String)] = [
            ("bread", "product-bread-loaf"),
            ("bagels", "product-bagels"),
        ]
        for (item, product) in approved {
            XCTAssertEqual(ItemAssetResolver.resolve(itemName: item).assetName, product, item)
            XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: item), product, item)
        }
        let fallback: [(String, String)] = [
            ("tortillas", "product-tortillas"),
            ("naan", "product-naan"),
        ]
        for (item, product) in fallback {
            XCTAssertEqual(ItemAssetResolver.resolve(itemName: item).assetName, product, item)
            XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: item), "category-bakery", item)
        }
    }

    func testLegacyDairyMatchesButFallsBackToCategory() {
        let fallbackDairy: [(String, String)] = [
            ("milk", "product-milk-whole"),
            ("yogurt", "product-yogurt"),
        ]
        for (item, product) in fallbackDairy {
            XCTAssertEqual(ItemAssetResolver.resolve(itemName: item).assetName, product, item)
            XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: item), "category-dairy", item)
        }
        // B7B/B7C approved dairy products now bundle dedicated art.
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "butter").assetName, "product-butter")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "butter"), "product-butter")
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "cheese").assetName, "product-cheese")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "cheese"), "product-cheese")
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "brown eggs").assetName, "product-eggs-brown")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "brown eggs"), "product-eggs-brown")
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "eggs").assetName, "product-eggs-white")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "eggs"), "product-eggs-white")
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "oat milk").assetName, "product-milk-oat")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "oat milk"), "product-milk-oat")
    }

    func testEggProductDoesNotMatchUnrelatedItems() {
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "large eggs").assetName, "product-eggs-white")
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "dozen eggs").assetName, "product-eggs-white")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "large eggs"), "product-eggs-white")
        // Eggplant keeps approved B1 dedicated asset.
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "eggplant"), "product-eggplant")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "bandaid").assetName, "product-eggs-white")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "bandage").assetName, "product-eggs-white")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "frozen veggies").assetName, "product-eggs-white")
    }

    func testLegacyMeatMatchesButFallsBackToCategory() {
        // Remaining meat without photoreal still falls back to category.
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "ground turkey").assetName, "product-ground-turkey")
        // B5B approved meat products now bundle dedicated art.
        let approved: [(String, String)] = [
            ("chicken", "product-chicken-breast"),
            ("chicken breast", "product-chicken-breast"),
            ("ground beef", "product-ground-beef"),
            ("steak", "product-steak"),
            ("pork chops", "product-pork"),
            ("bacon", "product-bacon"),
            ("sausage", "product-sausage"),
            ("turkey breast", "product-turkey-breast"),
            ("ground turkey", "product-ground-turkey"),
        ]
        for (item, product) in approved {
            XCTAssertEqual(ItemAssetResolver.resolve(itemName: item).assetName, product, item)
            XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: item), product, item)
        }
    }

    func testLegacyPantryAndCondimentMatchesButFallsBackToCategory() {
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "basmati rice").assetName, "product-rice-basmati")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "basmati rice"), "category-pantry")
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "white rice").assetName, "product-rice-white")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "white rice"), "category-pantry")
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "pasta").assetName, "product-pasta")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "pasta"), "category-pantry")
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "flour").assetName, "product-flour")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "flour"), "product-flour")
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "olive oil").assetName, "product-olive-oil")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "olive oil"), "category-condiments")
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "gochujang").assetName, "product-gochujang")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "gochujang"), "product-gochujang")
        // Exact "flour" must not lose to fuzzy "flowers"
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "flour").assetName, "product-flowers")
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "flowers").assetName, "product-flowers")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "flowers"), "product-flowers")
    }

    func testLegacyDrinksAndSeafoodMatchesButFallsBackToCategory() {
        // B6B approved drinks now bundle dedicated art.
        let approvedDrinks: [(String, String)] = [
            ("coffee", "product-coffee"),
            ("tea", "product-tea"),
            ("orange juice", "product-orange-juice"),
            ("water", "product-water"),
            ("beer", "product-beer"),
        ]
        for (item, product) in approvedDrinks {
            XCTAssertEqual(ItemAssetResolver.resolve(itemName: item).assetName, product, item)
            XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: item), product, item)
        }
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "salmon").assetName, "product-salmon")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "salmon"), "product-salmon")
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "shrimp").assetName, "product-shrimp")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "shrimp"), "product-shrimp")
    }

    func testLegacyFinalBatchMatchesButFallsBackToCategory() {
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "kimchi").assetName, "product-kimchi")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "kimchi"), "product-kimchi")
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "ice cream").assetName, "product-ice-cream")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "ice cream"), "product-ice-cream")
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "chips").assetName, "product-chips")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "chips"), "product-chips")
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "dish soap").assetName, "product-dish-soap")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "dish soap"), "product-dish-soap")
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "dog food").assetName, "product-dog-food")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "dog food"), "product-dog-food")
    }

    func testTierABProductThumbnailsResolve() {
        let cases: [(String, String, String)] = [
            ("flowers", "product-flowers", "product-flowers"),
            ("lettuce", "product-lettuce", "category-produce"),
            ("cat food", "product-cat-food", "product-cat-food"),
        ]
        for (item, product, category) in cases {
            XCTAssertEqual(ItemAssetResolver.resolve(itemName: item).assetName, product, item)
            XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: item), category, item)
        }
        // Approved photoreal products now bundle dedicated art.
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "frozen vegetables").assetName, "product-frozen-vegetables")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "frozen vegetables"), "product-frozen-vegetables")
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "sausage").assetName, "product-sausage")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "sausage"), "product-sausage")
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "ground turkey").assetName, "product-ground-turkey")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "ground turkey"), "product-ground-turkey")
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "hummus").assetName, "product-hummus")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "hummus"), "product-hummus")
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "granola bars").assetName, "product-granola-bars")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "granola bars"), "product-granola-bars")
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "corn flakes").assetName, "product-cereal")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "corn flakes"), "product-cereal")
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "canned soup").assetName, "product-soup")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "canned soup"), "product-soup")
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "peanut butter").assetName, "product-peanut-butter")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "peanut butter"), "product-peanut-butter")
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "beer").assetName, "product-beer")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "beer"), "product-beer")
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "toothpaste").assetName, "product-toothpaste")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "toothpaste"), "product-toothpaste")
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "shampoo").assetName, "product-shampoo")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "shampoo"), "product-shampoo")
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "baby wipes").assetName, "product-baby-wipes")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "baby wipes"), "product-baby-wipes")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "disinfecting wipes").assetName, "product-baby-wipes")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "eggplant").assetName, "product-eggs-white")
    }

    func testSpecificProductBatchResolves() {
        // Approved B1 assets still bundle dedicated product art.
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "green onions"), "product-green-onions")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "sweet potatoes"), "product-sweet-potatoes")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "chicken drumsticks"), "product-chicken-drumsticks")

        let legacyCases: [(String, String, String)] = [
            ("coconut milk", "product-milk-coconut", "product-milk-coconut"),
            ("sweetened condensed milk", "product-milk-condensed", "product-milk-condensed"),
            ("egg noodles", "product-egg-noodles", "product-egg-noodles"),
            ("paneer", "product-paneer", "product-paneer"),
            ("apple cider vinegar", "product-apple-cider-vinegar", "product-apple-cider-vinegar"),
            ("tomato sauce", "product-tomato-sauce", "product-tomato-sauce"),
            ("lime", "product-limes", "category-produce"),
            ("roti", "product-roti", "category-bakery"),
            ("paratha", "product-paratha", "category-bakery"),
            ("pita bread", "product-pita", "category-bakery"),
            ("rotisserie chicken", "product-rotisserie-chicken", "product-rotisserie-chicken"),
            ("chicken broth", "product-chicken-broth", "product-chicken-broth"),
            ("rice noodles", "product-rice-noodles", "product-rice-noodles"),
            ("rice vinegar", "product-rice-vinegar", "product-rice-vinegar"),
            ("pasta sauce", "product-pasta-sauce", "product-pasta-sauce"),
            ("coconut water", "product-coconut-water", "product-coconut-water"),
            ("cranberry juice", "product-cranberry-juice", "product-cranberry-juice"),
            ("root beer", "product-root-beer", "product-root-beer"),
            ("ginger ale", "product-ginger-ale", "product-ginger-ale"),
            ("pizza rolls", "product-pizza-rolls", "product-pizza-rolls"),
            ("conditioner", "product-conditioner", "product-conditioner"),
            ("diaper cream", "product-diaper-cream", "product-diaper-cream"),
            ("disinfecting wipes", "product-disinfecting-wipes", "product-disinfecting-wipes"),
        ]
        for (item, product, category) in legacyCases {
            XCTAssertEqual(ItemAssetResolver.resolve(itemName: item).assetName, product, item)
            XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: item), category, item)
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
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "corn flakes").assetName, "product-cereal")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "corn flakes"), "product-cereal")
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "banana bread").assetName, "product-banana-bread")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "banana bread"), "product-banana-bread")
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "coconut milk").assetName, "product-milk-coconut")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "coconut milk"), "product-milk-coconut")
        XCTAssertEqual(ItemAssetResolver.resolve(itemName: "ginger ale").assetName, "product-ginger-ale")
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "ginger ale"), "product-ginger-ale")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "onion powder"), "product-onions")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "garlic powder"), "product-garlic")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "eggplant").assetName, "product-eggs-white")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "chicken drumsticks"), "product-chicken-wings")
    }

    func testPhaseB6BSnacksBeveragesResolves() {
        let cases: [(String, String)] = [
            ("cereal", "product-cereal"),
            ("corn flakes", "product-cereal"),
            ("oatmeal", "product-cereal"),
            ("peanut butter", "product-peanut-butter"),
            ("tea", "product-tea"),
            ("green tea", "product-tea"),
            ("chai", "product-tea"),
            ("coffee", "product-coffee"),
            ("coffee beans", "product-coffee"),
            ("beer", "product-beer"),
            ("ipa", "product-beer"),
            ("lager", "product-beer"),
            ("orange juice", "product-orange-juice"),
            ("almond milk", "product-milk-almond"),
            ("plant milk", "product-milk-almond"),
            ("oat milk", "product-milk-oat"),
            ("soy milk", "product-milk-soy"),
            ("soup", "product-soup"),
            ("canned soup", "product-soup"),
            ("tomato soup", "product-soup"),
        ]
        for (item, asset) in cases {
            XCTAssertEqual(ItemAssetResolver.resolve(itemName: item).assetName, asset, item)
            XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: item), asset, item)
            XCTAssertTrue(CatalogAssetAvailability.isUsable(asset), asset)
        }
        // Collision / distinction protections
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "beer").productId, "root-beer")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "root beer").productId, "beer")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "peanut butter").productId, "almond-butter")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "almond butter").productId, "peanut-butter")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "coffee").productId, "coffee-creamer")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "coffee creamer").productId, "coffee")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "orange juice").productId, "apple-juice")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "almond milk").productId, "milk-oat")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "oat milk").productId, "milk-soy")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "soy milk").productId, "milk-almond")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "almond milk").productId, "milk-coconut")
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "beer").productId,
            ItemAssetResolver.resolve(itemName: "root beer").productId
        )
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "peanut butter").productId,
            ItemAssetResolver.resolve(itemName: "almond butter").productId
        )
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "coffee").productId,
            ItemAssetResolver.resolve(itemName: "coffee creamer").productId
        )
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "almond milk").productId,
            ItemAssetResolver.resolve(itemName: "oat milk").productId
        )
    }

    func testPhaseB7AHouseholdCareHealthResolves() {
        let cases: [(String, String)] = [
            ("dish soap", "product-dish-soap"),
            ("dishwashing liquid", "product-dish-soap"),
            ("disinfecting wipes", "product-disinfecting-wipes"),
            ("cleaning wipes", "product-disinfecting-wipes"),
            ("toilet paper", "product-toilet-paper"),
            ("bath tissue", "product-toilet-paper"),
            ("paper towels", "product-paper-towels"),
            ("paper towel", "product-paper-towels"),
            ("shampoo", "product-shampoo"),
            ("conditioner", "product-conditioner"),
            ("hair conditioner", "product-conditioner"),
            ("toothpaste", "product-toothpaste"),
            ("diapers", "product-diapers"),
            ("diaper", "product-diapers"),
            ("baby wipes", "product-baby-wipes"),
            ("diaper cream", "product-diaper-cream"),
            ("rash cream", "product-diaper-cream"),
        ]
        for (item, asset) in cases {
            XCTAssertEqual(ItemAssetResolver.resolve(itemName: item).assetName, asset, item)
            XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: item), asset, item)
            XCTAssertTrue(CatalogAssetAvailability.isUsable(asset), asset)
        }
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "disinfecting wipes").productId, "baby-wipes")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "baby wipes").productId, "disinfecting-wipes")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "shampoo").productId, "conditioner")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "conditioner").productId, "shampoo")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "toilet paper").productId, "paper-towels")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "paper towels").productId, "toilet-paper")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "dish soap").productId, "shampoo")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "diaper cream").productId, "diapers")
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "disinfecting wipes").productId,
            ItemAssetResolver.resolve(itemName: "baby wipes").productId
        )
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "shampoo").productId,
            ItemAssetResolver.resolve(itemName: "conditioner").productId
        )
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "toilet paper").productId,
            ItemAssetResolver.resolve(itemName: "paper towels").productId
        )
    }

    func testPhaseB7BHouseholdHealthBabyPetResolves() {
        let cases: [(String, String)] = [
            ("dog food", "product-dog-food"),
            ("kibble", "product-dog-food"),
            ("dog kibble", "product-dog-food"),
            ("cat food", "product-cat-food"),
            ("kitty food", "product-cat-food"),
            ("cat kibble", "product-cat-food"),
            ("pet shampoo", "product-pet-shampoo"),
            ("dog shampoo", "product-pet-shampoo"),
            ("cat shampoo", "product-pet-shampoo"),
            ("flowers", "product-flowers"),
            ("bouquet", "product-flowers"),
            ("bagels", "product-bagels"),
            ("banana bread", "product-banana-bread"),
            ("bread", "product-bread-loaf"),
            ("butter", "product-butter"),
            ("cheese", "product-cheese"),
            ("egg noodles", "product-egg-noodles"),
        ]
        for (item, asset) in cases {
            XCTAssertEqual(ItemAssetResolver.resolve(itemName: item).assetName, asset, item)
            XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: item), asset, item)
            XCTAssertTrue(CatalogAssetAvailability.isUsable(asset), asset)
        }
        // Collision / distinction protections
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "dog food").productId, "cat-food")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "cat food").productId, "dog-food")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "pet shampoo").productId, "shampoo")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "shampoo").productId, "pet-shampoo")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "flour").productId, "flowers")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "flowers").productId, "flour")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "butter").productId, "cheese")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "cheese").productId, "butter")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "bread").productId, "banana-bread")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "banana bread").productId, "bread-loaf")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "egg noodles").productId, "eggs-white")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "bagels").productId, "bread-loaf")
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "dog food").productId,
            ItemAssetResolver.resolve(itemName: "cat food").productId
        )
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "pet shampoo").productId,
            ItemAssetResolver.resolve(itemName: "shampoo").productId
        )
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "butter").productId,
            ItemAssetResolver.resolve(itemName: "cheese").productId
        )
    }

    func testPhaseB7CRemainingProductsResolve() {
        let cases: [(String, String)] = [
            ("apples", "product-apples"),
            ("apple", "product-apples"),
            ("green apple", "product-apples"),
            ("avocados", "product-avocados"),
            ("avocado", "product-avocados"),
            ("bananas", "product-bananas"),
            ("banana", "product-bananas"),
            ("cilantro", "product-cilantro"),
            ("dhaniya", "product-cilantro"),
            ("brown eggs", "product-eggs-brown"),
            ("brown egg", "product-eggs-brown"),
            ("eggs", "product-eggs-white"),
            ("egg", "product-eggs-white"),
            ("dozen eggs", "product-eggs-white"),
            ("flour", "product-flour"),
            ("all purpose flour", "product-flour"),
            ("gochujang", "product-gochujang"),
            ("kimchi", "product-kimchi"),
            ("lemons", "product-lemons"),
            ("lemon", "product-lemons"),
        ]
        for (item, asset) in cases {
            XCTAssertEqual(ItemAssetResolver.resolve(itemName: item).assetName, asset, item)
            XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: item), asset, item)
            XCTAssertTrue(CatalogAssetAvailability.isUsable(asset), asset)
        }
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "brown eggs").productId, "eggs-white")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "eggs").productId, "eggs-brown")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "lemons").productId, "limes")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "limes").productId, "lemons")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "bananas").productId, "plantains")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "cilantro").productId, "parsley")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "flour").productId, "flowers")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "apple cider vinegar").productId, "apples")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "avocado oil").productId, "avocados")
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "brown eggs").productId,
            ItemAssetResolver.resolve(itemName: "eggs").productId
        )
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "lemons").productId,
            ItemAssetResolver.resolve(itemName: "limes").productId
        )
    }

    func testPhaseB7DFinalProductsResolve() {
        let cases: [(String, String)] = [
            ("lettuce", "product-lettuce"),
            ("romaine", "product-lettuce"),
            ("iceberg lettuce", "product-lettuce"),
            ("limes", "product-limes"),
            ("lime", "product-limes"),
            ("milk", "product-milk-whole"),
            ("whole milk", "product-milk-whole"),
            ("2% milk", "product-milk-whole"),
            ("naan", "product-naan"),
            ("garlic naan", "product-naan"),
            ("olive oil", "product-olive-oil"),
            ("extra virgin olive oil", "product-olive-oil"),
            ("onions", "product-onions"),
            ("onion", "product-onions"),
            ("red onion", "product-onions"),
            ("paratha", "product-paratha"),
            ("frozen paratha", "product-paratha"),
            ("pasta", "product-pasta"),
            ("spaghetti", "product-pasta"),
            ("penne", "product-pasta"),
            ("pita", "product-pita"),
            ("pita bread", "product-pita"),
            ("potatoes", "product-potatoes"),
            ("potato", "product-potatoes"),
            ("aloo", "product-potatoes"),
            ("basmati", "product-rice-basmati"),
            ("basmati rice", "product-rice-basmati"),
            ("rice", "product-rice-white"),
            ("white rice", "product-rice-white"),
            ("roti", "product-roti"),
            ("chapati", "product-roti"),
            ("shallots", "product-shallots"),
            ("shallot", "product-shallots"),
            ("spinach", "product-spinach"),
            ("baby spinach", "product-spinach"),
            ("palak", "product-spinach"),
            ("tomatoes", "product-tomatoes"),
            ("tomato", "product-tomatoes"),
            ("tortillas", "product-tortillas"),
            ("flour tortilla", "product-tortillas"),
            ("yogurt", "product-yogurt"),
            ("greek yogurt", "product-yogurt"),
            ("dahi", "product-yogurt"),
        ]
        for (item, asset) in cases {
            XCTAssertEqual(ItemAssetResolver.resolve(itemName: item).assetName, asset, item)
            XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: item), asset, item)
            XCTAssertTrue(CatalogAssetAvailability.isUsable(asset), asset)
        }
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "limes").productId, "lemons")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "lemons").productId, "limes")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "shallots").productId, "onions")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "onions").productId, "shallots")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "green onions").productId, "onions")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "sweet potatoes").productId, "potatoes")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "basmati rice").productId, "rice-white")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "rice").productId, "rice-basmati")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "naan").productId, "roti")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "roti").productId, "naan")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "paratha").productId, "naan")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "pita").productId, "naan")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "tortillas").productId, "pita")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "olive oil").productId, "avocado-oil")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "coconut milk").productId, "milk-whole")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "lettuce").productId, "spinach")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "spinach").productId, "lettuce")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "pasta sauce").productId, "pasta")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "tomato sauce").productId, "tomatoes")
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "basmati rice").productId,
            ItemAssetResolver.resolve(itemName: "rice").productId
        )
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "shallots").productId,
            ItemAssetResolver.resolve(itemName: "onions").productId
        )
    }

    func testPhaseB2HerbsGreensIndianProduceResolves() {
        let cases: [(String, String)] = [
            ("kale", "product-kale"),
            ("arugula", "product-arugula"),
            ("bok choy", "product-bok-choy"),
            ("brussels sprouts", "product-brussels-sprouts"),
            ("mixed greens", "product-mixed-greens"),
            ("spring mix", "product-mixed-greens"),
            ("salad greens", "product-mixed-greens"),
            ("bean sprouts", "product-bean-sprouts"),
            ("leeks", "product-leeks"),
            ("fennel", "product-fennel"),
            ("parsnips", "product-parsnips"),
            ("turnips", "product-turnips"),
            ("basil", "product-basil"),
            ("mint", "product-mint"),
            ("pudina", "product-mint"),
            ("parsley", "product-parsley"),
            ("dill", "product-dill"),
            ("rosemary", "product-rosemary"),
            ("thyme", "product-thyme"),
            ("curry leaves", "product-curry-leaves"),
            ("kadi patta", "product-curry-leaves"),
            ("fenugreek leaves", "product-fenugreek-leaves"),
            ("methi", "product-fenugreek-leaves"),
            ("mustard greens", "product-mustard-greens"),
            ("bitter gourd", "product-bitter-gourd"),
            ("karela", "product-bitter-gourd"),
            ("ridge gourd", "product-ridge-gourd"),
            ("turai", "product-ridge-gourd"),
            ("tendli", "product-ivy-gourd"),
            ("parwal", "product-pointed-gourd"),
            ("arbi", "product-taro"),
            ("gavar", "product-cluster-beans"),
            ("chawli", "product-long-beans"),
            ("sem", "product-flat-beans"),
            ("drumstick", "product-drumsticks-moringa"),
            ("moringa", "product-drumsticks-moringa"),
            ("kathal", "product-jackfruit"),
            ("guava", "product-guava"),
            ("amla", "product-amla"),
            ("sitaphal", "product-custard-apple"),
            ("chikoo", "product-sapota"),
            ("jamun", "product-jamun"),
        ]
        for (item, asset) in cases {
            XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: item), asset, item)
        }
        XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: "chicken drumsticks"), "product-chicken-drumsticks")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "drumstick"), "product-chicken-drumsticks")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "curry powder"), "product-curry-leaves")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "fenugreek seeds"), "product-fenugreek-leaves")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "mint chutney"), "product-mint")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "basil pesto"), "product-basil")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "mustard sauce"), "product-mustard-greens")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "jackfruit chips"), "product-jackfruit")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "gulab jamun mix"), "product-jamun")
    }

    func testPhaseB3ADairyRefrigeratedResolves() {
        let cases: [(String, String)] = [
            ("coconut milk", "product-milk-coconut"),
            ("sweetened condensed milk", "product-milk-condensed"),
            ("evaporated milk", "product-milk-evaporated"),
            ("ghee", "product-ghee"),
            ("cream cheese", "product-cream-cheese"),
            ("cottage cheese", "product-cottage-cheese"),
            ("paneer", "product-paneer"),
            ("heavy cream", "product-heavy-cream"),
            ("whipping cream", "product-heavy-cream"),
            ("sour cream", "product-sour-cream"),
            ("coffee creamer", "product-coffee-creamer"),
        ]
        for (item, asset) in cases {
            XCTAssertEqual(ItemAssetResolver.resolve(itemName: item).assetName, asset, item)
            XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: item), asset, item)
            XCTAssertTrue(CatalogAssetAvailability.isUsable(asset), asset)
        }
        // Cross-product distinction: resolution IDs remain distinct
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "sweetened condensed milk").productId,
            ItemAssetResolver.resolve(itemName: "evaporated milk").productId
        )
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "heavy cream").productId,
            ItemAssetResolver.resolve(itemName: "coffee creamer").productId
        )
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "cottage cheese").productId,
            ItemAssetResolver.resolve(itemName: "sour cream").productId
        )
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "cream cheese").productId,
            ItemAssetResolver.resolve(itemName: "paneer").productId
        )
    }

    func testPhaseB4APantrySaucesOilsResolves() {
        let cases: [(String, String)] = [
            ("apple cider vinegar", "product-apple-cider-vinegar"),
            ("acv", "product-apple-cider-vinegar"),
            ("tomato sauce", "product-tomato-sauce"),
            ("marinara", "product-tomato-sauce"),
            ("tomato paste", "product-tomato-paste"),
            ("canned tomatoes", "product-canned-tomatoes"),
            ("diced tomatoes", "product-canned-tomatoes"),
            ("pasta sauce", "product-pasta-sauce"),
            ("spaghetti sauce", "product-pasta-sauce"),
            ("rice noodles", "product-rice-noodles"),
            ("rice vinegar", "product-rice-vinegar"),
            ("rice cakes", "product-rice-cakes"),
            ("avocado oil", "product-avocado-oil"),
            ("almond butter", "product-almond-butter"),
        ]
        for (item, asset) in cases {
            XCTAssertEqual(ItemAssetResolver.resolve(itemName: item).assetName, asset, item)
            XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: item), asset, item)
            XCTAssertTrue(CatalogAssetAvailability.isUsable(asset), asset)
        }
        // Collision protections: specific pantry products must not reuse broad roots
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "apple cider vinegar").productId, "apples")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "tomato sauce").productId, "tomatoes")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "tomato paste").productId, "tomatoes")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "canned tomatoes").productId, "tomatoes")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "pasta sauce").productId, "pasta")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "rice noodles").productId, "rice-white")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "rice vinegar").productId, "rice-white")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "rice cakes").productId, "rice-white")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "avocado oil").productId, "avocados")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "almond butter").productId, "peanut-butter")
        // Cross-product distinction among related pantry assets
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "tomato sauce").productId,
            ItemAssetResolver.resolve(itemName: "pasta sauce").productId
        )
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "tomato paste").productId,
            ItemAssetResolver.resolve(itemName: "canned tomatoes").productId
        )
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "apple cider vinegar").productId,
            ItemAssetResolver.resolve(itemName: "rice vinegar").productId
        )
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "rice vinegar").productId,
            ItemAssetResolver.resolve(itemName: "avocado oil").productId
        )
    }

    func testPhaseB5AMeatSeafoodFrozenResolves() {
        let cases: [(String, String)] = [
            ("chicken wings", "product-chicken-wings"),
            ("chicken wing", "product-chicken-wings"),
            ("chicken thighs", "product-chicken-thighs"),
            ("chicken thigh", "product-chicken-thighs"),
            ("rotisserie chicken", "product-rotisserie-chicken"),
            ("rotisserie", "product-rotisserie-chicken"),
            ("chicken broth", "product-chicken-broth"),
            ("chicken stock", "product-chicken-broth"),
            ("bone broth", "product-chicken-broth"),
            ("tuna steak", "product-tuna-steak"),
            ("ahi tuna", "product-tuna-steak"),
            ("tuna fillet", "product-tuna-steak"),
            ("salmon", "product-salmon"),
            ("salmon fillet", "product-salmon"),
            ("shrimp", "product-shrimp"),
            ("prawns", "product-shrimp"),
            ("frozen vegetables", "product-frozen-vegetables"),
            ("frozen veggies", "product-frozen-vegetables"),
            ("pizza rolls", "product-pizza-rolls"),
            ("bacon", "product-bacon"),
        ]
        for (item, asset) in cases {
            XCTAssertEqual(ItemAssetResolver.resolve(itemName: item).assetName, asset, item)
            XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: item), asset, item)
            XCTAssertTrue(CatalogAssetAvailability.isUsable(asset), asset)
        }
        // Collision protections
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "chicken wings").productId, "chicken-drumsticks")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "chicken thighs").productId, "chicken-breast")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "rotisserie chicken").productId, "chicken-breast")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "chicken broth").productId, "chicken-breast")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "tuna steak").productId, "steak")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "pizza rolls").productId, "frozen-pizza")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "frozen vegetables").productId, "mixed-greens")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "frozen vegetables").productId, "green-peas")
        // Cross-product distinction
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "chicken wings").productId,
            ItemAssetResolver.resolve(itemName: "chicken drumsticks").productId
        )
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "salmon").productId,
            ItemAssetResolver.resolve(itemName: "tuna steak").productId
        )
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "chicken broth").productId,
            ItemAssetResolver.resolve(itemName: "heavy cream").productId
        )
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "chicken broth").productId,
            ItemAssetResolver.resolve(itemName: "coffee creamer").productId
        )
    }

    func testPhaseB5BMeatSeafoodFrozenResolves() {
        let cases: [(String, String)] = [
            ("chicken", "product-chicken-breast"),
            ("chicken breast", "product-chicken-breast"),
            ("turkey breast", "product-turkey-breast"),
            ("sliced turkey", "product-turkey-breast"),
            ("ground turkey", "product-ground-turkey"),
            ("ground beef", "product-ground-beef"),
            ("steak", "product-steak"),
            ("sirloin", "product-steak"),
            ("ribeye", "product-steak"),
            ("pork chops", "product-pork"),
            ("pork chop", "product-pork"),
            ("sausage", "product-sausage"),
            ("italian sausage", "product-sausage"),
            ("frozen pizza", "product-frozen-pizza"),
            ("pizza", "product-frozen-pizza"),
            ("ice cream", "product-ice-cream"),
            ("gelato", "product-ice-cream"),
            ("hummus", "product-hummus"),
        ]
        for (item, asset) in cases {
            XCTAssertEqual(ItemAssetResolver.resolve(itemName: item).assetName, asset, item)
            XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: item), asset, item)
            XCTAssertTrue(CatalogAssetAvailability.isUsable(asset), asset)
        }
        // Collision / distinction protections
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "chicken").productId, "rotisserie-chicken")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "turkey breast").productId, "chicken-breast")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "steak").productId, "tuna-steak")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "ground beef").productId, "ground-turkey")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "sausage").productId, "bacon")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "frozen pizza").productId, "pizza-rolls")
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "ground turkey").productId,
            ItemAssetResolver.resolve(itemName: "ground beef").productId
        )
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "chicken breast").productId,
            ItemAssetResolver.resolve(itemName: "turkey breast").productId
        )
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "steak").productId,
            ItemAssetResolver.resolve(itemName: "tuna steak").productId
        )
    }

    func testPhaseB6ABeveragesSnacksResolves() {
        let cases: [(String, String)] = [
            ("ginger ale", "product-ginger-ale"),
            ("root beer", "product-root-beer"),
            ("coconut water", "product-coconut-water"),
            ("nariyal pani", "product-coconut-water"),
            ("apple juice", "product-apple-juice"),
            ("cranberry juice", "product-cranberry-juice"),
            ("grape juice", "product-grape-juice"),
            ("juice box", "product-juice-boxes"),
            ("juice boxes", "product-juice-boxes"),
            ("granola bars", "product-granola-bars"),
            ("protein bars", "product-granola-bars"),
            ("chips", "product-chips"),
            ("potato chips", "product-chips"),
            ("water", "product-water"),
            ("bottled water", "product-water"),
        ]
        for (item, asset) in cases {
            XCTAssertEqual(ItemAssetResolver.resolve(itemName: item).assetName, asset, item)
            XCTAssertEqual(ItemAssetResolver.bundledAssetName(itemName: item), asset, item)
            XCTAssertTrue(CatalogAssetAvailability.isUsable(asset), asset)
        }
        // Collision / distinction protections
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "root beer").productId, "beer")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "coconut water").productId, "milk-coconut")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "coconut milk").productId, "coconut-water")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "apple juice").productId, "apple-cider-vinegar")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "apple cider vinegar").productId, "apple-juice")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "apple juice").productId, "apples")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "cranberry juice").productId, "grape-juice")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "grape juice").productId, "grapes")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "ginger ale").productId, "ginger")
        XCTAssertNotEqual(ItemAssetResolver.resolve(itemName: "chips").productId, "rice-cakes")
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "coconut water").productId,
            ItemAssetResolver.resolve(itemName: "coconut milk").productId
        )
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "apple juice").productId,
            ItemAssetResolver.resolve(itemName: "apple cider vinegar").productId
        )
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "cranberry juice").productId,
            ItemAssetResolver.resolve(itemName: "grape juice").productId
        )
        XCTAssertNotEqual(
            ItemAssetResolver.resolve(itemName: "root beer").productId,
            ItemAssetResolver.resolve(itemName: "ginger ale").productId
        )
    }

    func testSpecificProductsDoNotReuseBroadAssets() {
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "egg noodles"), "product-eggs-white")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "coconut milk"), "product-milk-whole")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "apple cider vinegar"), "product-apples")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "tomato sauce"), "product-tomatoes")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "tomato paste"), "product-tomatoes")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "canned tomatoes"), "product-tomatoes")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "pasta sauce"), "product-pasta")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "tuna steak"), "product-steak")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "rice noodles"), "product-rice-white")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "rice vinegar"), "product-rice-white")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "rice cakes"), "product-rice-white")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "avocado oil"), "product-avocados")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "almond butter"), "product-peanut-butter")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "root beer"), "product-beer")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "coconut water"), "product-milk-coconut")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "apple juice"), "product-apple-cider-vinegar")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "apple juice"), "product-apples")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "grape juice"), "product-grapes")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "chips"), "product-rice-cakes")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "peanut butter"), "product-almond-butter")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "beer"), "product-root-beer")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "coffee"), "product-coffee-creamer")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "orange juice"), "product-apple-juice")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "chicken broth"), "product-chicken-breast")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "chicken wings"), "product-chicken-drumsticks")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "chicken thighs"), "product-chicken-breast")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "rotisserie chicken"), "product-chicken-breast")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "pizza rolls"), "product-frozen-pizza")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "frozen vegetables"), "product-mixed-greens")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "steak"), "product-tuna-steak")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "chicken"), "product-rotisserie-chicken")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "turkey breast"), "product-chicken-breast")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "frozen pizza"), "product-pizza-rolls")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "disinfecting wipes"), "product-baby-wipes")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "baby wipes"), "product-disinfecting-wipes")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "shampoo"), "product-conditioner")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "toilet paper"), "product-paper-towels")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "paper towels"), "product-toilet-paper")
        XCTAssertNotEqual(ItemAssetResolver.bundledAssetName(itemName: "dish soap"), "product-shampoo")
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

        let staleCases: [(String, String, String, String)] = [
            // name, stale cache, reconciled product asset, bundled display after cleanup
            ("coconut milk", "product-milk-whole", "product-milk-coconut", "product-milk-coconut"),
            ("egg noodles", "product-eggs-white", "product-egg-noodles", "product-egg-noodles"),
            ("apple cider vinegar", "product-apples", "product-apple-cider-vinegar", "product-apple-cider-vinegar"),
            ("root beer", "product-beer", "product-root-beer", "product-root-beer"),
            ("mango", "category-produce", "product-mangoes", "product-mangoes"),
            ("cucumber", "category-produce", "product-cucumbers", "product-cucumbers"),
            ("broccoli", "category-produce", "product-broccoli", "product-broccoli"),
            ("okra", "category-produce", "product-okra", "product-okra"),
            ("lauki", "category-produce", "product-bottle-gourd", "product-bottle-gourd"),
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
                entry.3,
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
