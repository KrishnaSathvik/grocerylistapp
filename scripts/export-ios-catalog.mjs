#!/usr/bin/env node
/**
 * Exports web app taxonomy → iOS catalog JSON (source of truth).
 * Run: node scripts/export-ios-catalog.mjs
 */
import { writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { CATEGORIES, CAT_KEYWORDS } from "../src/data/categories.js";
import { DEFAULT_STORES } from "../src/data/stores.js";
import { ITEM_ICONS } from "../src/itemIcons.js";
import { keywordMatches, categoryTokens } from "../src/detectCategory.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const outDir = join(__dirname, "../GroceryListiOS/GroceryList/Resources");

mkdirSync(outDir, { recursive: true });

/**
 * Canonical products — roots used to attach ITEM_ICONS aliases.
 * More-specific multi-word roots must beat generic single-word roots
 * (e.g. "coconut milk" > "milk", "egg noodles" > "egg").
 */
const CANONICAL_PRODUCTS = [
  // Dairy — milk family
  { id: "milk-whole", displayName: "Milk", categoryId: "dairy", roots: ["milk", "whole milk", "2% milk", "skim milk", "buttermilk", "lactose free milk"] },
  { id: "milk-oat", displayName: "Oat Milk", categoryId: "drinks", roots: ["oat milk"] },
  { id: "milk-almond", displayName: "Almond Milk", categoryId: "drinks", roots: ["almond milk", "plant milk"] },
  { id: "milk-soy", displayName: "Soy Milk", categoryId: "drinks", roots: ["soy milk"] },
  { id: "milk-coconut", displayName: "Coconut Milk", categoryId: "pantry", roots: ["coconut milk", "lite coconut milk"] },
  { id: "milk-condensed", displayName: "Condensed Milk", categoryId: "pantry", roots: ["condensed milk", "sweetened condensed milk"] },
  { id: "milk-evaporated", displayName: "Evaporated Milk", categoryId: "pantry", roots: ["evaporated milk"] },

  // Dairy — eggs & spreads
  { id: "eggs-white", displayName: "Eggs", categoryId: "dairy", roots: ["egg", "eggs", "egg whites", "dozen eggs", "anda"] },
  { id: "eggs-brown", displayName: "Brown Eggs", categoryId: "dairy", roots: ["brown egg", "brown eggs"] },
  { id: "egg-noodles", displayName: "Egg Noodles", categoryId: "pantry", roots: ["egg noodle", "egg noodles"] },
  { id: "butter", displayName: "Butter", categoryId: "dairy", roots: ["butter", "unsalted butter", "salted butter", "margarine", "makhan"] },
  { id: "ghee", displayName: "Ghee", categoryId: "dairy", roots: ["ghee", "clarified butter"] },
  { id: "cheese", displayName: "Cheese", categoryId: "dairy", roots: ["cheese", "cheddar", "mozzarella", "parmesan", "shredded cheese"] },
  { id: "cream-cheese", displayName: "Cream Cheese", categoryId: "dairy", roots: ["cream cheese"] },
  { id: "cottage-cheese", displayName: "Cottage Cheese", categoryId: "dairy", roots: ["cottage cheese"] },
  { id: "paneer", displayName: "Paneer", categoryId: "dairy", roots: ["paneer"] },
  { id: "heavy-cream", displayName: "Heavy Cream", categoryId: "dairy", roots: ["heavy cream", "whipping cream", "heavy whipping cream"] },
  { id: "sour-cream", displayName: "Sour Cream", categoryId: "dairy", roots: ["sour cream"] },
  { id: "yogurt", displayName: "Yogurt", categoryId: "dairy", roots: ["yogurt", "greek yogurt", "yoghurt", "dahi", "curd"] },

  // Produce
  { id: "bananas", displayName: "Bananas", categoryId: "produce", roots: ["banana", "bananas"] },
  { id: "banana-bread", displayName: "Banana Bread", categoryId: "bakery", roots: ["banana bread"] },
  { id: "apples", displayName: "Apples", categoryId: "produce", roots: ["apple", "apples", "green apple"] },
  { id: "apple-juice", displayName: "Apple Juice", categoryId: "drinks", roots: ["apple juice"] },
  { id: "apple-cider-vinegar", displayName: "Apple Cider Vinegar", categoryId: "condiments", roots: ["apple cider vinegar", "acv"] },
  { id: "tomatoes", displayName: "Tomatoes", categoryId: "produce", roots: ["tomato", "tomatoes", "cherry tomato", "grape tomato"] },
  { id: "tomato-sauce", displayName: "Tomato Sauce", categoryId: "condiments", roots: ["tomato sauce", "marinara"] },
  { id: "tomato-paste", displayName: "Tomato Paste", categoryId: "condiments", roots: ["tomato paste"] },
  { id: "canned-tomatoes", displayName: "Canned Tomatoes", categoryId: "pantry", roots: ["canned tomatoes", "diced tomatoes", "crushed tomatoes"] },
  { id: "onions", displayName: "Onions", categoryId: "produce", roots: ["onion", "onions", "red onion"] },
  { id: "green-onions", displayName: "Green Onions", categoryId: "produce", roots: ["green onion", "green onions", "scallion", "scallions", "spring onion", "spring onions"] },
  { id: "shallots", displayName: "Shallots", categoryId: "produce", roots: ["shallot", "shallots"] },
  { id: "potatoes", displayName: "Potatoes", categoryId: "produce", roots: ["potato", "potatoes", "aloo"] },
  { id: "sweet-potatoes", displayName: "Sweet Potatoes", categoryId: "produce", roots: ["sweet potato", "sweet potatoes", "yam", "yams"] },
  { id: "cilantro", displayName: "Cilantro", categoryId: "produce", roots: ["cilantro", "dhaniya"] },
  { id: "spinach", displayName: "Spinach", categoryId: "produce", roots: ["spinach", "baby spinach", "palak"] },
  { id: "avocados", displayName: "Avocados", categoryId: "produce", roots: ["avocado", "avocados"] },
  { id: "avocado-oil", displayName: "Avocado Oil", categoryId: "condiments", roots: ["avocado oil"] },
  { id: "lemons", displayName: "Lemons", categoryId: "produce", roots: ["lemon", "lemons"] },
  { id: "limes", displayName: "Limes", categoryId: "produce", roots: ["lime", "limes"] },
  { id: "lettuce", displayName: "Lettuce", categoryId: "produce", roots: ["lettuce", "romaine", "iceberg lettuce"] },

  // Phase B1 — essential produce (fruits)
  { id: "oranges", displayName: "Oranges", categoryId: "produce", roots: ["orange", "oranges", "mandarin", "mandarins", "clementine", "clementines", "tangerine", "tangerines"] },
  { id: "grapes", displayName: "Grapes", categoryId: "produce", roots: ["grape", "grapes"] },
  { id: "strawberries", displayName: "Strawberries", categoryId: "produce", roots: ["strawberry", "strawberries"] },
  { id: "blueberries", displayName: "Blueberries", categoryId: "produce", roots: ["blueberry", "blueberries"] },
  { id: "watermelon", displayName: "Watermelon", categoryId: "produce", roots: ["watermelon", "tarbooz"] },
  { id: "melon", displayName: "Melon", categoryId: "produce", roots: ["melon", "cantaloupe", "honeydew"] },
  { id: "cherries", displayName: "Cherries", categoryId: "produce", roots: ["cherry", "cherries"] },
  { id: "peaches", displayName: "Peaches", categoryId: "produce", roots: ["peach", "peaches", "nectarine", "nectarines"] },
  { id: "pears", displayName: "Pears", categoryId: "produce", roots: ["pear", "pears"] },
  { id: "pineapple", displayName: "Pineapple", categoryId: "produce", roots: ["pineapple", "pineapples"] },
  { id: "mangoes", displayName: "Mangoes", categoryId: "produce", roots: ["mango", "mangoes", "aam"] },
  { id: "kiwi", displayName: "Kiwi", categoryId: "produce", roots: ["kiwi", "kiwis", "kiwifruit"] },
  { id: "coconut", displayName: "Coconut", categoryId: "produce", roots: ["coconut", "coconuts", "nariyal"] },
  { id: "pomegranate", displayName: "Pomegranate", categoryId: "produce", roots: ["pomegranate", "pomegranates", "anaar"] },
  { id: "papaya", displayName: "Papaya", categoryId: "produce", roots: ["papaya", "papayas"] },

  // Phase B1 — essential produce (vegetables)
  { id: "carrots", displayName: "Carrots", categoryId: "produce", roots: ["carrot", "carrots"] },
  { id: "corn", displayName: "Corn", categoryId: "produce", roots: ["corn", "corn on the cob", "bhutta"] },
  { id: "broccoli", displayName: "Broccoli", categoryId: "produce", roots: ["broccoli"] },
  { id: "cauliflower", displayName: "Cauliflower", categoryId: "produce", roots: ["cauliflower", "gobi"] },
  { id: "cucumbers", displayName: "Cucumbers", categoryId: "produce", roots: ["cucumber", "cucumbers"] },
  { id: "zucchini", displayName: "Zucchini", categoryId: "produce", roots: ["zucchini", "courgette", "courgettes"] },
  { id: "bell-peppers", displayName: "Bell Peppers", categoryId: "produce", roots: ["bell pepper", "bell peppers", "capsicum", "shimla mirch"] },
  { id: "hot-peppers", displayName: "Hot Peppers", categoryId: "produce", roots: ["jalapeno", "jalapeño", "serrano", "habanero", "green chili", "green chilli", "hari mirch", "hot pepper", "hot peppers", "chili pepper", "chilli pepper"] },
  { id: "eggplant", displayName: "Eggplant", categoryId: "produce", roots: ["eggplant", "aubergine", "baingan"] },
  { id: "mushrooms", displayName: "Mushrooms", categoryId: "produce", roots: ["mushroom", "mushrooms", "portobello", "cremini", "shiitake"] },
  { id: "garlic", displayName: "Garlic", categoryId: "produce", roots: ["garlic"] },
  { id: "ginger", displayName: "Ginger", categoryId: "produce", roots: ["ginger"] },
  { id: "green-beans", displayName: "Green Beans", categoryId: "produce", roots: ["green bean", "green beans", "string beans"] },
  { id: "cabbage", displayName: "Cabbage", categoryId: "produce", roots: ["cabbage"] },
  { id: "celery", displayName: "Celery", categoryId: "produce", roots: ["celery"] },
  { id: "radishes", displayName: "Radishes", categoryId: "produce", roots: ["radish", "radishes", "muli"] },
  { id: "asparagus", displayName: "Asparagus", categoryId: "produce", roots: ["asparagus"] },
  { id: "green-peas", displayName: "Green Peas", categoryId: "produce", roots: ["pea", "peas", "green peas", "matar"] },
  { id: "okra", displayName: "Okra", categoryId: "produce", roots: ["okra", "bhindi"] },
  { id: "pumpkin", displayName: "Pumpkin", categoryId: "produce", roots: ["pumpkin", "kaddu"] },
  { id: "plantains", displayName: "Plantains", categoryId: "produce", roots: ["plantain", "plantains", "raw banana", "kaccha kela"] },
  { id: "bottle-gourd", displayName: "Bottle Gourd", categoryId: "produce", roots: ["bottle gourd", "lauki", "ghia"] },

  // Phase B2 — herbs, leafy greens, Indian/international produce
  { id: "kale", displayName: "Kale", categoryId: "produce", roots: ["kale"] },
  { id: "arugula", displayName: "Arugula", categoryId: "produce", roots: ["arugula", "rocket"] },
  { id: "bok-choy", displayName: "Bok Choy", categoryId: "produce", roots: ["bok choy", "bok-choy", "bokchoy", "pak choi"] },
  { id: "brussels-sprouts", displayName: "Brussels Sprouts", categoryId: "produce", roots: ["brussels sprouts", "brussels-sprouts", "brussel sprouts", "brussels sprout"] },
  { id: "mixed-greens", displayName: "Mixed Greens", categoryId: "produce", roots: ["mixed greens", "spring mix", "salad greens", "salad mix"] },
  { id: "bean-sprouts", displayName: "Bean Sprouts", categoryId: "produce", roots: ["bean sprouts", "bean sprout", "mung bean sprouts", "mung sprouts"] },
  { id: "leeks", displayName: "Leeks", categoryId: "produce", roots: ["leek", "leeks"] },
  { id: "fennel", displayName: "Fennel", categoryId: "produce", roots: ["fennel", "fennel bulb"] },
  { id: "parsnips", displayName: "Parsnips", categoryId: "produce", roots: ["parsnip", "parsnips"] },
  { id: "turnips", displayName: "Turnips", categoryId: "produce", roots: ["turnip", "turnips"] },
  { id: "basil", displayName: "Basil", categoryId: "produce", roots: ["basil", "tulsi"] },
  { id: "mint", displayName: "Mint", categoryId: "produce", roots: ["mint", "pudina"] },
  { id: "parsley", displayName: "Parsley", categoryId: "produce", roots: ["parsley"] },
  { id: "dill", displayName: "Dill", categoryId: "produce", roots: ["dill", "dill weed", "suva"] },
  { id: "rosemary", displayName: "Rosemary", categoryId: "produce", roots: ["rosemary"] },
  { id: "thyme", displayName: "Thyme", categoryId: "produce", roots: ["thyme"] },
  { id: "curry-leaves", displayName: "Curry Leaves", categoryId: "produce", roots: ["curry leaves", "curry leaf", "kadi patta"] },
  { id: "fenugreek-leaves", displayName: "Fenugreek Leaves", categoryId: "produce", roots: ["fenugreek leaves", "methi leaves", "methi", "fresh methi"] },
  { id: "mustard-greens", displayName: "Mustard Greens", categoryId: "produce", roots: ["mustard greens", "sarson ka saag", "sarson"] },
  { id: "bitter-gourd", displayName: "Bitter Gourd", categoryId: "produce", roots: ["bitter gourd", "karela", "bitter melon"] },
  { id: "ridge-gourd", displayName: "Ridge Gourd", categoryId: "produce", roots: ["ridge gourd", "turai", "tori", "luffa"] },
  { id: "ivy-gourd", displayName: "Ivy Gourd", categoryId: "produce", roots: ["ivy gourd", "tendli", "tindora"] },
  { id: "pointed-gourd", displayName: "Pointed Gourd", categoryId: "produce", roots: ["pointed gourd", "parwal", "parval"] },
  { id: "taro", displayName: "Taro", categoryId: "produce", roots: ["taro", "arbi", "colocasia"] },
  { id: "cluster-beans", displayName: "Cluster Beans", categoryId: "produce", roots: ["cluster beans", "cluster bean", "gavar", "guar"] },
  { id: "long-beans", displayName: "Long Beans", categoryId: "produce", roots: ["long beans", "long bean", "chawli beans", "chawli", "yardlong beans"] },
  { id: "flat-beans", displayName: "Flat Beans", categoryId: "produce", roots: ["flat beans", "flat bean", "sem phali", "sem"] },
  { id: "drumsticks-moringa", displayName: "Drumsticks (Moringa)", categoryId: "produce", roots: ["drumstick", "drumsticks", "moringa", "moringa pods", "sahjan", "moringa drumstick"] },
  { id: "jackfruit", displayName: "Jackfruit", categoryId: "produce", roots: ["jackfruit", "kathal"] },
  { id: "guava", displayName: "Guava", categoryId: "produce", roots: ["guava", "amrud"] },
  { id: "amla", displayName: "Amla", categoryId: "produce", roots: ["amla", "indian gooseberry"] },
  { id: "custard-apple", displayName: "Custard Apple", categoryId: "produce", roots: ["custard apple", "sitaphal", "sharifa"] },
  { id: "sapota", displayName: "Sapota", categoryId: "produce", roots: ["sapota", "chikoo", "chiku", "sapodilla"] },
  { id: "jamun", displayName: "Jamun", categoryId: "produce", roots: ["jamun", "java plum", "black plum"] },

  // Bakery
  { id: "bread-loaf", displayName: "Bread", categoryId: "bakery", roots: ["bread", "white bread", "wheat bread", "whole wheat bread", "sourdough", "rye bread"] },
  { id: "bagels", displayName: "Bagels", categoryId: "bakery", roots: ["bagel", "bagels"] },
  { id: "tortillas", displayName: "Tortillas", categoryId: "bakery", roots: ["tortilla", "tortillas", "flour tortilla", "corn tortilla", "wrap", "wraps"] },
  { id: "naan", displayName: "Naan", categoryId: "bakery", roots: ["naan", "garlic naan"] },
  { id: "roti", displayName: "Roti", categoryId: "bakery", roots: ["roti", "chapati", "flatbread"] },
  { id: "paratha", displayName: "Paratha", categoryId: "bakery", roots: ["paratha", "frozen paratha"] },
  { id: "pita", displayName: "Pita", categoryId: "bakery", roots: ["pita", "pita bread"] },

  // Meat & seafood
  { id: "chicken-breast", displayName: "Chicken", categoryId: "meat", roots: ["chicken", "chicken breast", "murgh", "frozen chicken"] },
  { id: "chicken-thighs", displayName: "Chicken Thighs", categoryId: "meat", roots: ["chicken thigh", "chicken thighs"] },
  { id: "chicken-wings", displayName: "Chicken Wings", categoryId: "meat", roots: ["chicken wing", "chicken wings", "chicken legs"] },
  { id: "chicken-drumsticks", displayName: "Chicken Drumsticks", categoryId: "meat", roots: ["chicken drumstick", "chicken drumsticks", "drumstick chicken"] },
  { id: "rotisserie-chicken", displayName: "Rotisserie Chicken", categoryId: "meat", roots: ["rotisserie chicken", "rotisserie"] },
  { id: "chicken-broth", displayName: "Chicken Broth", categoryId: "pantry", roots: ["chicken broth", "chicken stock", "bone broth"] },
  { id: "ground-beef", displayName: "Ground Beef", categoryId: "meat", roots: ["ground beef", "beef stew"] },
  { id: "steak", displayName: "Steak", categoryId: "meat", roots: ["steak", "sirloin", "ribeye", "flank steak"] },
  { id: "bacon", displayName: "Bacon", categoryId: "meat", roots: ["bacon", "turkey bacon"] },
  { id: "pork", displayName: "Pork", categoryId: "meat", roots: ["pork", "pork chop", "pork chops", "pork loin"] },
  { id: "sausage", displayName: "Sausage", categoryId: "meat", roots: ["sausage", "sausages", "italian sausage", "bratwurst", "kielbasa"] },
  { id: "ground-turkey", displayName: "Ground Turkey", categoryId: "meat", roots: ["ground turkey"] },
  { id: "turkey-breast", displayName: "Turkey Breast", categoryId: "meat", roots: ["turkey breast", "sliced turkey"] },
  { id: "salmon", displayName: "Salmon", categoryId: "seafood", roots: ["salmon", "salmon fillet", "smoked salmon", "lox"] },
  { id: "shrimp", displayName: "Shrimp", categoryId: "seafood", roots: ["shrimp", "prawns", "jhinga"] },
  { id: "tuna-steak", displayName: "Tuna Steak", categoryId: "seafood", roots: ["tuna steak", "ahi tuna", "tuna fillet"] },

  // Pantry
  { id: "rice-basmati", displayName: "Basmati Rice", categoryId: "pantry", roots: ["basmati", "basmati rice"] },
  { id: "rice-white", displayName: "Rice", categoryId: "pantry", roots: ["rice", "white rice", "brown rice", "jasmine rice", "chawal"] },
  { id: "rice-noodles", displayName: "Rice Noodles", categoryId: "pantry", roots: ["rice noodle", "rice noodles", "vermicelli rice"] },
  { id: "rice-vinegar", displayName: "Rice Vinegar", categoryId: "condiments", roots: ["rice vinegar"] },
  { id: "rice-cakes", displayName: "Rice Cakes", categoryId: "snacks", roots: ["rice cake", "rice cakes"] },
  { id: "pasta", displayName: "Pasta", categoryId: "pantry", roots: ["pasta", "spaghetti", "penne", "macaroni", "linguine", "fettuccine"] },
  { id: "pasta-sauce", displayName: "Pasta Sauce", categoryId: "condiments", roots: ["pasta sauce", "pizza sauce", "spaghetti sauce"] },
  { id: "flour", displayName: "Flour", categoryId: "pantry", roots: ["flour", "all purpose flour", "atta", "maida", "bread flour"] },
  { id: "cereal", displayName: "Cereal", categoryId: "pantry", roots: ["cereal", "corn flakes", "frosted flakes", "cheerios", "oatmeal"] },
  { id: "soup", displayName: "Soup", categoryId: "pantry", roots: ["soup", "canned soup", "chicken soup", "tomato soup"] },
  { id: "peanut-butter", displayName: "Peanut Butter", categoryId: "pantry", roots: ["peanut butter"] },
  { id: "almond-butter", displayName: "Almond Butter", categoryId: "pantry", roots: ["almond butter"] },

  // Condiments & oils
  { id: "olive-oil", displayName: "Olive Oil", categoryId: "condiments", roots: ["olive oil", "extra virgin olive oil"] },
  { id: "gochujang", displayName: "Gochujang", categoryId: "condiments", roots: ["gochujang"] },

  // Deli
  { id: "kimchi", displayName: "Kimchi", categoryId: "deli", roots: ["kimchi"] },
  { id: "hummus", displayName: "Hummus", categoryId: "deli", roots: ["hummus"] },

  // Drinks
  { id: "coffee", displayName: "Coffee", categoryId: "drinks", roots: ["coffee", "ground coffee", "coffee beans", "instant coffee", "espresso"] },
  { id: "coffee-creamer", displayName: "Coffee Creamer", categoryId: "drinks", roots: ["coffee creamer", "creamer"] },
  { id: "tea", displayName: "Tea", categoryId: "drinks", roots: ["tea", "green tea", "black tea", "chai", "matcha", "chai patti"] },
  { id: "water", displayName: "Water", categoryId: "drinks", roots: ["water", "bottled water", "sparkling water"] },
  { id: "coconut-water", displayName: "Coconut Water", categoryId: "drinks", roots: ["coconut water", "nariyal pani"] },
  { id: "orange-juice", displayName: "Orange Juice", categoryId: "drinks", roots: ["orange juice"] },
  { id: "cranberry-juice", displayName: "Cranberry Juice", categoryId: "drinks", roots: ["cranberry juice"] },
  { id: "grape-juice", displayName: "Grape Juice", categoryId: "drinks", roots: ["grape juice"] },
  { id: "juice-boxes", displayName: "Juice Boxes", categoryId: "drinks", roots: ["juice box", "juice boxes"] },
  { id: "beer", displayName: "Beer", categoryId: "drinks", roots: ["beer", "ipa", "lager", "stout", "craft beer", "pale ale"] },
  { id: "root-beer", displayName: "Root Beer", categoryId: "drinks", roots: ["root beer"] },
  { id: "ginger-ale", displayName: "Ginger Ale", categoryId: "drinks", roots: ["ginger ale"] },

  // Frozen
  { id: "ice-cream", displayName: "Ice Cream", categoryId: "frozen", roots: ["ice cream", "gelato", "kulfi", "frozen yogurt"] },
  { id: "frozen-pizza", displayName: "Frozen Pizza", categoryId: "frozen", roots: ["frozen pizza", "pizza"] },
  { id: "pizza-rolls", displayName: "Pizza Rolls", categoryId: "frozen", roots: ["pizza rolls", "pizza roll"] },
  { id: "frozen-vegetables", displayName: "Frozen Vegetables", categoryId: "frozen", roots: ["frozen vegetables", "frozen veggies", "frozen peas", "frozen corn"] },

  // Snacks
  { id: "chips", displayName: "Chips", categoryId: "snacks", roots: ["chips", "potato chips", "tortilla chips"] },
  { id: "granola-bars", displayName: "Granola Bars", categoryId: "snacks", roots: ["granola bar", "granola bars", "cereal bar", "cereal bars", "protein bar", "protein bars"] },

  // Household
  { id: "paper-towels", displayName: "Paper Towels", categoryId: "household", roots: ["paper towel", "paper towels"] },
  { id: "toilet-paper", displayName: "Toilet Paper", categoryId: "household", roots: ["toilet paper", "bath tissue"] },
  { id: "dish-soap", displayName: "Dish Soap", categoryId: "household", roots: ["dish soap", "dishwashing liquid", "dawn"] },
  { id: "disinfecting-wipes", displayName: "Disinfecting Wipes", categoryId: "household", roots: ["disinfecting wipes", "disinfectant wipes", "cleaning wipes", "wet wipes", "lysol wipes", "clorox wipes"] },

  // Health
  { id: "toothpaste", displayName: "Toothpaste", categoryId: "health", roots: ["toothpaste"] },
  { id: "shampoo", displayName: "Shampoo", categoryId: "health", roots: ["shampoo"] },
  { id: "conditioner", displayName: "Conditioner", categoryId: "health", roots: ["conditioner", "hair conditioner"] },

  // Baby
  { id: "diapers", displayName: "Diapers", categoryId: "baby", roots: ["diaper", "diapers", "nappy", "pull-ups"] },
  { id: "diaper-cream", displayName: "Diaper Cream", categoryId: "baby", roots: ["diaper cream", "diaper rash cream", "rash cream"] },
  { id: "baby-wipes", displayName: "Baby Wipes", categoryId: "baby", roots: ["baby wipes"] },

  // Pet
  { id: "dog-food", displayName: "Dog Food", categoryId: "pet", roots: ["dog food", "kibble", "dog kibble"] },
  { id: "cat-food", displayName: "Cat Food", categoryId: "pet", roots: ["cat food", "kitty food", "cat kibble"] },
  { id: "pet-shampoo", displayName: "Pet Shampoo", categoryId: "pet", roots: ["pet shampoo", "dog shampoo", "cat shampoo"] },

  // Floral
  { id: "flowers", displayName: "Flowers", categoryId: "floral", roots: ["flowers", "flower", "bouquet", "bouquets", "fresh flowers"] },
];

/** Product-specific image prompts — keyed by product id. */
const PRODUCT_PROMPTS = {
  "milk-whole": "Photorealistic grocery catalog product of one upright classic dairy whole-milk gable-top carton, opaque white body with a simple blue accent stripe and abstract milk-drop icon only, blank panels with absolutely NO readable text letters numbers logos barcodes. Distinct from plant-milk cartons (oat tan, almond cream with nut art, soy green), not a glass bottle, not coconut milk can. Transparent background, soft contact shadow, strong 44pt silhouette. No brands, hands, fridge, scenery.",
  "milk-oat": "Photorealistic grocery catalog product: one upright generic oat milk carton, warm beige/tan body with large oat stalk abstract graphics and blank panels with NO readable text, screw or gable top, distinct from almond milk cream carton and soy milk green carton and dairy milk, NO cup, transparent background, soft contact shadow, strong 44pt readability, no brand, no hands, no scenery",
  "milk-almond": "Photorealistic grocery catalog product: one upright generic almond milk carton, cream white body with almond nut abstract graphics and blank panels with NO readable text, distinct from oat milk tan carton and soy milk green carton and coconut milk can, NO cup, transparent background, soft contact shadow, strong 44pt readability, no brand, no hands, no scenery",
  "milk-soy": "Photorealistic grocery catalog product: one upright generic soy milk carton, light green accents with soy pod abstract graphics and blank panels with NO readable text, distinct from oat milk and almond milk cartons, NO cup, transparent background, soft contact shadow, strong 44pt readability, no brand, no hands, no scenery",
  "milk-coconut": "Photorealistic grocery catalog product: one generic white metal can of cooking coconut milk with restrained green coconut accents and NO readable text or logos, beside one opened coconut half showing thick white coconut flesh, no straw, no drinking glass, not coconut water, not dairy milk carton, transparent background, soft contact shadow, no brand",
  "milk-condensed": "Photorealistic grocery catalog product: one short compact generic metal can of sweetened condensed milk with creamy white and pale-blue blank label with NO readable text, beside a small spoon holding thick glossy condensed milk ribbon, thick sweet syrup texture not pourable evaporated milk, no open bowl, transparent background, soft contact shadow, no brand",
  "milk-evaporated": "Photorealistic grocery catalog product: one taller generic metal can of evaporated milk with warm cream and muted red blank label with NO readable text, optional open can rim showing smooth pourable liquid milk, no thick syrup ribbon, no spoon of condensed milk, silhouette distinct from short condensed milk can, transparent background, soft contact shadow, no brand",
  "eggs-white": "Photorealistic grocery catalog product: top-down open grey cardboard egg carton showing six bright white chicken eggs nestled in cups, clean shells, NO brown eggs, NO cooked eggs, NO plate, NO text on carton, transparent background, soft contact shadow, strong 44pt readability, no brand, no scenery",
  "eggs-brown": "Photorealistic grocery catalog product: top-down open cardboard egg carton showing six brown chicken eggs nestled in cups, warm brown shells clearly different from white eggs, NO white eggs, NO cooked eggs, NO plate, NO text on carton, transparent background, soft contact shadow, strong 44pt readability, no brand, no scenery",
  "egg-noodles": "Photorealistic grocery catalog product: one nest or bundle of dry curled yellow egg noodles with visible egg-rich golden color and wavy ribbon strands, clearly dry pasta noodles NOT fresh eggs NOT rice noodles NOT wheat spaghetti, NO cooked bowl NO chopsticks NO sauce, transparent background, soft contact shadow, strong 44pt readability, no brand, no text, no scenery",
  "butter": "Photorealistic grocery catalog product: one stick of yellow butter partially unwrapped in plain parchment paper showing smooth creamy butter face and ridged stick shape, blank wrapper with NO readable text, NO knife NO toast NO plate, distinct from cheese wedge and margarine tub, transparent background, soft contact shadow, strong 44pt readability, no brand, no scenery",
  "ghee": "Photorealistic grocery catalog product: clear glass jar filled with golden amber clarified butter ghee, metallic or plain neutral lid, smooth rich semi-solid translucent texture not watery oil or honey, optional small wooden spoon with a dab of semi-solid ghee, NO readable label, no butter sticks, no pan, transparent background, soft contact shadow, no text, no brand",
  "cheese": "Photorealistic grocery catalog product: one triangular wedge of yellow cheddar cheese with natural rind edge and visible cut face pores, NO plastic package required, NO readable text, NOT butter stick NOT cream cheese block, transparent background, soft contact shadow, strong 44pt readability, no brand, no plate, no scenery",
  "cream-cheese": "Photorealistic grocery catalog product: generic rectangular foil-wrapped cream cheese block partially opened showing bright white smooth soft spreadable cheese with one clean cut corner, neutral silver or plain white wrapper with NO readable branding, no bagel, no bowl, not crumbly cottage cheese, not firm paneer, transparent background, soft contact shadow, no text, no brand",
  "cottage-cheese": "Photorealistic grocery catalog product: small generic white dairy tub with lid removed, filled with white cottage cheese showing clear uneven curds and light creamy liquid, NO spoon obscuring contents, NO readable label, not smooth yogurt, not sour cream swirl, transparent background, soft contact shadow, no text, no brand",
  "paneer": "Photorealistic grocery catalog product: two or three clean rectangular firm matte off-white paneer blocks or thick cubes with subtle crumb texture on a cut face, no sauce, no curry, no herbs, distinct from tofu cream cheese and butter, transparent background, soft contact shadow, no text, no brand",
  "heavy-cream": "Photorealistic grocery catalog product: one small generic heavy cream carton, clean white with restrained blue accents, capped pour spout, richer and smaller than milk carton, optional tiny controlled cream pour cue, NO readable text, no whipped cream pile, distinct from coffee creamer bottle and coconut milk, transparent background, soft contact shadow, no brand",
  "sour-cream": "Photorealistic grocery catalog product: one short wide generic white dairy tub with lid partly open, visible smooth thick white sour cream with soft swirl, no curds, no herbs, no chips, NO readable label, distinct from cottage cheese and yogurt, transparent background, soft contact shadow, no brand",
  "yogurt": "Photorealistic grocery catalog cutout of one pastel blue single-serve yogurt cup with foil lid partially peeled back revealing smooth creamy white yogurt with a strawberry fruit swirl and one fresh strawberry half on top; clearly smooth yogurt not lumpy cottage cheese, not sour cream tub. Blank cup sides with NO readable text logos barcodes. Transparent background, soft contact shadow. No spoon required, plate, brands, hands, scenery.",
  "bananas": "Photorealistic grocery catalog product: one intact bunch of ripe yellow bananas with green stems still connected, natural speckles optional, NOT plantains (plantains are greener and thicker), NO peeled banana, NO fruit bowl, transparent background, soft contact shadow, strong 44pt readability, no brand, no text, no scenery",
  "banana-bread": "Photorealistic grocery catalog product: one short loaf of banana bread with two thick slices cut and leaning, moist brown crumb with visible banana flecks, optional one banana half beside loaf only as cue, NO plate NO butter NO frosting, distinct from sandwich bread loaf and muffins, transparent background, soft contact shadow, strong 44pt readability, no brand, no text, no scenery",
  "apples": "Photorealistic grocery catalog product: three fresh whole red apples clustered together with natural stems and subtle shine, NOT green-only apples as the main cue, NO sliced apple required, NO plate, transparent background, soft contact shadow, strong 44pt readability, no brand, no text, no scenery",
  "apple-juice": "Photorealistic grocery catalog product: one generic clear juice bottle filled with translucent golden apple juice, simple yellow-green abstract blank label with NO readable text, one red or green apple slice beside the bottle as cue, NO vinegar sediment, NO cider vinegar bottle shape, distinct from apple cider vinegar, transparent background, soft contact shadow, strong 44pt readability, no glass, no brand, no hands, no scenery",
  "apple-cider-vinegar": "Photorealistic grocery catalog product: one clear glass bottle filled with amber-brown apple cider vinegar, simple neutral cap, blank cream or light-brown generic label with NO readable text, one red apple or apple slice beside the bottle, optional subtle natural sediment near bottle bottom, not apple juice, not rice vinegar, not cooking oil, no salad, no drinking glass, no pouring hand, transparent background, soft contact shadow, strong 44pt readability, no brand",
  "tomatoes": "Photorealistic grocery catalog cutout of a small cluster of ripe red tomatoes on the vine with green calyxes and vine stems, glossy smooth skins, raw fresh produce. Recognition: fresh red tomatoes on vine, not canned tomatoes, not tomato sauce jar, not cherry-only tiny pile without vine cue if avoidable. Dense centered fill, transparent background, soft contact shadow. No plate, knife, salad, brands, text, hands, scenery.",
  "tomato-sauce": "Photorealistic grocery catalog product: one compact generic short plain jar or small can of smooth bright-red tomato sauce clearly visible through glass or open top, one or two fresh tomatoes as restrained supporting cue, sauce smoother and thinner than pasta sauce and less concentrated than tomato paste, NO pasta, NO chunky pieces, NO large herb garnish, blank/generic label with NO readable text, transparent background, soft contact shadow, strong 44pt readability, no brand",
  "tomato-paste": "Photorealistic grocery catalog product: one small generic metal can of dense dark-red concentrated tomato paste with a small thick mound or curl of paste showing firm texture beside or on the can rim, NOT a squeeze tube, NO watery pour, NO pasta, blank/generic label with NO readable text, distinct from tomato sauce and almond butter, transparent background, soft contact shadow, strong 44pt readability, no brand",
  "canned-tomatoes": "Photorealistic grocery catalog product: one open generic metal can clearly showing diced or peeled tomato chunks in juice, optional whole tomato beside the can, NOT smooth blended sauce, NOT tomato paste, NO pasta, blank/generic label with NO readable text, transparent background, soft contact shadow, strong 44pt readability, no brand",
  "onions": "Photorealistic grocery catalog cutout of two whole yellow storage onions with dry papery golden-brown skins, root discs and dried stem tips visible, round bulbous shape. Recognition: common yellow onions, not red onions only, not elongated shallots, not green-onion scallions, not garlic bulbs. Dense centered fill, transparent background, soft contact shadow. No plate, cutting board, hands, brands, text, scenery.",
  "green-onions": "Photorealistic grocery catalog cutout of bunch of fresh green onions with white bulbs and long green stalks, accurate natural texture, centered on transparent background, soft studio contact shadow, readable at thumbnail size, no plate, no text, no brand",
  "shallots": "Photorealistic grocery catalog cutout of a small cluster of reddish-copper shallots with copper-pink papery skins, elongated teardrop bulb shapes often joined at roots, smaller than yellow onions. Recognition: shallots not yellow onions, not red onion rounds, not garlic, not green onions. Dense centered fill, transparent background, soft contact shadow. No plate, knife, hands, brands, text, scenery.",
  "potatoes": "Photorealistic grocery catalog cutout of three russet potatoes with rough brown earthy skins, oblong irregular shapes, eyes visible, raw uncooked. Recognition: russet baking potatoes, not sweet potatoes orange, not red new potatoes only, not chips. Dense centered fill, transparent background, soft contact shadow. No plate, peeler, fries, mash, brands, text, hands, scenery.",
  "sweet-potatoes": "Photorealistic grocery catalog cutout of two orange-fleshed sweet potatoes with copper skin, accurate natural texture, centered on transparent background, soft studio contact shadow, readable at thumbnail size, no plate, no text, no brand",
  "cilantro": "Photorealistic grocery catalog product: one tied fresh cilantro bunch with bright green feathery lacy leaves and slender stems, clearly cilantro not flat-leaf parsley and not mint, NO pot, NO plate, transparent background, soft contact shadow, strong 44pt readability, no brand, no text, no scenery",
  "spinach": "Photorealistic grocery catalog cutout of a loose pile of fresh dark green spinach leaves with broad smooth-to-gently-crinkled oval leaves and short stems, raw uncooked. Recognition: spinach leaves darker and broader than mixed baby greens, not curly kale, not iceberg lettuce head, not mustard greens. Dense centered fill, transparent background, soft contact shadow. No bag packaging text, plate, cooked wilted spinach, brands, hands, scenery.",
  "avocados": "Photorealistic grocery catalog product: one whole dark bumpy avocado beside one halved avocado showing bright green flesh and large brown pit, raw fresh fruit not guacamole, NO toast, NO plate, transparent background, soft contact shadow, strong 44pt readability, no brand, no text, no scenery",
  "avocado-oil": "Photorealistic grocery catalog product: one tall clear glass bottle filled with pale green-gold cooking oil, neutral or dark-green cap, blank generic label with NO readable text, one avocado half beside it showing green flesh and brown pit, reads as bottled cooking oil not fresh avocado produce, no salad, no pouring hand, no olive imagery, distinct from rice vinegar and apple cider vinegar, transparent background, soft contact shadow, strong 44pt readability, no brand",
  "lemons": "Photorealistic grocery catalog product: three bright yellow lemons clustered, textured citrus peel, optionally one lemon cut in half showing pale yellow pulp, clearly yellow lemons NOT green limes, NO lemonade glass, NO plate, transparent background, soft contact shadow, strong 44pt readability, no brand, no text, no scenery",
  "limes": "Photorealistic grocery catalog cutout of two bright green Persian limes, one whole and one halved showing translucent green pulp and thin white pith, glossy textured rind. Recognition: vivid green citrus smaller than lemons, not yellow lemons, not key-lime yellow-green ambiguity alone. Dense centered fill, transparent background, soft contact shadow. No plate, juice glass, knife, hands, brands, logos, readable text, barcodes, scenery.",
  "lettuce": "Photorealistic grocery catalog cutout of one fresh whole iceberg lettuce head with pale crisp green outer leaves tightly wrapped in a round globe shape, water-droplet sheen optional, dense centered fill. Recognition: classic round iceberg head, not romaine spears, not spinach pile, not kale, not cabbage purple, not mixed salad greens bag. Isolated transparent background, soft studio contact shadow. No plate, bowl, hands, people, shelves, scenery, brands, logos, readable text, barcodes, watermarks.",
  // Phase B1 produce prompts
  oranges: "Photorealistic grocery catalog cutout of two whole ripe oranges and one clean half showing juicy segments, bright orange peel texture, centered on transparent background, soft studio contact shadow, readable at thumbnail size, no plate, no text, no brand",
  grapes: "Photorealistic compact bunch of fresh green grapes with natural bloom, grocery catalog cutout, centered on transparent background, soft contact shadow, no plate, no text, no brand",
  strawberries: "Photorealistic three ripe red strawberries with green tops, one cleanly sliced to show interior, grocery catalog cutout, centered transparent background, soft contact shadow, no plate, no text",
  blueberries: "Photorealistic compact cluster of fresh blueberries with dusty bloom, grocery catalog cutout, centered transparent background, soft contact shadow, no bowl, no text",
  watermelon: "Photorealistic watermelon wedge with red flesh and black seeds beside a partial whole green-striped melon, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  melon: "Photorealistic cantaloupe-style melon: one whole netted melon and one half showing orange flesh, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  cherries: "Photorealistic small cluster of bright red cherries with green stems, grocery catalog cutout, centered transparent background, soft contact shadow, no bowl, no text",
  peaches: "Photorealistic two whole fuzzy peaches and one half showing yellow-orange flesh and pit, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  pears: "Photorealistic two ripe green-yellow pears with natural speckles, grocery catalog cutout, centered transparent background, soft contact shadow, no plate, no text",
  pineapple: "Photorealistic whole ripe pineapple with spiky green crown and textured golden skin, grocery catalog cutout, centered transparent background, soft contact shadow, no plate, no text",
  mangoes: "Photorealistic grocery catalog cutout of one whole ripe mango and one clean half showing bright orange flesh and seed, accurate natural texture, centered on transparent background, soft studio contact shadow, no plate, no text",
  kiwi: "Photorealistic two whole brown fuzzy kiwis and one sliced half showing bright green flesh and black seeds, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  coconut: "Photorealistic whole brown hairy coconut beside one opened coconut half with white meat and water cavity, grocery catalog cutout, transparent background, soft contact shadow, no text, no brand",
  pomegranate: "Photorealistic whole red pomegranate and one broken-open half showing jewel-like arils, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  papaya: "Photorealistic whole orange papaya and one half showing salmon flesh with black seeds, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  carrots: "Photorealistic compact bunch of three fresh orange carrots with short green tops, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  corn: "Photorealistic two ears of sweet corn, one partly husked showing yellow kernels, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  broccoli: "Photorealistic fresh broccoli crown with short natural stalk and detailed green florets, grocery catalog cutout, transparent background, soft studio shadow, no plate, no text",
  cauliflower: "Photorealistic whole white cauliflower head with tight florets and pale green leaves, clearly distinct from broccoli, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  cucumbers: "Photorealistic two fresh dark-green cucumbers, one sliced at the end to show pale interior, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  zucchini: "Photorealistic two medium dark-green zucchini with visible stems, shorter and thicker than cucumber, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  "bell-peppers": "Photorealistic grouping of red, yellow, and green whole bell peppers, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  "hot-peppers": "Photorealistic compact cluster of green and red hot chili peppers, slender and pointed, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  eggplant: "Photorealistic one large glossy purple eggplant with green calyx, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  mushrooms: "Photorealistic compact cluster of common white button and brown cremini mushrooms, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  garlic: "Photorealistic whole garlic bulb with papery skin beside several peeled cloves, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  ginger: "Photorealistic compact fresh knobby ginger root with tan skin, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  "green-beans": "Photorealistic compact tied bundle of fresh green beans, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  cabbage: "Photorealistic whole green cabbage head with tight leaves, optionally showing a clean cut face, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  celery: "Photorealistic compact celery bunch with pale green ribs and leafy tops, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  radishes: "Photorealistic tied bunch of bright red radishes with short green tops, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  asparagus: "Photorealistic tied bundle of fresh green asparagus spears, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  "green-peas": "Photorealistic several green pea pods with one opened to show round peas inside, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  okra: "Photorealistic compact grouping of fresh green okra pods with one cut piece showing seeds, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  pumpkin: "Photorealistic small round orange grocery pumpkin with short stem, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  plantains: "Photorealistic small bunch of green cooking plantains, clearly greener and larger than ripe dessert bananas, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  "bottle-gourd": "Photorealistic one pale green bottle gourd with characteristic bulbous shape, clearly distinct from cucumber, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  // Phase B2 produce prompts
  kale: "Photorealistic bunch of curly dark-green kale leaves with ruffled edges, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  arugula: "Photorealistic loose pile of fresh arugula leaves with lobed jagged edges, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  "bok-choy": "Photorealistic two heads of bok choy with white crisp stems and dark green leaves, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  "brussels-sprouts": "Photorealistic compact cluster of green brussels sprouts, some cut in half, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  "mixed-greens": "Photorealistic mixed salad greens pile with varied leaf shapes and colors, grocery catalog cutout, transparent background, soft contact shadow, no bowl, no text",
  "bean-sprouts": "Photorealistic pile of fresh white mung bean sprouts with yellow tips, grocery catalog cutout, transparent background, soft contact shadow, no bowl, no plate, no text",
  leeks: "Photorealistic two fresh leeks with white bases and dark green flat tops, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  fennel: "Photorealistic one fresh fennel bulb with feathery green fronds, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  parsnips: "Photorealistic two cream-colored parsnip roots with tapered ends, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  turnips: "Photorealistic two purple-topped white turnips with short green tops, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  basil: "Photorealistic tied bunch of fresh green basil leaves, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  mint: "Photorealistic tied bunch of fresh bright-green mint sprigs, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  parsley: "Photorealistic tied bunch of curly parsley, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  dill: "Photorealistic tied bunch of feathery fresh dill fronds, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  rosemary: "Photorealistic tied bunch of woody rosemary sprigs with needle leaves, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  thyme: "Photorealistic tied bunch of fresh thyme sprigs, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  "curry-leaves": "Photorealistic small sprig cluster of glossy dark-green curry leaves, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  "fenugreek-leaves": "Photorealistic bunch of fresh fenugreek methi leaves with small clover-like leaflets, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  "mustard-greens": "Photorealistic bunch of large mustard greens with ruffled green leaves, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  "bitter-gourd": "Photorealistic two warty green bitter gourds (karela), one sliced to show pale interior, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  "ridge-gourd": "Photorealistic one long ridged green ridge gourd (turai) with characteristic ridges, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  "ivy-gourd": "Photorealistic small cluster of oval green ivy gourds (tendli), grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  "pointed-gourd": "Photorealistic several pointed green parwal gourds with tapered ends, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  taro: "Photorealistic two brown hairy taro roots (arbi) with one cut showing white flesh, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  "cluster-beans": "Photorealistic compact tied bundle of thin green cluster beans (gavar), grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  "long-beans": "Photorealistic coiled or bundled very long green yardlong beans, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  "flat-beans": "Photorealistic handful of wide flat green beans (sem), grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  "drumsticks-moringa": "Photorealistic three long slender green moringa drumstick pods, clearly vegetable pods not chicken, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  jackfruit: "Photorealistic whole spiky green-yellow jackfruit, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  guava: "Photorealistic two whole guavas and one half showing pink or white flesh with seeds, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  amla: "Photorealistic small cluster of round green amla Indian gooseberries, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  "custard-apple": "Photorealistic one whole bumpy green custard apple (sitaphal) and one opened half showing creamy segments, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  sapota: "Photorealistic two brown oval sapota chikoo fruits, one halved showing soft brown flesh, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  jamun: "Photorealistic small cluster of glossy purple-black jamun fruits, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text",
  "chicken-drumsticks": "Photorealistic raw chicken drumsticks clustered together showing skin and bone end, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text, no brand",
  "bread-loaf": "Photorealistic grocery catalog product: one sliced sandwich bread loaf standing upright with several slices fanned slightly, soft white crumb and golden crust, NO bag packaging text, NO toast scene NO butter, distinct from banana bread denser loaf and bagels ring shape, transparent background, soft contact shadow, strong 44pt readability, no brand, no scenery",
  "bagels": "Photorealistic grocery catalog product: three plain bagels stacked or clustered with clear center holes and shiny baked crust, sesame optional but restrained, NO cream cheese NO plate NO toaster, distinct from donuts and bread rolls, transparent background, soft contact shadow, strong 44pt readability, no brand, no text, no scenery",
  "tortillas": "Photorealistic grocery catalog cutout of a neat stack of soft pale flour tortillas showing round layered edges, light tan soft surface, thin flat discs. Recognition: flour tortilla stack, not pita pocket, not naan, not roti, not corn tortilla deep yellow only if stack still reads as tortillas. Transparent background, soft contact shadow. No package text, brands, fillings, hands, scenery, plates.",
  "naan": "Photorealistic grocery catalog cutout of one warm teardrop-oval naan flatbread with blistered charred bubbles, soft puffy irregular surface, light golden-brown with darker toasted spots, slightly thicker than roti. Recognition: bubbled tandoor naan shape, not round thin roti, not flaky layered paratha, not pita pocket, not tortilla stack. Isolated transparent background, soft contact shadow. No plate, curry bowl, garlic cloves required, brands, text, hands, scenery.",
  "roti": "Photorealistic grocery catalog cutout of one thin round whole-wheat roti (chapati) with matte soft brown-beige surface, few light toast spots, evenly thin without naan bubbles or paratha layers. Recognition: everyday Indian roti, thinner and flatter than naan, not flaky paratha, not pita pocket, not tortilla. Transparent background, soft contact shadow. No plate, ghee pool, brands, text, hands, scenery.",
  "paratha": "Photorealistic grocery catalog cutout of one round flaky layered golden-brown paratha with visible laminated folds and slightly uneven crispy edges, richer toasted color than plain roti. Recognition: flaky layered Indian flatbread, not puffy bubbled naan, not thin whole-wheat roti, not pita pocket, not flour tortilla. Transparent background, soft contact shadow. No plate, stuffing visible required, brands, text, hands, scenery.",
  "pita": "Photorealistic grocery catalog cutout of one round beige pita bread pocket slightly opened to show hollow interior cavity, soft matte surface with light toast spots. Recognition: Middle Eastern pita pocket, not naan tear-drop, not roti, not paratha layers, not tortilla. Transparent background, soft contact shadow. No filling, plate, hummus required, brands, text, hands, scenery.",
  "chicken-breast": "Photorealistic grocery catalog product: two raw boneless chicken breast fillets, pale pink natural poultry color, lean oval shape, clean grocery-counter presentation, NO skin-on whole chicken, NO grill marks, NO sauce, NO tray or packaging, distinct from turkey breast and rotisserie chicken, transparent background, soft contact shadow, strong 44pt readability, no plate, no text, no brand, no hands",
  "chicken-thighs": "Photorealistic grocery catalog product: three or four raw chicken thighs with broad rounded thigh shape, natural pale pink color, consistent skin-on presentation, compact grocery-counter pile, NO drumstick-length bones, NO sauce, NO grill marks, distinct from chicken breast and wings, transparent background, soft contact shadow, strong 44pt readability, no plate, no text, no brand, no hands",
  "chicken-wings": "Photorealistic grocery catalog product: five or six raw chicken wing pieces mixing drumettes and flats, natural pale pink raw poultry, compact grocery presentation, visibly smaller and more jointed than drumsticks, NO sauce, NO frying, NO unnatural protruding bones, transparent background, soft contact shadow, strong 44pt readability, no plate, no text, no brand, no hands",
  "rotisserie-chicken": "Photorealistic grocery catalog product: one whole cooked golden-brown rotisserie chicken with tucked wings and legs and crisp browned skin, grocery-ready presentation without tray label or readable packaging, NO side dishes, NO carving knife, NOT raw, distinct from raw chicken and chicken breast, transparent background, soft contact shadow, strong 44pt readability, no text, no brand, no hands",
  "chicken-broth": "Photorealistic grocery catalog product: one generic shelf-stable broth carton in warm cream or pale-yellow colors with capped pour spout, blank generic label with optional simple chicken silhouette abstract cue and absolutely NO readable text, optional small controlled golden broth splash cue, NO soup bowl, NO surrounding vegetables, distinct from milk heavy-cream and juice cartons, transparent background, soft contact shadow, strong 44pt readability, no brand",
  "ground-beef": "Photorealistic grocery catalog product: compact mound of raw ground beef with clear coarse strand texture, deep red-pink color, NO patties, NO tray packaging, NO blood pools, distinct from ground turkey and burger patties, transparent background, soft contact shadow, strong 44pt readability, no plate, no text, no brand, no hands",
  "steak": "Photorealistic grocery catalog product: one or two raw beef steaks with deep red flesh and visible marbling, clean grocery cut, NO grill marks, NO garnish, NO butter, distinct from tuna steak and pork chops, transparent background, soft contact shadow, strong 44pt readability, no plate, no text, no brand, no hands",
  "bacon": "Photorealistic grocery catalog product: several overlapping strips of raw bacon showing pink meat and white fat marbling, compact grocery-counter presentation, NO cooked crisp edges, NO blood pools, NO hands or cutting board, transparent background, soft contact shadow, strong 44pt readability, no plate, no text, no brand",
  "pork": "Photorealistic grocery catalog product: two raw pork chops with pale pink meat, clear bone shape, modest white fat edge, clean grocery presentation, NO grill marks, NO sauce, distinct from steak and ribs, transparent background, soft contact shadow, strong 44pt readability, no plate, no text, no brand, no hands",
  "sausage": "Photorealistic grocery catalog product: four raw linked sausages with natural casing and slight curve, pale-brown to pink raw sausage color, NO buns, NO grill marks, distinct from smooth hot dogs and bacon, transparent background, soft contact shadow, strong 44pt readability, no plate, no text, no brand, no hands",
  "ground-turkey": "Photorealistic grocery catalog product: compact mound of raw ground turkey with clear strand texture, visibly paler pink-beige than ground beef, NO patties, NO tray packaging, distinct from ground beef, transparent background, soft contact shadow, strong 44pt readability, no plate, no text, no brand, no hands",
  "turkey-breast": "Photorealistic grocery catalog product: two or three raw boneless turkey-breast portions, pale pink lean color, broad lean shape with subtle natural grain, NO sliced deli presentation, NO cooked crust, NO whole turkey, distinct from chicken breast and ham, transparent background, soft contact shadow, strong 44pt readability, no plate, no text, no brand, no hands",
  "salmon": "Photorealistic grocery catalog product: one raw salmon fillet with orange-pink flesh and visible white fat striations, clean grocery-counter cut, NO cooked grill marks, NO can, NO lemon garnish plate, distinct from tuna steak and shrimp, transparent background, soft contact shadow, strong 44pt readability, no plate, no text, no brand, no hands",
  "shrimp": "Photorealistic grocery catalog product: compact cluster of raw shrimp with shells and curved bodies, pale pink-gray raw color, NO cooked pink cocktail shrimp presentation, NO cocktail sauce, NO plate, distinct from fish sticks and salmon fillet, transparent background, soft contact shadow, strong 44pt readability, no text, no brand, no hands",
  "tuna-steak": "Photorealistic grocery catalog product: one clean raw tuna steak with deep red ahi flesh, thick steak cut clearly fish not beef, NO can, NO cooked grill marks, NO sushi platter, distinct from salmon fillet, transparent background, soft contact shadow, strong 44pt readability, no plate, no text, no brand, no hands",
  "rice-basmati": "Photorealistic grocery catalog product of one upright generic bag of long-grain basmati rice: clear or translucent window showing elongated slender white rice grains longer than ordinary white rice, blank cream/green panel with abstract grain icon only and NO readable text logos barcodes. Distinct from short-grain white rice bag and cooked rice bowl. Transparent background, soft contact shadow. No brands, hands, bowls of cooked rice, scenery.",
  "rice-white": "Photorealistic grocery catalog cutout of a dense mound of dry uncooked short-to-medium white rice grains in the foreground with individual oval kernels visible, plus a clear plastic retail bag of the same white rice behind it with blank white label strip and NO readable text. Recognition: dry white rice grains shorter/plumper than basmati, not bread loaf, not flour powder, not cooked rice. Transparent background, soft contact shadow. No brands, logos, barcodes, bowls, plates, hands, scenery.",
  "rice-noodles": "Photorealistic grocery catalog product: one compact dry nest or bundle of thin white translucent rice noodles, optional several straight dry strands beside it, pale thin rice noodles clearly different from yellow egg noodles and wheat pasta and rice grains, NO cooked bowl, NO chopsticks, NO vegetables, NO sauce, transparent background, soft contact shadow, strong 44pt readability, no text, no brand",
  "rice-vinegar": "Photorealistic grocery catalog product: one clear bottle containing nearly clear or very pale golden vinegar, simple neutral or dark cap, blank white or cream generic label with NO readable text, small group of white rice grains beside the bottle, NO apple, NO green oil tint, NO drinking glass, distinct from apple cider vinegar and avocado oil, transparent background, soft contact shadow, strong 44pt readability, no brand",
  "rice-cakes": "Photorealistic grocery catalog product: stack of three or four round puffed rice cakes in pale white-beige with visible puffed-grain texture, one cake slightly angled to show thickness, no packaging required, NO chocolate coating, NO plate, NO spread, clearly puffed rice cakes not crackers bread tortillas or cookies, transparent background, soft contact shadow, strong 44pt readability, no text, no brand",
  "pasta": "Photorealistic grocery catalog cutout of a neat nest or small pile of dry uncooked pale-yellow spaghetti strands (dry pasta, not cooked, not sauced), optional few penne pieces for shape variety kept secondary. Recognition: dry Italian pasta nest, not egg noodles, not rice noodles, not cooked pasta in bowl. Transparent background, soft contact shadow, dense fill. No box packaging text, brands, logos, readable text, plates, sauce, hands, scenery.",
  "pasta-sauce": "Photorealistic grocery catalog product: one medium generic glass jar of rich red ready-to-use pasta sauce with visible chunky tomato texture and subtle herb flecks, neutral lid, blank/generic label with NO readable text, NO pasta bowl, NO spaghetti, distinct from smooth canned tomato sauce, transparent background, soft contact shadow, strong 44pt readability, no brand",
  "flour": "Photorealistic grocery catalog product: one upright plain white paper flour sack with blank label NO readable text, small controlled pile or scoop of white flour powder beside the bag, clearly dry flour NOT sugar crystals NOT baking powder tin, NO baked goods, transparent background, soft contact shadow, strong 44pt readability, no brand, no scenery",
  "cereal": "Photorealistic grocery catalog product: compact pile of golden toasted corn flakes or ring cereal pieces spilling from a simple generic open cereal box with blank abstract label and NO readable text, NO bowl, NO milk, NO spoon, cereal shape clearly visible at 44pt, transparent background, soft contact shadow, strong 44pt readability, no brand, no hands, no scenery",
  "soup": "Photorealistic grocery catalog product: one open generic metal soup can with blank abstract label NO readable text, visible chunky soup contents at the open top, optional light steam cue, NO bowl, NO spoon, NO plate, transparent background, soft contact shadow, strong 44pt readability, no brand, no hands, no scenery",
  "peanut-butter": "Photorealistic grocery catalog product: one clear generic glass jar filled with tan creamy peanut butter showing swirl texture, blank abstract label NO readable text, several peanuts in shells or shelled peanuts beside the jar, NO bread, NO knife, NO almond butter look, distinct from almond-butter jar, transparent background, soft contact shadow, strong 44pt readability, no brand, no hands, no scenery",
  "almond-butter": "Photorealistic grocery catalog product: one clear generic jar containing smooth tan almond butter, neutral lid, jar open enough to show a smooth swirl, several whole almonds beside it, NO bread, NO toast, NO spoon covering contents, blank/generic label with NO readable text, visibly distinct from peanut butter (lighter tan, almond cue), transparent background, soft contact shadow, strong 44pt readability, no brand",
  "olive-oil": "Photorealistic grocery catalog product of one tall slender dark green glass olive-oil bottle with pour spout or screw cap, golden-green oil visible through glass, blank cream or olive-toned label with abstract olive leaf silhouette only and NO readable text logos barcodes. Distinct from avocado-oil (often darker/taller different shape) and vinegar bottles. Transparent background, soft contact shadow, strong bottle silhouette at 44pt. No brands, hands, olives pile required, scenery, plates.",
  "gochujang": "Photorealistic grocery catalog product: one short squat tub or jar of thick deep-red Korean chili paste gochujang, blank abstract label NO readable text, optional tiny chili pepper cue only, paste visible if lid open or through clear lid, NOT ketchup NOT tomato paste can, transparent background, soft contact shadow, strong 44pt readability, no brand, no scenery",
  "kimchi": "Photorealistic grocery catalog product: one clear glass jar filled with red fermented napa cabbage kimchi showing white cabbage ribs and chili coating, plain lid, blank abstract label NO readable text, NOT a bowl or plate serving, NOT sauerkraut pale color, transparent background, soft contact shadow, strong 44pt readability, no brand, no scenery",
  "hummus": "Photorealistic grocery catalog product: open generic short tub of smooth beige hummus with olive oil swirl and optional paprika dusting, blank tub with NO readable text, NO pita, NO vegetables surrounding, transparent background, soft contact shadow, strong 44pt readability, no brand, no hands",
  "coffee": "Photorealistic grocery catalog product: compact pile of dark roasted coffee beans beside a generic kraft coffee bag standing upright with blank abstract label and NO readable text, NO prepared coffee cup, NO creamer bottle, distinct from coffee-creamer and chocolate and mixed nuts, transparent background, soft contact shadow, strong 44pt readability, no brand, no hands, no scenery",
  "coffee-creamer": "Photorealistic grocery catalog product: one compact generic plastic coffee creamer bottle with curved body and flip-top cap, neutral cream beige or light-brown accents, optional small coffee-bean visual cue with NO readable text, no coffee cup, no brand, bottle silhouette not carton, distinct from heavy cream carton and milk, transparent background, soft contact shadow",
  "tea": "Photorealistic grocery catalog product: one generic tea box standing with several plain tea bags beside it, abstract color accents blank panels NO readable text, optional small loose tea leaves cue, NO prepared cup, NO teapot, distinct from coffee beans and coffee bag, transparent background, soft contact shadow, strong 44pt readability, no brand, no hands, no scenery",
  "water": "Photorealistic grocery catalog product: one clear plain plastic bottled-water bottle upright, fully transparent still water with NO bubbles and NO fruit cues, neutral blank white or pale-blue abstract label band with NO readable text, screw cap, distinct from sparkling soda cans and juice bottles, transparent background, soft contact shadow, strong 44pt readability, no glass, no brand, no hands, no scenery",
  "coconut-water": "Photorealistic grocery catalog product: one compact generic clear bottle or beverage carton of nearly clear thin coconut water, white and light-green abstract blank packaging with NO readable text, one opened young green coconut beside it as cue, NO straw, NO coconut milk can, NO thick white liquid, clearly distinct from coconut milk, transparent background, soft contact shadow, strong 44pt readability, no brand, no hands, no scenery",
  "orange-juice": "Photorealistic grocery catalog product: one generic orange juice carton upright, bright orange abstract blank label NO readable text, one orange fruit wedge or whole small orange beside carton, opaque orange juice cue on package graphics only, NO glass, distinct from apple juice bottle and juice boxes, transparent background, soft contact shadow, strong 44pt readability, no brand, no hands, no scenery",
  "cranberry-juice": "Photorealistic grocery catalog product: one generic clear bottle filled with deep ruby-red cranberry juice, restrained red abstract blank label with NO readable text, several fresh cranberries beside the bottle, NO tomato imagery, NO cocktail glass, distinct from grape juice purple tone, transparent background, soft contact shadow, strong 44pt readability, no brand, no hands, no scenery",
  "grape-juice": "Photorealistic grocery catalog product: one generic clear bottle filled with dark purple grape juice, restrained purple abstract blank label with NO readable text, small cluster of purple grapes beside the bottle, NO wine glass, NO cork, NO alcohol bottle styling, distinct from cranberry juice ruby-red, transparent background, soft contact shadow, strong 44pt readability, no brand, no hands, no scenery",
  "juice-boxes": "Photorealistic grocery catalog product: two small generic kids juice cartons standing together, simple fruit-color abstract accents, attached straws present and correctly formed, blank panels with NO readable text, NO nutrition panel, distinct from broth cartons and dairy milk cartons, transparent background, soft contact shadow, strong 44pt readability, no brand, no hands, no scenery",
  "beer": "Photorealistic grocery catalog product: one amber glass beer bottle upright with condensation, pale gold or amber beer liquid visible, blank foil neck wrap and blank body label abstract shapes NO readable text, NO mug, NO foam overflow scene, clearly alcoholic beer bottle silhouette distinct from root-beer soft-drink bottle and ginger-ale can, transparent background, soft contact shadow, strong 44pt readability, no brand, no hands, no scenery",
  "root-beer": "Photorealistic grocery catalog product: one generic dark-brown root-beer soda BOTTLE with cream and brown abstract blank label treatment, deep brown carbonated liquid visible, silhouette different from cola cans, NO ice-cream float, NO mug, NO glass, NO readable text, soft drink not beer, transparent background, soft contact shadow, strong 44pt readability, no brand, no hands, no scenery",
  "ginger-ale": "Photorealistic grocery catalog product: one generic pale-gold ginger-ale soda can, muted gold and green abstract blank packaging with NO readable text, small fresh ginger slice beside can as ingredient cue, pale-gold liquid not dark cola and not bright lemon-lime green, NO lemon wedge dominant styling, transparent background, soft contact shadow, strong 44pt readability, no brand, no hands, no scenery",
  "ice-cream": "Photorealistic grocery catalog product: one scoop or compact swirl of vanilla ice cream with soft peaks, optional second chocolate scoop, NO cone, NO bowl required if scoop stands alone, NO syrup drizzle scene, frozen dairy dessert look, transparent background, soft contact shadow, strong 44pt readability, no plate, no text, no brand",
  "frozen-pizza": "Photorealistic grocery catalog product: one small whole frozen pizza with visible cheese and restrained toppings, frosted frozen surface cue, NO box, NO slice being held, NO restaurant plating, transparent background, soft contact shadow, strong 44pt readability, no text, no brand, no hands",
  "pizza-rolls": "Photorealistic grocery catalog product: six or seven small golden pizza rolls with compact pillow-like rectangular shape, one opened piece showing red tomato filling and melted cheese, NO plate, NO dipping sauce, NO full pizza, NO readable packaging, distinct from chicken nuggets and dumplings, transparent background, soft contact shadow, strong 44pt readability, no text, no brand",
  "frozen-vegetables": "Photorealistic grocery catalog product: compact frozen mixed-vegetable grouping with visible peas carrots corn and green beans, slight frosted icy surface looking frozen not fresh, clean isolated grocery presentation, NO bowl, NO cooked steam, NO sauce, NO packaging text, distinct from fresh mixed greens and green peas, transparent background, soft contact shadow, strong 44pt readability, no brand",
  "chips": "Photorealistic grocery catalog product: compact pile of thin curved golden potato chips with visible light seasoning texture, optional plain generic empty bag with blank abstract label and NO readable text, NO salsa, NO bowl, NO tortilla triangle shapes, distinct potato-chip curves readable at 44pt, transparent background, soft contact shadow, strong 44pt readability, no brand, no hands, no scenery",
  "granola-bars": "Photorealistic grocery catalog product: two rectangular oat-and-nut granola bars with visible oat seed and nut texture, one bar partially broken to show interior crumb, NO branded wrapper, NO chocolate-bar appearance, distinct from dense protein bars, transparent background, soft contact shadow, strong 44pt readability, no plate, no text, no brand, no hands",
  "paper-towels": "Photorealistic grocery catalog product: two upright white paper-towel rolls taller and wider than toilet paper, visible embossed sheet edge and cardboard core, NO kitchen counter, NO packaging text, distinct from toilet-paper rolls by taller wider silhouette readable at 44pt, transparent background, soft contact shadow, strong 44pt readability, no brand, no hands, no scenery",
  "toilet-paper": "Photorealistic grocery catalog product: three or four clean white toilet-paper rolls stacked or grouped, visible cardboard cores and soft embossed texture, NO plastic packaging, NO bathroom scene, distinct from taller paper-towel rolls and tissues, transparent background, soft contact shadow, strong 44pt readability, no brand, no hands, no scenery",
  "dish-soap": "Photorealistic grocery catalog product: one clear or translucent squeeze bottle with flip-top cap filled with green or blue dish soap liquid, blank abstract label NO readable text, NO sponge, NO dishes, NO bubbles, NO sink, NO hands, distinct from hand-soap pump bottle and body-wash, transparent background, soft contact shadow, strong 44pt readability, no brand, no scenery",
  "disinfecting-wipes": "Photorealistic grocery catalog product: one short cylindrical cleaning-wipes canister with flip-top lid, one white wipe emerging slightly from opening, blank generic label NO readable text, NO cleaning scene, distinct from baby-wipes soft pack and tissues, transparent background, soft contact shadow, strong 44pt readability, no brand, no hands, no scenery",
  "toothpaste": "Photorealistic grocery catalog product: one plain toothpaste tube with cap beside or attached, optional small clean toothpaste curl, blank abstract label NO readable text, NO toothbrush required, NO bathroom scene, transparent background, soft contact shadow, strong 44pt readability, no brand, no hands, no scenery",
  "shampoo": "Photorealistic grocery catalog product: one tall generic shampoo bottle with flip-top cap, clear or blue or herbal-green packaging, blank abstract hair-like wave cue with NO readable text, NO hair, NO shower, NO person, distinct from conditioner creamier bottle and body-wash, transparent background, soft contact shadow, strong 44pt readability, no brand, no scenery",
  "conditioner": "Photorealistic grocery catalog product: one tall conditioner bottle with silhouette different from shampoo, creamier opaque pastel or warm packaging, blank abstract label NO readable text, NO hair, NO shower, distinct from shampoo bottle shape and color, transparent background, soft contact shadow, strong 44pt readability, no brand, no hands, no scenery",
  "diapers": "Photorealistic grocery catalog product: three clean folded disposable baby diapers stacked, soft white material with pale generic accent pattern, NO baby, NO readable packaging text, transparent background, soft contact shadow, strong 44pt readability, no brand, no hands, no scenery",
  "diaper-cream": "Photorealistic grocery catalog product: one small squeeze tube of diaper rash cream with blank pastel abstract label NO readable text, optional tiny controlled white cream dab only, NO diaper, NO baby, transparent background, soft contact shadow, strong 44pt readability, no brand, no hands, no scenery",
  "baby-wipes": "Photorealistic grocery catalog product: one compact soft-pack or pastel plastic baby-wipes tub with one wipe emerging, soft pastel generic design blank panels NO readable text, NO baby imagery, distinct from disinfecting-wipes hard canister, transparent background, soft contact shadow, strong 44pt readability, no brand, no hands, no scenery",
  "dog-food": "Photorealistic grocery catalog product: one upright generic dry dog-food bag with blank label and only a simple abstract paw cue NO readable text, several medium-large brown kibble pieces beside the bag, NO dog photograph NO bowl required, distinct from smaller cat-food kibble and flour bags, transparent background, soft contact shadow, strong 44pt readability, no brand, no scenery",
  "cat-food": "Photorealistic grocery catalog product: one smaller upright generic dry cat-food bag with blank label and only a tiny abstract paw cue NO readable text NO fish artwork, several smaller brown kibble pieces beside the bag, clearly smaller bag and finer kibble than dog food, NO cat NO wet-food can, transparent background, soft contact shadow, strong 44pt readability, no brand, no scenery",
  "pet-shampoo": "Photorealistic grocery catalog product: one compact squeeze or pump pet-care bottle with silhouette different from tall adult shampoo, restrained abstract paw-shaped cue on blank label NO readable text, pale liquid visible, NO animal photo NO person, distinct from human shampoo and conditioner bottles, transparent background, soft contact shadow, strong 44pt readability, no brand, no scenery",
  "flowers": "Photorealistic grocery catalog product: one compact grocery floral bouquet of roses and tulips with green stems and simple paper wrap cuff, fresh bloom colors, NO vase required, NO readable florist text, NO full room scene, transparent background, soft contact shadow, strong 44pt readability, no brand, no people, no scenery",
};

/** Do not auto-attach powdered/spice forms onto fresh produce via short roots. */
const PRODUCE_FORM_BLOCK_TOKENS = new Set([
  "powder",
  "seasoning",
  "spice",
  "extract",
  "seeds",
  "seed",
  "mix",
  "sauce",
  "paste",
  "chutney",
  "pesto",
  "chips",
]);

function assignKeywordsToProducts() {
  const products = CANONICAL_PRODUCTS.map((p) => ({
    ...p,
    keywords: [...new Set(p.roots)],
  }));

  const iconKeys = Object.keys(ITEM_ICONS).sort((a, b) => b.length - a.length);

  for (const key of iconKeys) {
    let bestProduct = null;
    let bestLen = 0;
    const nameTokens = categoryTokens(key);
    const keyHasProduceFormBlock = nameTokens.some((t) => PRODUCE_FORM_BLOCK_TOKENS.has(t));

    for (const product of products) {
      if (keyHasProduceFormBlock && product.categoryId === "produce") continue;
      for (const root of product.roots) {
        if (!keywordMatches(nameTokens, root)) continue;
        if (root.length > bestLen) {
          bestProduct = product;
          bestLen = root.length;
        }
      }
    }

    if (bestProduct && !bestProduct.keywords.includes(key)) {
      bestProduct.keywords.push(key);
    }
  }

  return products.map((p) => ({
    id: p.id,
    displayName: p.displayName,
    assetName: `product-${p.id}`,
    categoryId: p.categoryId,
    keywords: [...new Set(p.keywords)].sort((a, b) => b.length - a.length),
  }));
}

function productPrompt(product) {
  const specific = PRODUCT_PROMPTS[product.id];
  if (specific) return specific;
  return `${product.displayName.toLowerCase()}, single grocery product, soft 3D realistic illustration, transparent background, centered, no text, no brand`;
}

// ── Category catalog ────────────────────────────────────────────────────────

const categoryIds = Object.keys(CATEGORIES);
const categoryCatalog = categoryIds.map((id, index) => {
  const meta = CATEGORIES[id];
  return {
    id,
    displayName: meta.label,
    assetName: `category-${id}`,
    colorKey: id,
    colorHex: meta.color,
    sortOrder: (index + 1) * 10,
    keywords: CAT_KEYWORDS[id] ?? [],
  };
});

// ── Product catalog ─────────────────────────────────────────────────────────

const productCatalog = assignKeywordsToProducts();

// ── Legacy seed files (backward compatible) ─────────────────────────────────

const categoriesPayload = {
  categories: categoryIds.map((id) => ({
    id,
    label: CATEGORIES[id].label,
    color: CATEGORIES[id].color,
    emoji: CATEGORIES[id].emoji,
  })),
  keywords: CAT_KEYWORDS,
};

const storesPayload = {
  stores: Object.entries(DEFAULT_STORES).map(([id, meta]) => ({
    id,
    label: meta.label,
    domain: meta.domain,
    color: meta.color,
  })),
};

const emojiMap = Object.entries(ITEM_ICONS)
  .map(([keyword, emoji]) => ({ keyword, emoji }))
  .sort((a, b) => b.keyword.length - a.keyword.length);

// ── Asset manifest for image generation ─────────────────────────────────────

const CATEGORY_PROMPTS = {
  produce: "Photorealistic grocery catalog cutout of grouped fresh fruits and vegetables, soft 3D realistic illustration, transparent background",
  dairy: "Photorealistic grocery catalog cutout of milk carton, cheese wedge, and eggs grouped together, soft 3D illustration, transparent background",
  meat: "Photorealistic grocery catalog cutout of raw chicken breast and beef cuts grouped, soft 3D illustration, transparent background",
  seafood: "Photorealistic grocery catalog cutout of fish fillet and shrimp grouped, soft 3D illustration, transparent background",
  bakery: "Photorealistic grocery catalog cutout of loaf of bread, croissant, and bagel grouped, soft 3D illustration, transparent background",
  deli: "Photorealistic grocery catalog cutout of sliced deli meats and hummus grouped, soft 3D illustration, transparent background",
  frozen: "Photorealistic grocery catalog cutout of frozen vegetables and ice cream grouped, soft 3D illustration, transparent background",
  pantry: "Photorealistic grocery catalog cutout of rice bag, pasta box, and canned goods grouped, soft 3D illustration, transparent background",
  snacks: "Photorealistic grocery catalog cutout of chips bag, cookies, and popcorn grouped, soft 3D illustration, transparent background",
  condiments: "Photorealistic grocery catalog cutout of spice jars, hot sauce, and olive oil bottle grouped, soft 3D illustration, transparent background",
  drinks: "Photorealistic grocery catalog cutout of water bottle, juice carton, and coffee bag grouped, soft 3D illustration, transparent background",
  household: "Photorealistic grocery catalog cutout of paper towels, dish soap, and cleaning supplies grouped, soft 3D illustration, transparent background",
  health: "Photorealistic grocery catalog cutout of shampoo bottle, toothpaste, and vitamins grouped, soft 3D illustration, transparent background",
  baby: "Photorealistic grocery catalog cutout of diapers and baby formula grouped, soft 3D illustration, transparent background",
  pet: "Photorealistic grocery catalog cutout of dog food bag and pet treats grouped, soft 3D illustration, transparent background",
  floral: "Photorealistic grocery catalog cutout of fresh flower bouquet with roses and tulips grouped, soft 3D illustration, transparent background",
  misc: "Photorealistic grocery catalog cutout of generic grocery bag with mixed items, soft 3D illustration, transparent background",
};

const assetManifest = [
  ...categoryCatalog.map((c) => ({
    assetName: c.assetName,
    type: "category",
    categoryId: c.id,
    displayName: c.displayName,
    priority: 1,
    prompt: CATEGORY_PROMPTS[c.id] ?? `grouped ${c.displayName.toLowerCase()} groceries, soft 3D realistic illustration, transparent background, no text`,
  })),
  ...productCatalog.map((p, index) => ({
    assetName: p.assetName,
    type: "product",
    productId: p.id,
    categoryId: p.categoryId,
    displayName: p.displayName,
    priority: index < 20 ? 2 : 3,
    prompt: productPrompt(p),
  })),
];

// ── Write files ─────────────────────────────────────────────────────────────

writeFileSync(join(outDir, "category_catalog.json"), JSON.stringify(categoryCatalog, null, 2) + "\n");
writeFileSync(join(outDir, "product_catalog.json"), JSON.stringify(productCatalog, null, 2) + "\n");
writeFileSync(join(outDir, "asset_manifest.json"), JSON.stringify(assetManifest, null, 2) + "\n");
writeFileSync(join(outDir, "category_keywords.json"), JSON.stringify(categoriesPayload, null, 2) + "\n");
writeFileSync(join(outDir, "default_stores.json"), JSON.stringify(storesPayload, null, 2) + "\n");
writeFileSync(join(outDir, "item_emoji_map.json"), JSON.stringify(emojiMap, null, 2) + "\n");

// Legacy product map for migration period
const legacyProductMap = productCatalog.flatMap((p) =>
  p.keywords.slice(0, 3).map((keyword) => ({ keyword, assetName: p.assetName }))
);
writeFileSync(join(outDir, "product_image_map.json"), JSON.stringify(legacyProductMap, null, 2) + "\n");

// Prompt manifest for artwork generation (product-specific)
const promptManifest = productCatalog.map((p) => ({
  productId: p.id,
  assetName: p.assetName,
  displayName: p.displayName,
  categoryId: p.categoryId,
  prompt: productPrompt(p),
}));
writeFileSync(
  join(__dirname, "../GroceryListiOS/PRODUCT_IMAGE_PROMPTS.json"),
  JSON.stringify(promptManifest, null, 2) + "\n"
);

console.log(`Wrote category_catalog.json (${categoryCatalog.length} categories)`);
console.log(`Wrote product_catalog.json (${productCatalog.length} products)`);
console.log(`Wrote asset_manifest.json (${assetManifest.length} assets)`);
console.log(`Wrote category_keywords.json, default_stores.json, item_emoji_map.json`);
console.log(`Wrote product_image_map.json (${legacyProductMap.length} keyword mappings)`);
console.log(`Wrote PRODUCT_IMAGE_PROMPTS.json (${promptManifest.length} product prompts)`);
