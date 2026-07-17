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
  { id: "lettuce", displayName: "Lettuce", categoryId: "produce", roots: ["lettuce", "romaine", "iceberg lettuce", "spring mix"] },

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
  "milk-whole": "White milk carton with blue accent stripe and milk-drop icon, soft 3D grocery illustration, transparent background, no text, no brand",
  "milk-oat": "Warm tan oat milk carton with large oat stalk graphics, soft 3D grocery illustration, transparent background, no text, no brand",
  "milk-almond": "Cream almond milk carton with almond graphics, soft 3D grocery illustration, transparent background, no text, no brand",
  "milk-soy": "Light green soy milk carton with soy pod graphics, soft 3D grocery illustration, transparent background, no text, no brand",
  "milk-coconut": "Unbranded white coconut milk can beside one opened coconut half, clearly non-dairy, single grocery product composition, soft 3D grocery illustration, transparent background, no text, no brand",
  "milk-condensed": "Small unbranded metal can of sweetened condensed milk with a spoon showing thick pale cream, soft 3D grocery illustration, transparent background, no text, no brand",
  "milk-evaporated": "Small unbranded metal can of evaporated milk with a small pouring cup of light milk, visually distinct from condensed milk, soft 3D grocery illustration, transparent background, no text, no brand",
  "eggs-white": "Top-down grey egg carton with six visible white eggs, soft 3D grocery illustration, transparent background, no text, no brand",
  "eggs-brown": "Top-down egg carton with brown eggs, soft 3D grocery illustration, transparent background, no text, no brand",
  "egg-noodles": "Bundle of dry curled yellow egg noodles, clearly noodles and not eggs, soft 3D grocery illustration, transparent background, no text, no brand",
  "butter": "Stick of yellow butter with partial paper wrapper, soft 3D grocery illustration, transparent background, no text, no brand",
  "ghee": "Clear glass jar filled with rich golden clarified butter and a small spoon, soft 3D grocery illustration, transparent background, no text, no brand",
  "cheese": "Wedge of yellow cheddar cheese, soft 3D grocery illustration, transparent background, no text, no brand",
  "cream-cheese": "Opened unbranded cream cheese tub with smooth white spread and a small spreading knife, soft 3D grocery illustration, transparent background, no text, no brand",
  "cottage-cheese": "Small open unbranded tub containing visible white cottage-cheese curds, soft 3D grocery illustration, transparent background, no text, no brand",
  "paneer": "Fresh white paneer block with several neat cubes, no plate or text, soft 3D grocery illustration, transparent background, no text, no brand",
  "yogurt": "Photorealistic grocery cutout of a pastel blue single-serve yogurt cup with peeled foil lid, smooth white yogurt topped with a visible strawberry fruit swirl and one fresh strawberry half, clearly smooth yogurt not lumpy cottage cheese, isolated transparent background, centered, soft studio contact shadow, no text, no brand, no plate",
  "bananas": "Bunch of yellow bananas, soft 3D grocery illustration, transparent background, no text, no brand",
  "banana-bread": "Sliced loaf of banana bread showing moist crumb and banana cue, soft 3D grocery illustration, transparent background, no text, no brand",
  "apples": "Two fresh red apples, soft 3D grocery illustration, transparent background, no text, no brand",
  "apple-juice": "Unbranded clear bottle of amber apple juice with a small apple cue, soft 3D grocery illustration, transparent background, no text, no brand",
  "apple-cider-vinegar": "Amber glass vinegar bottle with a small apple visual cue, no readable label, soft 3D grocery illustration, transparent background, no text, no brand",
  "tomatoes": "Cluster of ripe red tomatoes on the vine, soft 3D grocery illustration, transparent background, no text, no brand",
  "tomato-sauce": "Unbranded glass jar filled with smooth red tomato sauce and a tomato-and-basil visual cue, soft 3D grocery illustration, transparent background, no text, no brand",
  "tomato-paste": "Small unbranded tomato-paste can with dense dark-red paste visible on a spoon, soft 3D grocery illustration, transparent background, no text, no brand",
  "canned-tomatoes": "Open unbranded metal can with diced red tomatoes visibly inside, soft 3D grocery illustration, transparent background, no text, no brand",
  "onions": "Two whole yellow onions with papery skins, soft 3D grocery illustration, transparent background, no text, no brand",
  "green-onions": "Bunch of fresh green onions with white bulbs and long green stalks, soft 3D grocery illustration, transparent background, no text, no brand",
  "shallots": "Cluster of reddish-brown shallots, soft 3D grocery illustration, transparent background, no text, no brand",
  "potatoes": "Three russet potatoes, soft 3D grocery illustration, transparent background, no text, no brand",
  "sweet-potatoes": "Two orange-fleshed sweet potatoes with copper skin, soft 3D grocery illustration, transparent background, no text, no brand",
  "cilantro": "Bundle of feathery cilantro leaves with tied stems, soft 3D grocery illustration, transparent background, no text, no brand",
  "spinach": "Pile of dark broad crinkled spinach leaves, soft 3D grocery illustration, transparent background, no text, no brand",
  "avocados": "Whole avocado beside a halved avocado showing green flesh and pit, soft 3D grocery illustration, transparent background, no text, no brand",
  "avocado-oil": "Tall clear bottle of golden-green avocado oil with a small avocado cue, soft 3D grocery illustration, transparent background, no text, no brand",
  "lemons": "Two bright yellow lemons, soft 3D grocery illustration, transparent background, no text, no brand",
  "limes": "Two bright green limes, soft 3D grocery illustration, transparent background, no text, no brand",
  "lettuce": "Fresh green head of lettuce, soft 3D grocery illustration, transparent background, no text, no brand",
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
  "chicken-drumsticks": "Photorealistic raw chicken drumsticks clustered together showing skin and bone end, grocery catalog cutout, transparent background, soft contact shadow, no plate, no text, no brand",
  "bread-loaf": "Sliced sandwich bread loaf, soft 3D grocery illustration, transparent background, no text, no brand",
  "bagels": "Stack of plain bagels, soft 3D grocery illustration, transparent background, no text, no brand",
  "tortillas": "Stack of flour tortillas, soft 3D grocery illustration, transparent background, no text, no brand",
  "naan": "Warm bubbled naan flatbread, soft 3D grocery illustration, transparent background, no text, no brand",
  "roti": "Round thin whole-wheat roti flatbread, soft 3D grocery illustration, transparent background, no text, no brand",
  "paratha": "Flaky layered golden-brown paratha, soft 3D grocery illustration, transparent background, no text, no brand",
  "pita": "Round pita bread pocket slightly open, soft 3D grocery illustration, transparent background, no text, no brand",
  "chicken-breast": "Raw chicken breast fillets, soft 3D grocery illustration, transparent background, no text, no brand",
  "chicken-thighs": "Raw chicken thighs with skin, soft 3D grocery illustration, transparent background, no text, no brand",
  "chicken-wings": "Raw chicken wings clustered together, soft 3D grocery illustration, transparent background, no text, no brand",
  "rotisserie-chicken": "Whole cooked golden-brown rotisserie chicken in a simple clear deli tray, soft 3D grocery illustration, transparent background, no text, no brand",
  "chicken-broth": "Unbranded broth carton with a small bowl of clear golden chicken broth, no readable text, soft 3D grocery illustration, transparent background, no text, no brand",
  "ground-beef": "Portion of raw ground beef, soft 3D grocery illustration, transparent background, no text, no brand",
  "steak": "Raw beef steak cut, soft 3D grocery illustration, transparent background, no text, no brand",
  "bacon": "Strips of raw bacon, soft 3D grocery illustration, transparent background, no text, no brand",
  "pork": "Raw pork chops, soft 3D grocery illustration, transparent background, no text, no brand",
  "sausage": "Linked raw sausages, soft 3D grocery illustration, transparent background, no text, no brand",
  "ground-turkey": "Portion of raw ground turkey meat, soft 3D grocery illustration, transparent background, no text, no brand",
  "turkey-breast": "Sliced roasted turkey breast deli cuts, soft 3D grocery illustration, transparent background, no text, no brand",
  "salmon": "Raw salmon fillet, soft 3D grocery illustration, transparent background, no text, no brand",
  "shrimp": "Raw shrimp clustered, soft 3D grocery illustration, transparent background, no text, no brand",
  "tuna-steak": "Raw tuna steak showing deep red flesh, clearly fish not beef, soft 3D grocery illustration, transparent background, no text, no brand",
  "rice-basmati": "Bag of long-grain basmati rice, soft 3D grocery illustration, transparent background, no text, no brand",
  "rice-white": "Clear plastic bag of white rice grains, soft 3D grocery illustration, transparent background, no text, no brand",
  "rice-noodles": "Bundle of thin dry white translucent rice noodles, clearly different from rice grains, soft 3D grocery illustration, transparent background, no text, no brand",
  "rice-vinegar": "Clear bottle of pale rice vinegar with a small rice cue, soft 3D grocery illustration, transparent background, no text, no brand",
  "rice-cakes": "Stack of round puffed rice cakes, soft 3D grocery illustration, transparent background, no text, no brand",
  "pasta": "Nest of dry spaghetti pasta, soft 3D grocery illustration, transparent background, no text, no brand",
  "pasta-sauce": "Unbranded glass jar of red pasta sauce with basil and a small pasta cue, soft 3D grocery illustration, transparent background, no text, no brand",
  "flour": "White paper flour bag with a scoop of flour, soft 3D grocery illustration, transparent background, no text, no brand",
  "cereal": "Bowl of breakfast cereal with flakes, soft 3D grocery illustration, transparent background, no text, no brand",
  "soup": "Open can of soup with steam cue, soft 3D grocery illustration, transparent background, no text, no brand",
  "peanut-butter": "Open jar of peanut butter with a knife, soft 3D grocery illustration, transparent background, no text, no brand",
  "almond-butter": "Open jar of almond butter with visible almond pieces and whole almonds beside it, soft 3D grocery illustration, transparent background, no text, no brand",
  "olive-oil": "Green glass bottle of olive oil, soft 3D grocery illustration, transparent background, no text, no brand",
  "gochujang": "Squat red Korean paste tub with chili cue, soft 3D grocery illustration, transparent background, no text, no brand",
  "kimchi": "Bowl of red kimchi, soft 3D grocery illustration, transparent background, no text, no brand",
  "hummus": "Bowl of hummus with olive oil swirl, soft 3D grocery illustration, transparent background, no text, no brand",
  "coffee": "Bag of coffee beans with a coffee cup cue, soft 3D grocery illustration, transparent background, no text, no brand",
  "coffee-creamer": "Small unbranded creamer bottle beside a coffee cup with lightened coffee, soft 3D grocery illustration, transparent background, no text, no brand",
  "tea": "Box of tea bags with loose tea leaves, soft 3D grocery illustration, transparent background, no text, no brand",
  "water": "Clear plastic water bottle, soft 3D grocery illustration, transparent background, no text, no brand",
  "coconut-water": "Clear bottle of coconut water with a coconut half cue, soft 3D grocery illustration, transparent background, no text, no brand",
  "orange-juice": "Orange juice carton with orange cue, soft 3D grocery illustration, transparent background, no text, no brand",
  "cranberry-juice": "Bottle of deep red cranberry juice with cranberry cue, soft 3D grocery illustration, transparent background, no text, no brand",
  "grape-juice": "Bottle of purple grape juice with grape cluster cue, soft 3D grocery illustration, transparent background, no text, no brand",
  "juice-boxes": "Two small unbranded juice boxes with straws, soft 3D grocery illustration, transparent background, no text, no brand",
  "beer": "Amber glass beer bottle with condensation, soft 3D grocery illustration, transparent background, no text, no brand",
  "root-beer": "Unbranded dark root-beer soda bottle and small frothy soda mug, clearly a soft drink and not alcoholic beer, soft 3D grocery illustration, transparent background, no text, no brand",
  "ginger-ale": "Unbranded pale-gold soda can with fresh ginger root visual cue, clearly a soft drink, soft 3D grocery illustration, transparent background, no text, no brand",
  "ice-cream": "Ice cream scoop in a bowl, soft 3D grocery illustration, transparent background, no text, no brand",
  "frozen-pizza": "Frozen pizza in an open box, soft 3D grocery illustration, transparent background, no text, no brand",
  "pizza-rolls": "Plate of golden pizza rolls / pizza bites showing melted cheese, soft 3D grocery illustration, transparent background, no text, no brand",
  "frozen-vegetables": "Bag of mixed frozen vegetables, soft 3D grocery illustration, transparent background, no text, no brand",
  "chips": "Open bag of potato chips with chips spilling, soft 3D grocery illustration, transparent background, no text, no brand",
  "granola-bars": "Stack of granola bars, soft 3D grocery illustration, transparent background, no text, no brand",
  "paper-towels": "Roll of paper towels, soft 3D grocery illustration, transparent background, no text, no brand",
  "toilet-paper": "Roll of toilet paper, soft 3D grocery illustration, transparent background, no text, no brand",
  "dish-soap": "Bottle of dish soap with sponge cue, soft 3D grocery illustration, transparent background, no text, no brand",
  "disinfecting-wipes": "Tub of disinfecting cleaning wipes with a wipe partially pulled out, soft 3D grocery illustration, transparent background, no text, no brand",
  "toothpaste": "Toothpaste tube with toothbrush cue, soft 3D grocery illustration, transparent background, no text, no brand",
  "shampoo": "Bottle of shampoo, soft 3D grocery illustration, transparent background, no text, no brand",
  "conditioner": "Bottle of hair conditioner visually distinct from shampoo, soft pastel bottle, soft 3D grocery illustration, transparent background, no text, no brand",
  "diapers": "Stack of folded baby diapers, soft 3D grocery illustration, transparent background, no text, no brand",
  "diaper-cream": "Tube of diaper rash cream with a soft baby-care cue, soft 3D grocery illustration, transparent background, no text, no brand",
  "baby-wipes": "Package of baby wipes, soft 3D grocery illustration, transparent background, no text, no brand",
  "dog-food": "Brown dog food bag with bone icon and kibble bowl, soft 3D grocery illustration, transparent background, no text, no brand",
  "cat-food": "Cat food bag with fish cue and kibble bowl, soft 3D grocery illustration, transparent background, no text, no brand",
  "pet-shampoo": "Bottle of pet shampoo with a small paw-print cue, soft 3D grocery illustration, transparent background, no text, no brand",
  "flowers": "Fresh flower bouquet with roses and tulips, soft 3D grocery illustration, transparent background, no text, no brand",
};

/** Do not auto-attach powdered/spice forms onto fresh produce via short roots. */
const PRODUCE_FORM_BLOCK_TOKENS = new Set(["powder", "seasoning", "spice", "extract"]);

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
  produce: "grouped fresh fruits and vegetables, soft 3D realistic illustration, transparent background",
  dairy: "milk carton, cheese wedge, and eggs grouped together, soft 3D illustration, transparent background",
  meat: "raw chicken breast and beef cuts grouped, soft 3D illustration, transparent background",
  seafood: "fish fillet and shrimp grouped, soft 3D illustration, transparent background",
  bakery: "loaf of bread, croissant, and bagel grouped, soft 3D illustration, transparent background",
  deli: "sliced deli meats and hummus grouped, soft 3D illustration, transparent background",
  frozen: "frozen vegetables and ice cream grouped, soft 3D illustration, transparent background",
  pantry: "rice bag, pasta box, and canned goods grouped, soft 3D illustration, transparent background",
  snacks: "chips bag, cookies, and popcorn grouped, soft 3D illustration, transparent background",
  condiments: "spice jars, hot sauce, and olive oil bottle grouped, soft 3D illustration, transparent background",
  drinks: "water bottle, juice carton, and coffee bag grouped, soft 3D illustration, transparent background",
  household: "paper towels, dish soap, and cleaning supplies grouped, soft 3D illustration, transparent background",
  health: "shampoo bottle, toothpaste, and vitamins grouped, soft 3D illustration, transparent background",
  baby: "diapers and baby formula grouped, soft 3D illustration, transparent background",
  pet: "dog food bag and pet treats grouped, soft 3D illustration, transparent background",
  floral: "fresh flower bouquet with roses and tulips grouped, soft 3D illustration, transparent background",
  misc: "generic grocery bag with mixed items, soft 3D illustration, transparent background",
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
