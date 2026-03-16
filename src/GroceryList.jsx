import { useState, useRef, useCallback, useEffect } from "react";

const LINE_H = 44;
const PER_PAGE = 10;

const CATEGORIES = {
  produce:    { label: "Produce",           color: "#4a7c59", emoji: "🥕" },
  dairy:      { label: "Dairy & Eggs",      color: "#c4883c", emoji: "🥛" },
  meat:       { label: "Meat & Poultry",    color: "#a63d40", emoji: "🥩" },
  seafood:    { label: "Seafood",           color: "#3d7ea6", emoji: "🦐" },
  bakery:     { label: "Bakery",            color: "#b08968", emoji: "🍞" },
  deli:       { label: "Deli",              color: "#8c6e54", emoji: "🥪" },
  frozen:     { label: "Frozen",            color: "#5e7ea8", emoji: "🧊" },
  pantry:     { label: "Pantry & Grains",   color: "#7a6c5d", emoji: "🫙" },
  snacks:     { label: "Snacks",            color: "#c2855a", emoji: "🍪" },
  condiments: { label: "Condiments & Spices",color:"#a0855b", emoji: "🌶️" },
  drinks:     { label: "Beverages",         color: "#6a8e7f", emoji: "🥤" },
  household:  { label: "Household",         color: "#6b7d8e", emoji: "🧻" },
  health:     { label: "Health & Beauty",   color: "#8b6f8e", emoji: "🧴" },
  baby:       { label: "Baby & Kids",       color: "#d4889a", emoji: "🍼" },
  pet:        { label: "Pet",               color: "#7a8b6f", emoji: "🐾" },
};

const CAT_KEYWORDS = {
  produce: [
    "apple","apples","banana","bananas","tomato","tomatoes","cherry tomato","grape tomato",
    "lettuce","romaine","spinach","kale","arugula","spring mix","mixed greens",
    "onion","onions","red onion","green onion","scallion","scallions","shallot","shallots",
    "garlic","ginger","turmeric root",
    "potato","potatoes","sweet potato","sweet potatoes","yam","yams","aloo",
    "carrot","carrots","baby carrots","celery","radish","beet","beets","turnip",
    "broccoli","cauliflower","gobi","brussels sprouts","cabbage","bok choy",
    "pepper","peppers","bell pepper","jalapeno","serrano","habanero","poblano",
    "cucumber","cucumbers","zucchini","squash","butternut squash","pumpkin","kaddu",
    "corn","corn on the cob","bhutta","avocado","avocados",
    "mushroom","mushrooms","portobello","shiitake","cremini",
    "asparagus","artichoke","eggplant","baingan","okra","bhindi","green beans","snap peas","snow peas",
    "strawberry","strawberries","blueberry","blueberries","raspberry","raspberries","blackberry","blackberries",
    "cherry","cherries","cranberry","cranberries",
    "lemon","lemons","lime","limes","orange","oranges","mandarin","clementine","grapefruit",
    "grape","grapes","mango","mangoes","aam","papaya","guava","amrud","passion fruit","dragon fruit","lychee","litchi","jackfruit","kathal",
    "pineapple","watermelon","tarbooz","cantaloupe","honeydew","melon",
    "peach","peaches","nectarine","plum","plums","apricot","fig","figs","anjeer","date","dates","khajoor","pomegranate","anaar",
    "pear","pears","kiwi","coconut","nariyal",
    "cilantro","dhaniya","basil","tulsi","mint","pudina","parsley","dill","suva","rosemary","thyme","sage","chives","tarragon",
    "curry leaves","kadi patta","methi","fenugreek leaves","drumstick","moringa","sahjan",
    "fruit","fruits","vegetable","vegetables","veggies","sabzi","salad","herbs","fresh herbs","greens",
  ],
  dairy: [
    "milk","whole milk","2% milk","skim milk","buttermilk","chaas","lactose free milk",
    "cheese","shredded cheese","sliced cheese","string cheese",
    "mozzarella","parmesan","cheddar","swiss","provolone","gouda","brie","feta","ricotta","goat cheese",
    "cream cheese","cottage cheese","queso",
    "yogurt","greek yogurt","yoghurt","dahi",
    "butter","unsalted butter","salted butter","margarine","makhan",
    "cream","heavy cream","whipping cream","half and half","sour cream","malai",
    "eggs","egg","egg whites","dozen eggs","anda",
    "ghee","paneer","curd","khoya","mawa","coffee creamer","creamer","lassi",
  ],
  meat: [
    "chicken","chicken breast","chicken thigh","chicken thighs","chicken wings","chicken legs","chicken drumsticks",
    "whole chicken","rotisserie chicken","chicken tender","chicken tenders","murgh",
    "beef","ground beef","steak","sirloin","ribeye","filet mignon","flank steak","chuck roast",
    "roast","pot roast","brisket","beef stew",
    "pork","pork chop","pork chops","pork loin","pork tenderloin","pork belly",
    "bacon","turkey bacon","canadian bacon",
    "sausage","sausages","italian sausage","bratwurst","kielbasa","chorizo",
    "turkey","turkey breast","ground turkey",
    "lamb","lamb chop","lamb chops","lamb leg","rack of lamb","keema","gosht",
    "veal","bison","venison","duck",
    "meatball","meatballs","patties","burger patties",
    "ham","spiral ham","ribs","baby back ribs","spare ribs",
    "hot dog","hot dogs","jerky","beef jerky",
  ],
  seafood: [
    "shrimp","prawns","jhinga","scallop","scallops",
    "salmon","salmon fillet","smoked salmon","lox",
    "tuna","ahi tuna","tuna steak","canned tuna",
    "cod","tilapia","halibut","mahi mahi","swordfish","trout","catfish","bass","snapper","pomfret","rohu","surmai",
    "fish","fish fillet","fish sticks","machhi",
    "crab","crab legs","crab meat","lobster","lobster tail",
    "clam","clams","mussel","mussels","oyster","oysters",
    "calamari","squid","octopus","anchovies","sardines","sushi","sashimi",
  ],
  bakery: [
    "bread","white bread","wheat bread","whole wheat bread","multigrain bread","sourdough","rye bread",
    "bagel","bagels","everything bagel","croissant","croissants",
    "muffin","muffins","blueberry muffin",
    "tortilla","tortillas","flour tortilla","corn tortilla","wrap","wraps",
    "pita","pita bread","naan","roti","chapati","paratha","puri","bhatura","kulcha","flatbread",
    "bun","buns","hamburger bun","hot dog bun","brioche","pav",
    "roll","rolls","dinner rolls","ciabatta","baguette","focaccia","cornbread",
    "english muffin","english muffins",
    "cake","cupcake","cupcakes","birthday cake","pie","pie crust",
    "cookie","cookies","brownie","brownies",
    "donut","donuts","doughnut","doughnuts",
    "pastry","pastries","scone","scones","cinnamon roll","cinnamon rolls",
    "cracker","crackers","graham crackers","rusks","khari","mathri",
  ],
  deli: [
    "lunch meat","deli meat","sliced turkey","sliced ham","sliced chicken",
    "salami","pepperoni","prosciutto","mortadella","bologna","pastrami",
    "hummus","guacamole","pico de gallo",
    "prepared salad","potato salad","coleslaw","macaroni salad",
    "rotisserie","deli sandwich",
    "olive","olives","pickle","pickles","pickled","achar","charcuterie",
  ],
  frozen: [
    "ice cream","gelato","sorbet","kulfi","frozen yogurt","popsicle","popsicles",
    "frozen pizza","frozen meal","frozen meals","frozen dinner","tv dinner",
    "frozen vegetables","frozen veggies","frozen fruit","frozen berries",
    "frozen chicken","frozen shrimp","frozen fish",
    "frozen waffles","waffles","eggo",
    "tater tots","french fries","frozen fries","hash browns",
    "pizza rolls","hot pockets","pot pie",
    "frozen burrito","frozen burritos","ice","ice cubes",
    "frozen dumplings","dumplings","gyoza","samosa","samosas","frozen paratha","frozen naan",
    "cool whip","whipped topping",
  ],
  pantry: [
    "rice","white rice","brown rice","basmati","basmati rice","jasmine rice","wild rice","sushi rice","chawal",
    "pasta","spaghetti","penne","fusilli","rigatoni","macaroni","linguine","fettuccine","lasagna","angel hair",
    "noodles","ramen","udon","soba","rice noodles","egg noodles","lo mein","maggi","sevai","vermicelli","seviyan",
    "flour","all purpose flour","maida","bread flour","almond flour","coconut flour","whole wheat flour","atta","besan","gram flour","rice flour","ragi flour","jowar flour",
    "sugar","brown sugar","powdered sugar","shakkar","gur","jaggery","mishri",
    "baking soda","baking powder","yeast","cornstarch","cream of tartar",
    "vanilla","vanilla extract","cocoa powder",
    "oats","oatmeal","granola","muesli","daliya","dalia","cereal","cheerios","cornflakes",
    "beans","black beans","kidney beans","rajma","pinto beans","refried beans","chickpeas","chole","chana","garbanzo",
    "lentils","dal","moong dal","toor dal","masoor dal","urad dal","chana dal","split peas","sambhar powder",
    "canned tomatoes","diced tomatoes","crushed tomatoes","tomato paste","tomato sauce","marinara",
    "canned corn","canned beans","canned soup","canned tuna","canned chicken",
    "broth","stock","chicken broth","chicken stock","beef broth","vegetable broth","bone broth",
    "soup","ramen packet","sabudhana","tapioca","sago",
    "quinoa","couscous","bulgur","farro","barley","polenta","grits",
    "poha","flattened rice","puffed rice","murmura","breadcrumbs","panko",
    "coconut milk","evaporated milk","condensed milk",
    "protein powder","protein bar","protein bars",
    "chia seeds","flax seeds","alsi","hemp seeds","sunflower seeds","pumpkin seeds","sesame seeds","til",
    "nuts","almonds","badam","cashews","kaju","walnuts","akhrot","pecans","peanuts","moongfali","pistachios","pista","macadamia","mixed nuts",
    "peanut butter","almond butter","nutella","tahini",
    "jelly","jam","preserves","marmalade",
    "honey","shahad","maple syrup","agave","molasses","corn syrup",
    "papad","appalam","sev","bhujia","namkeen",
    "idli mix","dosa mix","upma mix","khichdi","rava","suji","semolina",
    "tofu","tempeh","seitan","ravioli","tortellini",
  ],
  snacks: [
    "chips","potato chips","tortilla chips","corn chips","pita chips","veggie chips",
    "popcorn","microwave popcorn","pretzels","cheese puffs","cheetos","doritos",
    "trail mix","granola bar","granola bars","energy bar","energy bars","clif bar",
    "candy","chocolate","chocolate bar","gummy bears","gummy candy","gummy worms","m&ms","skittles",
    "fruit snack","fruit snacks","dried fruit","raisins","dried mango","dried cranberries",
    "rice cakes","rice cake","beef jerky","slim jim",
    "seaweed","seaweed snack","nori","pudding","jello","fruit cup",
    "snack bar","cheese crackers","goldfish",
    "salsa","queso dip","bean dip","french onion dip","ranch dip",
    "murukku","chakli","mixture","chivda","khakhra",
  ],
  condiments: [
    "ketchup","mustard","yellow mustard","dijon mustard","honey mustard",
    "mayo","mayonnaise",
    "hot sauce","sriracha","tabasco","frank's","cholula","gochujang","sambal",
    "soy sauce","tamari","fish sauce","oyster sauce","hoisin","teriyaki","worcestershire",
    "vinegar","white vinegar","apple cider vinegar","balsamic vinegar","rice vinegar",
    "oil","olive oil","extra virgin olive oil","vegetable oil","canola oil","coconut oil","avocado oil","sesame oil","mustard oil","sarson ka tel",
    "salad dressing","ranch","italian dressing","caesar dressing","vinaigrette",
    "bbq sauce","barbecue sauce","steak sauce",
    "relish","chutney","cranberry sauce","applesauce",
    "salt","sea salt","kosher salt","pink salt","sendha namak","kala namak","black salt",
    "pepper","black pepper","white pepper","red pepper flakes","cayenne","kali mirch",
    "cumin","jeera","turmeric","haldi","cinnamon","dalchini","paprika","smoked paprika",
    "chili powder","lal mirch","garlic powder","onion powder",
    "oregano","thyme","rosemary","bay leaves","tej patta","curry powder",
    "garam masala","chaat masala","pav bhaji masala","biryani masala","kitchen king masala","sambhar masala",
    "amchur","dry mango powder","hing","asafoetida","ajwain","carom seeds",
    "fennel seeds","saunf","mustard seeds","rai","fenugreek seeds","methi seeds","kalonji","nigella seeds",
    "cardamom","elaichi","clove","laung","nutmeg","jaiphal","star anise","coriander powder","dhania powder",
    "italian seasoning","everything bagel seasoning","taco seasoning","old bay",
    "bouillon","bouillon cube","seasoning",
    "pesto","alfredo sauce","pasta sauce","pizza sauce",
    "cooking spray","pam","tamarind","imli","kokum",
  ],
  drinks: [
    "water","bottled water","sparkling water","seltzer","mineral water","tonic water",
    "juice","orange juice","apple juice","cranberry juice","grape juice","lemonade","nimbu pani","aam panna",
    "soda","cola","coke","pepsi","sprite","ginger ale","root beer","thumbs up","limca","maaza",
    "coffee","ground coffee","coffee beans","instant coffee","k-cups","cold brew","espresso",
    "tea","green tea","black tea","herbal tea","chai","matcha","iced tea","chai patti","tea leaves",
    "beer","ipa","lager","ale","stout","craft beer","hard seltzer",
    "wine","red wine","white wine","rose","champagne","prosecco",
    "liquor","vodka","whiskey","rum","tequila","gin","bourbon",
    "kombucha","coconut water","nariyal pani","almond milk","oat milk","soy milk","plant milk",
    "energy drink","red bull","monster","gatorade","sports drink","electrolyte",
    "hot chocolate","cocoa mix","rooh afza","sharbat","jaljeera",
  ],
  household: [
    "paper towel","paper towels","napkins","tissue","tissues","facial tissue","kleenex",
    "toilet paper","bath tissue",
    "trash bag","trash bags","garbage bags","bin liners",
    "ziplock","ziploc","storage bags","freezer bags","sandwich bags","aluminum foil","foil",
    "plastic wrap","saran wrap","cling wrap","parchment paper","wax paper",
    "dish soap","dishwashing liquid","dawn",
    "detergent","laundry detergent","tide","fabric softener","dryer sheets",
    "bleach","disinfectant","lysol","clorox",
    "all purpose cleaner","glass cleaner","windex","surface cleaner",
    "sponge","sponges","scrub brush","steel wool",
    "paper plates","paper cups","disposable",
    "candle","candles","air freshener","febreze","agarbatti","incense",
    "light bulb","light bulbs","batteries","battery",
    "matches","lighter","hand sanitizer","rubbing alcohol","hydrogen peroxide",
  ],
  health: [
    "body wash","shower gel",
    "shampoo","conditioner","hair gel","dry shampoo",
    "soap","bar soap","hand soap","liquid soap",
    "toothpaste","toothbrush","floss","dental floss","mouthwash","listerine","datun",
    "deodorant","antiperspirant",
    "lotion","body lotion","hand cream","moisturizer","face cream","face wash",
    "sunscreen","sunblock","spf",
    "razor","razors","shaving cream",
    "band-aid","bandaid","bandage","gauze","first aid",
    "medicine","ibuprofen","tylenol","advil","aspirin",
    "allergy","benadryl","claritin","zyrtec",
    "cold medicine","dayquil","nyquil","cough syrup","cough drops",
    "antacid","tums","pepto","eno",
    "vitamin","vitamins","multivitamin","vitamin d","vitamin c","fish oil","probiotic","supplement",
    "fiber gummies","fibre gummies","gummies","vitamin gummies","melatonin gummies","elderberry gummies",
    "monk fruit","monk fruit sachets","stevia",
    "eye drops","contact lens","contact solution","saline",
    "cotton balls","cotton pads","q-tips","cotton swab",
    "feminine","tampon","tampons","pad","pads",
    "nail polish","tweezers",
    "makeup","mascara","foundation","lipstick","lip balm","chapstick",
    "balm","tiger balm","vicks","zandu",
  ],
  baby: [
    "diapers","diaper","nappy","nappies","pull-ups",
    "wipes","baby wipes","wet wipes",
    "formula","baby formula","similac","enfamil",
    "baby food","baby cereal","cerelac","teething",
    "sippy cup","bottle","baby bottle","pacifier",
    "baby wash","baby shampoo","baby lotion","baby oil","baby powder","diaper cream",
    "juice box","juice boxes","lunchable","lunchables",
    "fruit pouch","squeeze pouch","snack pack",
  ],
  pet: [
    "dog food","cat food","pet food","kibble",
    "dog treats","cat treats","pet treats",
    "cat litter","kitty litter","litter",
    "pet shampoo","flea","tick",
    "chew toy","dog toy","cat toy","pet toy",
    "leash","collar","harness","bird seed","birdseed","fish food",
    "puppy pad","puppy pads",
  ],
};

/* ── Item-level emoji lookup ────────────────────────────────────── */
const ITEM_EMOJIS = {
  // Fruits
  apple: "🍎", apples: "🍎", "green apple": "🍏",
  banana: "🍌", bananas: "🍌",
  grape: "🍇", grapes: "🍇",
  orange: "🍊", oranges: "🍊", mandarin: "🍊", clementine: "🍊", tangerine: "🍊",
  lemon: "🍋", lemons: "🍋", lime: "🍋‍🟩", limes: "🍋‍🟩",
  watermelon: "🍉", tarbooz: "🍉",
  melon: "🍈", cantaloupe: "🍈", honeydew: "🍈",
  strawberry: "🍓", strawberries: "🍓",
  blueberry: "🫐", blueberries: "🫐",
  cherry: "🍒", cherries: "🍒",
  peach: "🍑", peaches: "🍑", nectarine: "🍑",
  mango: "🥭", mangoes: "🥭", aam: "🥭",
  pineapple: "🍍",
  coconut: "🥥", nariyal: "🥥",
  kiwi: "🥝",
  pear: "🍐", pears: "🍐",
  plum: "🍇", plums: "🍇",
  apricot: "🍑",
  pomegranate: "🍎", anaar: "🍎",
  raspberry: "🍓", raspberries: "🍓",
  blackberry: "🍇", blackberries: "🍇",
  cranberry: "🍎", cranberries: "🍎",
  guava: "🍐", amrud: "🍐",
  papaya: "🍈",
  lychee: "🍑", litchi: "🍑",
  jackfruit: "🍈", kathal: "🍈",
  "dragon fruit": "🍈",
  "passion fruit": "🍈",
  avocado: "🥑", avocados: "🥑",

  // Vegetables
  carrot: "🥕", carrots: "🥕", "baby carrots": "🥕",
  broccoli: "🥦",
  lettuce: "🥬", romaine: "🥬", kale: "🥬", spinach: "🥬", arugula: "🥬", "spring mix": "🥬", "mixed greens": "🥬", greens: "🥬", palak: "🥬",
  cucumber: "🥒", cucumbers: "🥒",
  tomato: "🍅", tomatoes: "🍅", "cherry tomato": "🍅", "grape tomato": "🍅",
  "hot pepper": "🌶️", jalapeno: "🌶️", serrano: "🌶️", habanero: "🌶️", poblano: "🌶️", "green chili": "🌶️", "hari mirch": "🌶️",
  pepper: "🫑", peppers: "🫑", "bell pepper": "🫑", capsicum: "🫑", "shimla mirch": "🫑",
  corn: "🌽", "corn on the cob": "🌽", bhutta: "🌽",
  potato: "🥔", potatoes: "🥔", "sweet potato": "🍠", "sweet potatoes": "🍠", yam: "🍠", aloo: "🥔",
  eggplant: "🍆", baingan: "🍆", aubergine: "🍆",
  onion: "🧅", onions: "🧅", "red onion": "🧅", "green onion": "🧅", shallot: "🧅", shallots: "🧅", scallion: "🧅", scallions: "🧅",
  garlic: "🧄",
  mushroom: "🍄", mushrooms: "🍄", portobello: "🍄", shiitake: "🍄", cremini: "🍄",
  peanut: "🥜", peanuts: "🥜", moongfali: "🥜", "mixed nuts": "🥜", nuts: "🥜", almonds: "🥜", badam: "🥜", cashews: "🥜", kaju: "🥜", walnuts: "🥜", akhrot: "🥜", pecans: "🥜", pistachios: "🥜", pista: "🥜",
  ginger: "🫚",
  peas: "🫛", "green peas": "🫛", "snap peas": "🫛", "snow peas": "🫛", matar: "🫛",
  "green beans": "🫘", beans: "🫘", "black beans": "🫘", "kidney beans": "🫘", rajma: "🫘", chickpeas: "🫘", chole: "🫘", chana: "🫘",
  lentils: "🫘", dal: "🫘", "moong dal": "🫘", "toor dal": "🫘", "masoor dal": "🫘", "urad dal": "🫘",
  celery: "🥬",
  cauliflower: "🥦", gobi: "🥦",
  "brussels sprouts": "🥦",
  cabbage: "🥬", "bok choy": "🥬",
  asparagus: "🥦",
  zucchini: "🥒", squash: "🥒",
  radish: "🥕", beet: "🥕", beets: "🥕", turnip: "🥕",
  okra: "🫑", bhindi: "🫑",
  "drumstick": "🥬", moringa: "🥬",

  // Herbs
  cilantro: "🌿", dhaniya: "🌿", basil: "🌿", tulsi: "🌿", mint: "🌿", pudina: "🌿", parsley: "🌿", dill: "🌿", rosemary: "🌿", thyme: "🌿", sage: "🌿", chives: "🌿", "fresh herbs": "🌿", herbs: "🌿", "curry leaves": "🌿", "kadi patta": "🌿", methi: "🌿",

  // Dairy & Eggs
  milk: "🥛", "whole milk": "🥛", "2% milk": "🥛", "skim milk": "🥛", buttermilk: "🥛", chaas: "🥛",
  cheese: "🧀", cheddar: "🧀", mozzarella: "🧀", parmesan: "🧀", swiss: "🧀", provolone: "🧀", gouda: "🧀", brie: "🧀", feta: "🧀", ricotta: "🧀", "goat cheese": "🧀", "cream cheese": "🧀", "cottage cheese": "🧀", "shredded cheese": "🧀", "sliced cheese": "🧀", "string cheese": "🧀", paneer: "🧀",
  egg: "🥚", eggs: "🥚", "egg whites": "🥚", "dozen eggs": "🥚", anda: "🥚",
  butter: "🧈", "unsalted butter": "🧈", "salted butter": "🧈", margarine: "🧈", makhan: "🧈", ghee: "🧈",
  yogurt: "🫙", "greek yogurt": "🫙", yoghurt: "🫙", dahi: "🫙", curd: "🫙",
  cream: "🥛", "heavy cream": "🥛", "whipping cream": "🥛", "sour cream": "🥛", "half and half": "🥛", malai: "🥛",
  "ice cream": "🍦", gelato: "🍦", kulfi: "🍦", "frozen yogurt": "🍦",

  // Meat & Poultry
  chicken: "🍗", "chicken breast": "🍗", "chicken thigh": "🍗", "chicken thighs": "🍗", "chicken wings": "🍗", "chicken legs": "🍗", "chicken drumsticks": "🍗", "chicken tender": "🍗", "chicken tenders": "🍗", murgh: "🍗",
  beef: "🥩", "ground beef": "🥩", steak: "🥩", sirloin: "🥩", ribeye: "🥩", "filet mignon": "🥩", brisket: "🥩",
  pork: "🥩", "pork chop": "🥩", "pork chops": "🥩", "pork loin": "🥩", "pork belly": "🥩",
  bacon: "🥓", "turkey bacon": "🥓", "canadian bacon": "🥓",
  sausage: "🌭", sausages: "🌭", "italian sausage": "🌭", bratwurst: "🌭", kielbasa: "🌭", chorizo: "🌭",
  "hot dog": "🌭", "hot dogs": "🌭",
  turkey: "🦃", "turkey breast": "🦃", "ground turkey": "🦃",
  lamb: "🍖", "lamb chop": "🍖", "lamb chops": "🍖", "rack of lamb": "🍖", keema: "🍖", gosht: "🍖",
  ham: "🍖", ribs: "🍖", "baby back ribs": "🍖", "spare ribs": "🍖",
  duck: "🦆",
  meatball: "🧆", meatballs: "🧆",

  // Seafood
  shrimp: "🦐", prawns: "🦐", jhinga: "🦐",
  fish: "🐟", "fish fillet": "🐟", machhi: "🐟", tilapia: "🐟", cod: "🐟", halibut: "🐟", trout: "🐟", catfish: "🐟", bass: "🐟", snapper: "🐟", pomfret: "🐟", rohu: "🐟", surmai: "🐟",
  salmon: "🐟", "salmon fillet": "🐟", "smoked salmon": "🐟", lox: "🐟",
  tuna: "🐟", "tuna steak": "🐟", "canned tuna": "🐟",
  crab: "🦀", "crab legs": "🦀", "crab meat": "🦀",
  lobster: "🦞", "lobster tail": "🦞",
  squid: "🦑", calamari: "🦑", octopus: "🐙",
  oyster: "🦪", oysters: "🦪", clam: "🦪", clams: "🦪", mussel: "🦪", mussels: "🦪",
  sushi: "🍣", sashimi: "🍣",
  scallop: "🦪", scallops: "🦪",

  // Bakery
  bread: "🍞", "white bread": "🍞", "wheat bread": "🍞", "whole wheat bread": "🍞", "sourdough": "🍞", "rye bread": "🍞",
  bagel: "🥯", bagels: "🥯", "everything bagel": "🥯",
  croissant: "🥐", croissants: "🥐",
  baguette: "🥖",
  pretzel: "🥨", pretzels: "🥨",
  pancake: "🥞", pancakes: "🥞",
  waffle: "🧇", waffles: "🧇", "frozen waffles": "🧇",
  cake: "🎂", "birthday cake": "🎂",
  cupcake: "🧁", cupcakes: "🧁",
  pie: "🥧", "pie crust": "🥧",
  cookie: "🍪", cookies: "🍪",
  donut: "🍩", donuts: "🍩", doughnut: "🍩", doughnuts: "🍩",
  muffin: "🧁", muffins: "🧁",
  tortilla: "🫓", tortillas: "🫓", wrap: "🫓", wraps: "🫓", pita: "🫓", "pita bread": "🫓", naan: "🫓", roti: "🫓", chapati: "🫓", paratha: "🫓", flatbread: "🫓",
  "cinnamon roll": "🧁", "cinnamon rolls": "🧁",
  brownie: "🍫", brownies: "🍫",

  // Deli
  "lunch meat": "🥪", "deli meat": "🥪", salami: "🥪", pepperoni: "🥪", prosciutto: "🥪", bologna: "🥪", pastrami: "🥪",
  hummus: "🥣", guacamole: "🥑",
  pickle: "🥒", pickles: "🥒", achar: "🥒",
  olive: "🫒", olives: "🫒",
  sandwich: "🥪", "deli sandwich": "🥪",

  // Frozen
  "frozen pizza": "🍕", pizza: "🍕",
  "french fries": "🍟", "frozen fries": "🍟", "tater tots": "🍟",
  popsicle: "🍦", popsicles: "🍦",
  dumplings: "🥟", "frozen dumplings": "🥟", gyoza: "🥟",
  samosa: "🥟", samosas: "🥟",
  burrito: "🌯", "frozen burrito": "🌯", "frozen burritos": "🌯",
  "hot pockets": "🌯",

  // Pantry & Grains
  rice: "🍚", "white rice": "🍚", "brown rice": "🍚", "basmati rice": "🍚", basmati: "🍚", "jasmine rice": "🍚", chawal: "🍚",
  pasta: "🍝", spaghetti: "🍝", penne: "🍝", fusilli: "🍝", rigatoni: "🍝", macaroni: "🍝", linguine: "🍝", fettuccine: "🍝", lasagna: "🍝",
  noodles: "🍜", ramen: "🍜", udon: "🍜", soba: "🍜", "rice noodles": "🍜", maggi: "🍜",
  flour: "🌾", "all purpose flour": "🌾", maida: "🌾", atta: "🌾", "bread flour": "🌾", "wheat flour": "🌾", besan: "🌾", "gram flour": "🌾",
  oats: "🌾", oatmeal: "🌾", granola: "🌾", muesli: "🌾", cereal: "🥣", cheerios: "🥣", cornflakes: "🥣",
  honey: "🍯", shahad: "🍯",
  "maple syrup": "🍁",
  "peanut butter": "🥜", "almond butter": "🥜", nutella: "🍫", tahini: "🫙",
  jam: "🍓", jelly: "🍇", preserves: "🍓", marmalade: "🍊",
  "canned tomatoes": "🥫", "tomato paste": "🥫", "tomato sauce": "🥫", "canned soup": "🥫", "canned beans": "🥫", "canned corn": "🥫",
  broth: "🥣", stock: "🥣", "chicken broth": "🥣", "chicken stock": "🥣", "vegetable broth": "🥣", soup: "🥣",
  sugar: "🍬", "brown sugar": "🍬",
  "coconut milk": "🥥",
  tofu: "🥡", tempeh: "🥡",
  "protein powder": "💪", "protein bar": "💪", "protein bars": "💪",
  quinoa: "🌾", couscous: "🌾", bulgur: "🌾", barley: "🌾",
  "chia seeds": "🌱", "flax seeds": "🌱", "hemp seeds": "🌱", "sunflower seeds": "🌻", "pumpkin seeds": "🌱", "sesame seeds": "🌱",
  poha: "🍚", "flattened rice": "🍚", "puffed rice": "🍚",
  rava: "🌾", suji: "🌾", semolina: "🌾",

  // Snacks
  chips: "🥜", "potato chips": "🥜", "tortilla chips": "🥜",
  popcorn: "🍿",
  chocolate: "🍫", "chocolate bar": "🍫",
  candy: "🍬",
  "gummy bears": "🍬", "gummy candy": "🍬",
  lollipop: "🍭",
  "trail mix": "🥜",
  "granola bar": "🥜", "granola bars": "🥜",
  "energy bar": "🥜", "energy bars": "🥜",
  "dried fruit": "🍇", raisins: "🍇", "dried mango": "🥭", "dried cranberries": "🍇",
  salsa: "🫙",

  // Condiments & Spices
  ketchup: "🍅",
  mustard: "🫙",
  "hot sauce": "🌶️", sriracha: "🌶️", tabasco: "🌶️",
  "soy sauce": "🫙", "fish sauce": "🫙", "oyster sauce": "🫙",
  vinegar: "🫙", "apple cider vinegar": "🫙", "balsamic vinegar": "🫙",
  oil: "🫒", "olive oil": "🫒", "vegetable oil": "🫒", "coconut oil": "🥥", "sesame oil": "🫒", "mustard oil": "🫒", "avocado oil": "🥑",
  salt: "🧂", "sea salt": "🧂", "kosher salt": "🧂", "pink salt": "🧂",
  "black pepper": "🫙", "red pepper flakes": "🌶️",
  cumin: "🫙", jeera: "🫙", turmeric: "🫙", haldi: "🫙", cinnamon: "🫙", dalchini: "🫙",
  "garam masala": "🫙", "chaat masala": "🫙",
  "bbq sauce": "🫙", "barbecue sauce": "🫙",
  pesto: "🌿", "pasta sauce": "🍝", "alfredo sauce": "🫙", "pizza sauce": "🍕", marinara: "🍅",
  chutney: "🫙",

  // Beverages
  water: "💧", "bottled water": "💧", "sparkling water": "💧",
  coffee: "☕", "ground coffee": "☕", "coffee beans": "☕", "instant coffee": "☕", espresso: "☕", "cold brew": "☕",
  tea: "🍵", "green tea": "🍵", "black tea": "🍵", "herbal tea": "🍵", chai: "🍵", matcha: "🍵", "iced tea": "🍵",
  juice: "🧃", "orange juice": "🧃", "apple juice": "🧃", "cranberry juice": "🧃", lemonade: "🍋",
  soda: "🥤", cola: "🥤", coke: "🥤", pepsi: "🥤", sprite: "🥤", "ginger ale": "🥤",
  beer: "🍺", ipa: "🍺", lager: "🍺", ale: "🍺", stout: "🍺", "craft beer": "🍺",
  wine: "🍷", "red wine": "🍷", "white wine": "🥂", rose: "🍷", champagne: "🥂", prosecco: "🥂",
  vodka: "🍸", whiskey: "🥃", rum: "🍹", tequila: "🍸", gin: "🍸", bourbon: "🥃",
  kombucha: "🍵",
  "coconut water": "🥥", "nariyal pani": "🥥",
  "almond milk": "🥛", "oat milk": "🥛", "soy milk": "🥛",
  "energy drink": "⚡", "red bull": "⚡", "sports drink": "⚡", gatorade: "⚡",
  "hot chocolate": "☕", "cocoa mix": "☕",
  smoothie: "🥤",
  lassi: "🥛",

  // Household
  "paper towel": "🧻", "paper towels": "🧻",
  "toilet paper": "🧻",
  "trash bag": "🗑️", "trash bags": "🗑️", "garbage bags": "🗑️",
  "dish soap": "🧴", "dishwashing liquid": "🧴",
  detergent: "🧴", "laundry detergent": "🧴",
  sponge: "🧽", sponges: "🧽",
  bleach: "🧴", disinfectant: "🧴",
  "aluminum foil": "🧻", foil: "🧻",
  candle: "🕯️", candles: "🕯️",
  batteries: "🔋", battery: "🔋",
  "light bulb": "💡", "light bulbs": "💡",
  broom: "🧹", mop: "🧹",

  // Health & Beauty
  shampoo: "🧴", conditioner: "🧴",
  soap: "🧼", "bar soap": "🧼", "hand soap": "🧼",
  toothpaste: "🪥", toothbrush: "🪥",
  lotion: "🧴", moisturizer: "🧴", sunscreen: "🧴",
  deodorant: "🧴",
  razor: "🪒", razors: "🪒",
  "band-aid": "🩹", bandaid: "🩹", bandage: "🩹",
  medicine: "💊", ibuprofen: "💊", tylenol: "💊", aspirin: "💊",
  vitamin: "💊", vitamins: "💊", multivitamin: "💊", supplement: "💊",
  "eye drops": "💧",
  lipstick: "💄", makeup: "💄",
  "nail polish": "💅",
  "lip balm": "💄", chapstick: "💄",

  // Baby & Kids
  diapers: "👶", diaper: "👶", nappy: "👶",
  "baby wipes": "👶", wipes: "👶",
  "baby food": "🍼", formula: "🍼", "baby bottle": "🍼",
  pacifier: "🍼",

  // Pet
  "dog food": "🐕", "dog treats": "🐕",
  "cat food": "🐈", "cat treats": "🐈", "cat litter": "🐈",
  "pet food": "🐾", "pet treats": "🐾",
  "bird food": "🐦", "bird seed": "🐦",
  "fish food": "🐠",

  // Prepared Foods
  tacos: "🌮", taco: "🌮", "taco shells": "🌮",
  burger: "🍔", hamburger: "🍔",
  "french toast": "🍞",
  salad: "🥗",
  stew: "🍲", curry: "🍛",
  "fried rice": "🍛",
  "mac and cheese": "🧀",
};

function getItemEmoji(text) {
  const lower = text.toLowerCase().trim();
  // Try exact match first
  if (ITEM_EMOJIS[lower]) return ITEM_EMOJIS[lower];
  // Try longest substring match
  let best = null, bestLen = 0;
  for (const [key, emoji] of Object.entries(ITEM_EMOJIS)) {
    if (key.length > bestLen && (lower.includes(key) || lower === key + "s")) {
      best = emoji;
      bestLen = key.length;
    }
  }
  return best;
}

function detectCategory(text) {
  const lower = text.toLowerCase().trim();
  let best = null, bestLen = 0;
  for (const [cat, keywords] of Object.entries(CAT_KEYWORDS)) {
    for (const kw of keywords) {
      if ((lower === kw || lower.includes(kw)) && kw.length > bestLen) { best = cat; bestLen = kw.length; }
    }
  }
  return best;
}

function parseQty(raw) {
  const t = raw.trim();
  let m = t.match(/^(\d+)\s*[xX]\s+(.+)$/);
  if (m) return { qty: parseInt(m[1]), text: m[2].trim() };
  m = t.match(/^[xX](\d+)\s+(.+)$/);
  if (m) return { qty: parseInt(m[1]), text: m[2].trim() };
  m = t.match(/^(.+?)\s+[xX](\d+)$/);
  if (m) return { qty: parseInt(m[2]), text: m[1].trim() };
  m = t.match(/^(\d+)\s+(.+)$/);
  if (m && parseInt(m[1]) > 1 && parseInt(m[1]) < 100) return { qty: parseInt(m[1]), text: m[2].trim() };
  return { qty: 1, text: t };
}

/* ═══ SWIPE ROW ═══ */
function SwipeRow({ children, onDelete, height }) {
  const [offset, setOffset] = useState(0);
  const [swiping, setSwiping] = useState(false);
  const [deleted, setDeleted] = useState(false);
  const startX = useRef(0), startY = useRef(0), locked = useRef(false);
  const TH = 80, DEL = 120;
  const onTS = e => { startX.current = e.touches[0].clientX; startY.current = e.touches[0].clientY; locked.current = false; setSwiping(true); };
  const onTM = e => {
    if (!swiping) return;
    const dx = e.touches[0].clientX - startX.current, dy = e.touches[0].clientY - startY.current;
    if (!locked.current && (Math.abs(dx) > 8 || Math.abs(dy) > 8)) { locked.current = true; if (Math.abs(dy) > Math.abs(dx)) { setSwiping(false); setOffset(0); return; } }
    if (!locked.current) return;
    setOffset(Math.min(0, Math.max(-DEL - 20, dx)));
  };
  const onTE = () => { setSwiping(false); if (offset < -DEL) { setDeleted(true); setTimeout(onDelete, 280); } else setOffset(0); };
  const prog = Math.min(1, Math.abs(offset) / TH), ready = Math.abs(offset) >= TH;
  return (
    <div style={{ position: "relative", overflow: "hidden", height: deleted ? 0 : height, opacity: deleted ? 0 : 1, transition: deleted ? "height .28s ease, opacity .2s ease" : "none" }}>
      <div style={{ position: "absolute", right: 0, top: 0, bottom: 0, width: Math.abs(offset) + 1,
        background: ready ? "linear-gradient(90deg,#c0392b,#e74c3c)" : `rgba(163,61,64,${prog * .85})`,
        display: "flex", alignItems: "center", justifyContent: "center", transition: swiping ? "none" : "all .25s ease", borderBottom: "1px solid rgba(255,255,255,.15)" }}>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"
          style={{ opacity: prog, transform: `scale(${.6 + prog * .4})`, transition: swiping ? "none" : "all .2s" }}>
          <polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"/>
        </svg>
      </div>
      <div onTouchStart={onTS} onTouchMove={onTM} onTouchEnd={onTE}
        style={{ transform: `translateX(${offset}px)`, transition: swiping ? "none" : "transform .25s cubic-bezier(.25,.46,.45,.94)",
          position: "relative", zIndex: 1, background: "var(--paper)" }}>
        {children}
      </div>
    </div>
  );
}

/* ═══ MAIN ═══ */
export default function GroceryList() {
  const [items, setItems] = useState(() => {
    try { const s = localStorage.getItem("grocery-items"); return s ? JSON.parse(s) : []; }
    catch { return []; }
  });
  const [input, setInput] = useState("");
  const [selectedCat, setSelectedCat] = useState("pantry");
  const [autoDetectedCat, setAutoDetectedCat] = useState(null);
  const [showCatPicker, setShowCatPicker] = useState(false);
  const [page, setPage] = useState(0);
  const [flipDir, setFlipDir] = useState(null);
  const [animating, setAnimating] = useState(false);
  const [justChecked, setJustChecked] = useState(new Set());
  const [toast, setToast] = useState(null);
  const [undoItem, setUndoItem] = useState(null);
  const [dragId, setDragId] = useState(null);
  const [dragOverId, setDragOverId] = useState(null);
  const inputRef = useRef(null);
  const undoTimer = useRef(null);

  useEffect(() => { try { localStorage.setItem("grocery-items", JSON.stringify(items)); } catch {} }, [items]);

  useEffect(() => { if (!input.trim()) { setAutoDetectedCat(null); return; } setAutoDetectedCat(detectCategory(parseQty(input).text)); }, [input]);
  const activeCat = autoDetectedCat || selectedCat;

  const totalLeft = items.filter(i => !i.checked).length;
  const totalPages = Math.max(1, Math.ceil(items.length / PER_PAGE));

  useEffect(() => { if (page >= totalPages) setPage(Math.max(0, totalPages - 1)); }, [totalPages, page]);

  const pageStart = page * PER_PAGE;
  const pageItems = items.slice(pageStart, pageStart + PER_PAGE);
  const pageUnchecked = pageItems.filter(i => !i.checked);
  const pageChecked = pageItems.filter(i => i.checked);
  const blankLines = Math.max(0, PER_PAGE - pageItems.length);

  const addItem = () => {
    const raw = input.trim(); if (!raw) return;
    const { qty, text } = parseQty(raw);
    const cat = autoDetectedCat || selectedCat;
    setItems(prev => {
      const next = [...prev, { id: Date.now(), text, qty, category: cat, checked: false }];
      const lp = Math.max(1, Math.ceil(next.length / PER_PAGE)) - 1;
      if (lp > page) goToPage(lp, "next");
      return next;
    });
    setInput(""); setAutoDetectedCat(null); inputRef.current?.focus();
  };

  const toggleCheck = id => {
    setJustChecked(p => { const n = new Set(p); if (items.find(i => i.id === id && !i.checked)) n.add(id); return n; });
    setTimeout(() => setJustChecked(p => { const n = new Set(p); n.delete(id); return n; }), 600);
    setItems(p => p.map(i => i.id === id ? { ...i, checked: !i.checked } : i));
  };

  const removeItem = id => {
    const d = items.find(i => i.id === id); if (!d) return;
    setItems(p => p.filter(i => i.id !== id));
    if (undoTimer.current) clearTimeout(undoTimer.current);
    setUndoItem(d); setToast(`Deleted "${d.text}"`);
    undoTimer.current = setTimeout(() => { setUndoItem(null); setToast(null); }, 3500);
  };
  const handleUndo = () => { if (!undoItem) return; setItems(p => [...p, undoItem]); setUndoItem(null); setToast(null); if (undoTimer.current) clearTimeout(undoTimer.current); };

  const updateText = useCallback((id, t) => setItems(p => p.map(i => i.id === id ? { ...i, text: t } : i)), []);
  const handleItemKeyDown = e => { if (e.key === "Enter") { e.preventDefault(); e.target.blur(); inputRef.current?.focus(); } };
  const handleItemBlur = id => setItems(p => { const it = p.find(i => i.id === id); return it && !it.text.trim() ? p.filter(i => i.id !== id) : p; });
  const clearChecked = () => setItems(p => p.filter(i => !i.checked));

  const shareList = async () => {
    const unc = items.filter(i => !i.checked), chk = items.filter(i => i.checked);
    let t = "🛒 Grocery List\n" + new Date().toLocaleDateString("en-US", { weekday: "long", month: "long", day: "numeric" }) + "\n\n";
    unc.forEach(i => { t += `☐ ${i.qty > 1 ? i.qty + "x " : ""}${i.text}\n`; });
    if (chk.length) { t += "\n✓ Picked up:\n"; chk.forEach(i => { t += `  ✓ ${i.text}\n`; }); }
    t += `\n${unc.length} item${unc.length !== 1 ? "s" : ""} remaining`;
    if (navigator.share) { try { await navigator.share({ title: "Grocery List", text: t }); return; } catch {} }
    try { await navigator.clipboard.writeText(t); setToast("Copied!"); setTimeout(() => setToast(null), 2200); } catch { setToast("Couldn't copy"); setTimeout(() => setToast(null), 2200); }
  };

  const handleDragStart = id => setDragId(id);
  const handleDragOver = (e, id) => { e.preventDefault(); setDragOverId(id); };
  const handleDrop = tid => {
    if (dragId == null || dragId === tid) { setDragId(null); setDragOverId(null); return; }
    setItems(p => { const a = [...p], f = a.findIndex(i => i.id === dragId), t = a.findIndex(i => i.id === tid); if (f < 0 || t < 0) return p; const [m] = a.splice(f, 1); a.splice(t, 0, m); return a; });
    setDragId(null); setDragOverId(null);
  };
  const handleDragEnd = () => { setDragId(null); setDragOverId(null); };

  const goToPage = (t, d) => { if (animating || t === page) return; setFlipDir(d); setAnimating(true); setTimeout(() => { setPage(t); setFlipDir(null); setAnimating(false); }, 300); };
  const prevPage = () => page > 0 && goToPage(page - 1, "prev");
  const nextPage = () => page < totalPages - 1 && goToPage(page + 1, "next");
  const pageAnimClass = flipDir === "next" ? "pg-out-l" : flipDir === "prev" ? "pg-out-r" : "pg-in";

  const blankTouch = useRef({ x: 0, y: 0 });
  const onBTS = e => { blankTouch.current = { x: e.touches[0].clientX, y: e.touches[0].clientY }; };
  const onBTE = e => { const dx = e.changedTouches[0].clientX - blankTouch.current.x, dy = e.changedTouches[0].clientY - blankTouch.current.y; if (Math.abs(dx) > Math.abs(dy) && Math.abs(dx) > 60) { dx < 0 ? nextPage() : prevPage(); } };

  const CheckMark = ({ color, checked: c, justDone }) => (
    <div style={{ width: 14, height: 14, borderRadius: "50%", border: `1.5px solid ${c ? color : "var(--line)"}`, backgroundColor: c ? color : "transparent", display: "flex", alignItems: "center", justifyContent: "center", transition: "all .2s" }}>
      {c && <svg width="8" height="7" viewBox="0 0 10 8" fill="none" style={{ overflow: "visible" }}><path d="M1 4L3.5 6.5L9 1" stroke="#fff" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" className={justDone ? "check-draw" : ""} style={justDone ? {} : { strokeDasharray: "none" }} /></svg>}
    </div>
  );

  return (
    <div style={{ minHeight: "100dvh", background: "var(--bg)", display: "flex", justifyContent: "center", padding: "20px 8px 60px", fontFamily: "'DM Sans', sans-serif", position: "relative", overflowX: "hidden", width: "100%" }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Caveat:wght@400;500;600;700&family=DM+Sans:ital,wght@0,400;0,500;0,600;1,400&display=swap');

        /* ═══ LIGHT THEME (default) ═══ */
        :root {
          --bg: linear-gradient(155deg, #ddd6ca 0%, #cfc7b8 50%, #c4baa8 100%);
          --paper: #faf8f4;
          --ink: #3a3429;
          --ink-soft: #7a6c5d;
          --ink-muted: #a89e90;
          --ink-faint: #b8b0a2;
          --line: #e4ddd3;
          --line-dash: #d4cec4;
          --margin: rgba(230,164,160,0.4);
          --hole: linear-gradient(135deg, #cfc7b8, #ddd6ca);
          --hole-shadow: inset 0 1px 2px rgba(0,0,0,.12);
          --shadow: 0 1px 3px rgba(0,0,0,.05), 0 8px 32px rgba(0,0,0,.10), 0 0 0 1px rgba(0,0,0,.03);
          --badge-bg: #3a3429;
          --badge-fg: #faf8f4;
          --border-btn: #d4cec4;
          --check-unchecked: #c4b8a8;
          --checked-text: #b0a89a;
          --strike: #b0a89a;
          --drag: #c4b8a8;
          --curl1: #e8e0d4;
          --curl2: #d6cdbf;
          --toast-bg: #3a3429;
          --toast-fg: #faf8f4;
          --focus-bg: rgba(74,124,89,0.035);
          --caret: #a63d40;
          --noise-opacity: 0.03;
        }

        /* ═══ DARK THEME ═══ */
        @media (prefers-color-scheme: dark) {
          :root {
            --bg: linear-gradient(155deg, #1a1a1f 0%, #141418 50%, #111115 100%);
            --paper: #1e1e24;
            --ink: #e8e4de;
            --ink-soft: #a09888;
            --ink-muted: #78716a;
            --ink-faint: #5a544e;
            --line: #2e2e35;
            --line-dash: #35353d;
            --margin: rgba(180,100,96,0.25);
            --hole: linear-gradient(135deg, #2a2a32, #222228);
            --hole-shadow: inset 0 1px 3px rgba(0,0,0,.4);
            --shadow: 0 1px 3px rgba(0,0,0,.2), 0 8px 32px rgba(0,0,0,.4), 0 0 0 1px rgba(255,255,255,.04);
            --badge-bg: #e8e4de;
            --badge-fg: #1e1e24;
            --border-btn: #3a3a42;
            --check-unchecked: #4a4a52;
            --checked-text: #5a544e;
            --strike: #5a544e;
            --drag: #4a4a52;
            --curl1: #28282f;
            --curl2: #1a1a20;
            --toast-bg: #e8e4de;
            --toast-fg: #1e1e24;
            --focus-bg: rgba(74,124,89,0.08);
            --caret: #e07070;
            --noise-opacity: 0.015;
          }
        }

        *,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
        html,body{overflow-x:hidden;width:100%;-webkit-text-size-adjust:100%;-webkit-tap-highlight-color:transparent}
        body{overscroll-behavior-y:none}
        input,textarea,select,button{font-size:16px}
        input::placeholder{color:var(--ink-faint);font-style:italic}
        ::-webkit-scrollbar{width:5px}
        ::-webkit-scrollbar-thumb{background:var(--line-dash);border-radius:3px}

        /* Prevent iOS zoom on input focus — inputs must be >= 16px */
        @supports (-webkit-touch-callout: none) {
          input{font-size:max(16px, 21px)!important}
        }

        /* Small screens: tighten padding */
        @media (max-width: 380px) {
          .notepad-wrap { padding-left: 40px !important; padding-right: 10px !important; }
          .g-edit { font-size: 18px !important; }
        }
        @media (max-width: 320px) {
          .notepad-wrap { padding-left: 36px !important; padding-right: 8px !important; }
          .g-edit { font-size: 16px !important; }
        }

        @keyframes slideIn{from{opacity:0;transform:translateX(-8px)}to{opacity:1;transform:translateX(0)}}
        @keyframes fadeIn{from{opacity:0}to{opacity:1}}
        @keyframes pgOutL{0%{opacity:1;transform:translateX(0) rotateY(0)}100%{opacity:0;transform:translateX(-40px) rotateY(8deg)}}
        @keyframes pgOutR{0%{opacity:1;transform:translateX(0) rotateY(0)}100%{opacity:0;transform:translateX(40px) rotateY(-8deg)}}
        @keyframes pgIn{0%{opacity:0;transform:translateY(6px)}100%{opacity:1;transform:translateY(0)}}
        .pg-out-l{animation:pgOutL .3s ease-in forwards}
        .pg-out-r{animation:pgOutR .3s ease-in forwards}
        .pg-in{animation:pgIn .25s ease-out forwards}
        @keyframes drawCheck{from{stroke-dashoffset:20}to{stroke-dashoffset:0}}
        .check-draw{stroke-dasharray:20;stroke-dashoffset:20;animation:drawCheck .4s ease-out .05s forwards}
        @keyframes strikeAnim{from{width:0}to{width:100%}}
        .strike-anim::after{content:'';position:absolute;left:0;top:50%;height:1.5px;background:var(--strike);width:0;animation:strikeAnim .35s ease-out .15s forwards;transform:rotate(-0.5deg)}
        @keyframes toastIn{from{opacity:0;transform:translate(-50%,20px)}to{opacity:1;transform:translate(-50%,0)}}

        .g-add:hover:not(:disabled){background:var(--ink)!important;color:var(--paper)!important;border-color:var(--ink)!important}
        .g-cat-dot:hover{transform:scale(1.15)}
        .g-clear:hover{opacity:1!important}
        .g-chip:hover{transform:translateY(-1px)}
        .g-nav:hover:not(:disabled){background:var(--ink)!important;color:var(--paper)!important}
        .g-nav:disabled{opacity:.25;cursor:default}
        .g-dot:hover{transform:scale(1.3)}
        .g-share:hover{background:var(--ink)!important;color:var(--paper)!important}

        .g-item.dragging{opacity:.4}
        .g-item.drag-over{border-top:2px solid #4a7c59;margin-top:-2px}
        .g-drag{cursor:grab;opacity:.25;transition:opacity .15s}
        .g-item:hover .g-drag{opacity:.6}
        .g-drag:active{cursor:grabbing}

        .g-edit{
          flex:1;border:none;outline:none;
          font-size:21px;font-family:'Caveat',cursive;font-weight:500;
          color:var(--ink);background:transparent;padding:0;
          line-height:${LINE_H}px;height:${LINE_H}px;
          letter-spacing:.2px;caret-color:var(--caret);min-width:0;
        }
        .g-edit:focus{background:var(--focus-bg);border-radius:3px;padding:0 4px;margin:0 -4px}
        .g-edit.done{color:var(--checked-text)}

        .notepad-wrap::after{
          content:'';position:absolute;bottom:0;right:0;width:40px;height:40px;
          background:linear-gradient(135deg,transparent 50%,var(--curl1) 50%,var(--curl2) 100%);
          box-shadow:-2px -2px 5px rgba(0,0,0,.05);border-top-left-radius:4px;
          transition:all .3s ease;z-index:5;
        }
        .notepad-wrap:hover::after{width:55px;height:55px}
        .notepad-wrap::before{
          content:'';position:absolute;inset:0;
          background-image:url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.85' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='0.03'/%3E%3C/svg%3E");
          background-size:200px 200px;pointer-events:none;z-index:0;border-radius:2px;opacity:var(--noise-opacity);
        }
        @keyframes catPulse{0%{box-shadow:0 0 0 0 rgba(74,124,89,.4)}70%{box-shadow:0 0 0 8px rgba(74,124,89,0)}100%{box-shadow:0 0 0 0 rgba(74,124,89,0)}}
        .cat-detected{animation:catPulse .6s ease-out}
      `}</style>

      <div className="notepad-wrap" style={{ width: "100%", maxWidth: 460, background: "var(--paper)", borderRadius: 2, boxShadow: "var(--shadow)", position: "relative", paddingLeft: 48, paddingRight: 14, paddingBottom: 18, overflow: "hidden" }}>
        <div style={{ position: "absolute", left: 38, top: 0, bottom: 0, width: 2, background: "var(--margin)", zIndex: 1 }} />
        <div style={{ position: "absolute", left: 0, top: 16, bottom: 16, width: 24, display: "flex", flexDirection: "column", gap: 22, alignItems: "center", zIndex: 2 }}>
          {Array.from({ length: 18 }).map((_, i) => <div key={i} style={{ width: 10, height: 10, borderRadius: "50%", background: "var(--hole)", boxShadow: "var(--hole-shadow)", flexShrink: 0 }} />)}
        </div>

        {/* Header */}
        <div style={{ paddingTop: 20, paddingBottom: 8, position: "relative", zIndex: 1 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            <h1 style={{ fontFamily: "'Caveat', cursive", fontSize: 34, fontWeight: 700, color: "var(--ink)", lineHeight: 1.1 }}>Grocery List</h1>
            {items.length > 0 && <span style={{ display: "inline-flex", alignItems: "center", justifyContent: "center", minWidth: 20, height: 20, borderRadius: 10, background: "var(--badge-bg)", color: "var(--badge-fg)", fontSize: 12, fontWeight: 600, padding: "0 6px" }}>{totalLeft}</span>}
            {items.length > 0 && (
              <button className="g-share" onClick={shareList} style={{ marginLeft: "auto", width: 28, height: 28, borderRadius: "50%", border: `1.5px solid var(--border-btn)`, background: "transparent", color: "var(--ink-soft)", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", transition: "all .15s", padding: 0, flexShrink: 0 }} title="Share">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 12v8a2 2 0 002 2h12a2 2 0 002-2v-8"/><polyline points="16 6 12 2 8 6"/><line x1="12" y1="2" x2="12" y2="15"/></svg>
              </button>
            )}
          </div>
          <p style={{ fontSize: 13, color: "var(--ink-muted)", marginTop: 2, fontStyle: "italic" }}>{new Date().toLocaleDateString("en-US", { weekday: "long", month: "long", day: "numeric" })}</p>
        </div>

        {/* Input */}
        <div style={{ display: "flex", alignItems: "center", gap: 8, height: LINE_H, borderBottom: "1px solid var(--line)", position: "relative", zIndex: 1 }}>
          <button onClick={() => setShowCatPicker(!showCatPicker)} className={`g-cat-dot ${autoDetectedCat ? "cat-detected" : ""}`}
            style={{ width: 28, height: 28, borderRadius: "50%", border: "none", cursor: "pointer", flexShrink: 0, transition: "all .2s", display: "flex", alignItems: "center", justifyContent: "center", backgroundColor: CATEGORIES[activeCat].color }}
            title={autoDetectedCat ? `Auto: ${CATEGORIES[activeCat].label}` : CATEGORIES[activeCat].label}>
            <span style={{ fontSize: 14, lineHeight: 1 }}>{CATEGORIES[activeCat].emoji}</span>
          </button>
          <input ref={inputRef} value={input} onChange={e => setInput(e.target.value)} onKeyDown={e => e.key === "Enter" && addItem()} placeholder='Add item... (try "2x milk")'
            style={{ flex: 1, border: "none", outline: "none", fontSize: 21, fontFamily: "'Caveat', cursive", fontWeight: 500, color: "var(--ink)", background: "transparent", padding: 0, height: LINE_H, lineHeight: `${LINE_H}px`, letterSpacing: ".2px", caretColor: "var(--caret)", minWidth: 0, WebkitAppearance: "none", borderRadius: 0 }} />
          {input.trim() && getItemEmoji(input.trim()) && <span style={{ fontSize: 22, lineHeight: 1, flexShrink: 0, userSelect: "none", animation: "fadeIn .2s ease" }}>{getItemEmoji(input.trim())}</span>}
          {autoDetectedCat && input.trim() && <span style={{ fontSize: 10, fontWeight: 600, color: "#4a7c59", textTransform: "uppercase", letterSpacing: ".8px", whiteSpace: "nowrap", opacity: .65, fontFamily: "'DM Sans', sans-serif" }}>{CATEGORIES[autoDetectedCat].label}</span>}
          <button onClick={addItem} className="g-add" style={{ width: 28, height: 28, borderRadius: "50%", border: `1.5px solid var(--border-btn)`, background: "transparent", color: "var(--ink-soft)", fontSize: 18, cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0, transition: "all .15s", lineHeight: 1 }} disabled={!input.trim()}>+</button>
        </div>

        {/* Category picker */}
        {showCatPicker && (
          <div style={{ display: "flex", flexWrap: "wrap", gap: 4, padding: "8px 0 4px", animation: "fadeIn .15s ease", maxHeight: 110, overflowY: "auto", position: "relative", zIndex: 1 }}>
            {Object.entries(CATEGORIES).map(([key, { label, color, emoji }]) => (
              <button key={key} className="g-chip" onClick={() => { setSelectedCat(key); setAutoDetectedCat(null); setShowCatPicker(false); }}
                style={{ fontSize: 11.5, padding: "3px 9px", borderRadius: 14, cursor: "pointer", fontWeight: 500, fontFamily: "'DM Sans', sans-serif", transition: "all .15s", whiteSpace: "nowrap",
                  backgroundColor: selectedCat === key ? color : "transparent", color: selectedCat === key ? "#fff" : color, border: `1.5px solid ${color}` }}>
                {emoji} {label}
              </button>
            ))}
          </div>
        )}

        {/* Page */}
        <div style={{ minHeight: PER_PAGE * LINE_H, position: "relative", perspective: "800px", overflow: "hidden", touchAction: "pan-y" }}>
          <div key={page} className={pageAnimClass} style={{ transformOrigin: "center center", position: "relative", zIndex: 1 }}>
            {items.length === 0 && (
              <div style={{ textAlign: "center", padding: "36px 0", animation: "fadeIn .3s ease" }}>
                <span style={{ fontSize: 36, display: "block", marginBottom: 6 }}>📝</span>
                <p style={{ fontFamily: "'Caveat', cursive", fontSize: 24, color: "var(--ink-muted)", fontWeight: 600 }}>Start adding items</p>
                <p style={{ fontSize: 13, color: "var(--ink-faint)", marginTop: 4, fontStyle: "italic" }}>Try "2x milk" or "3 bananas" for quantities</p>
                <p style={{ fontSize: 13, color: "var(--ink-faint)", marginTop: 4, fontStyle: "italic" }}>Categories auto-detect · swipe left to delete</p>
              </div>
            )}

            {pageUnchecked.map(item => (
              <SwipeRow key={item.id} onDelete={() => removeItem(item.id)} height={LINE_H}>
                <div className={`g-item ${dragId === item.id ? "dragging" : ""} ${dragOverId === item.id ? "drag-over" : ""}`}
                  style={{ display: "flex", alignItems: "center", gap: 6, height: LINE_H, borderBottom: "1px solid var(--line)", position: "relative" }}
                  draggable onDragStart={() => handleDragStart(item.id)} onDragOver={e => handleDragOver(e, item.id)} onDrop={() => handleDrop(item.id)} onDragEnd={handleDragEnd}>
                  <span className="g-drag" style={{ fontSize: 12, color: "var(--drag)", userSelect: "none", width: 12, textAlign: "center", flexShrink: 0, lineHeight: 1 }}>⠿</span>
                  <button onClick={() => toggleCheck(item.id)} style={{ width: 16, height: 16, background: "transparent", border: "none", cursor: "pointer", padding: 0, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                    <CheckMark color={CATEGORIES[item.category]?.color || "#888"} checked={false} justDone={false} />
                  </button>
                  {item.qty > 1 && <span style={{ fontSize: 12, fontWeight: 700, color: "var(--badge-fg)", background: "var(--badge-bg)", borderRadius: 8, padding: "1px 5px", lineHeight: 1.3, fontFamily: "'DM Sans', sans-serif", flexShrink: 0, minWidth: 20, textAlign: "center" }}>{item.qty}×</span>}
                  <input className="g-edit" value={item.text} onChange={e => updateText(item.id, e.target.value)} onKeyDown={handleItemKeyDown} onBlur={() => handleItemBlur(item.id)} spellCheck={false} />
                  {getItemEmoji(item.text) && <span style={{ fontSize: 20, lineHeight: 1, flexShrink: 0, userSelect: "none" }}>{getItemEmoji(item.text)}</span>}
                  <span style={{ fontSize: 14, lineHeight: 1, flexShrink: 0, userSelect: "none", opacity: .7 }} title={CATEGORIES[item.category]?.label}>{CATEGORIES[item.category]?.emoji}</span>
                </div>
              </SwipeRow>
            ))}

            {pageChecked.length > 0 && (
              <>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", height: LINE_H, borderBottom: "1px dashed var(--line-dash)" }}>
                  <span style={{ fontSize: 11, color: "var(--ink-faint)", fontWeight: 600, textTransform: "uppercase", letterSpacing: "1.2px" }}>picked up</span>
                  {page === 0 && <button className="g-clear" onClick={clearChecked} style={{ fontSize: 11, color: "#a63d40", background: "transparent", border: "none", cursor: "pointer", fontFamily: "'DM Sans', sans-serif", fontWeight: 600, opacity: .6, transition: "opacity .15s" }}>clear</button>}
                </div>
                {pageChecked.map(item => (
                  <SwipeRow key={item.id} onDelete={() => removeItem(item.id)} height={LINE_H}>
                    <div className="g-item" style={{ display: "flex", alignItems: "center", gap: 6, height: LINE_H, borderBottom: "1px solid var(--line)", opacity: .45 }}>
                      <span style={{ fontSize: 12, color: "var(--drag)", userSelect: "none", width: 12, textAlign: "center", flexShrink: 0, visibility: "hidden" }}>⠿</span>
                      <button onClick={() => toggleCheck(item.id)} style={{ width: 16, height: 16, background: "transparent", border: "none", cursor: "pointer", padding: 0, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                        <CheckMark color={CATEGORIES[item.category]?.color || "#888"} checked={true} justDone={justChecked.has(item.id)} />
                      </button>
                      {item.qty > 1 && <span style={{ fontSize: 12, fontWeight: 700, color: "var(--badge-fg)", background: "var(--badge-bg)", borderRadius: 8, padding: "1px 5px", lineHeight: 1.3, fontFamily: "'DM Sans', sans-serif", flexShrink: 0, opacity: .5 }}>{item.qty}×</span>}
                      <div style={{ flex: 1, position: "relative", height: LINE_H, display: "flex", alignItems: "center" }}>
                        <input className="g-edit done" value={item.text} onChange={e => updateText(item.id, e.target.value)} onKeyDown={handleItemKeyDown} onBlur={() => handleItemBlur(item.id)} spellCheck={false} style={{ textDecoration: "none" }} />
                        <div className={justChecked.has(item.id) ? "strike-anim" : ""} style={{ position: "absolute", left: 0, top: "50%", height: 1.5, background: "var(--strike)", transform: "rotate(-0.5deg)", width: justChecked.has(item.id) ? undefined : "100%", pointerEvents: "none" }} />
                      </div>
                      {getItemEmoji(item.text) && <span style={{ fontSize: 20, lineHeight: 1, flexShrink: 0, userSelect: "none", opacity: .7 }}>{getItemEmoji(item.text)}</span>}
                      <span style={{ fontSize: 14, lineHeight: 1, flexShrink: 0, userSelect: "none", opacity: .5 }} title={CATEGORIES[item.category]?.label}>{CATEGORIES[item.category]?.emoji}</span>
                    </div>
                  </SwipeRow>
                ))}
              </>
            )}

            {Array.from({ length: blankLines }).map((_, i) => (
              <div key={`b${i}`} style={{ height: LINE_H, borderBottom: "1px solid var(--line)" }} onTouchStart={onBTS} onTouchEnd={onBTE} />
            ))}
          </div>
        </div>

        {/* Pagination */}
        {totalPages > 1 && (
          <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 14, paddingTop: 12, paddingBottom: 4, position: "relative", zIndex: 1 }}>
            <button className="g-nav" onClick={prevPage} disabled={page === 0 || animating} style={{ width: 28, height: 28, borderRadius: "50%", border: `1.5px solid var(--border-btn)`, background: "transparent", color: "var(--ink-soft)", fontSize: 18, cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", transition: "all .15s", fontFamily: "system-ui", lineHeight: 1, padding: 0 }}>‹</button>
            <div style={{ display: "flex", gap: 6, alignItems: "center" }}>
              {Array.from({ length: totalPages }).map((_, i) => (
                <button key={i} className="g-dot" onClick={() => i !== page && goToPage(i, i > page ? "next" : "prev")}
                  style={{ width: i === page ? 9 : 7, height: i === page ? 9 : 7, borderRadius: "50%", background: i === page ? "var(--ink)" : "var(--line-dash)", border: "none", cursor: "pointer", padding: 0, transition: "all .2s" }} />
              ))}
            </div>
            <button className="g-nav" onClick={nextPage} disabled={page === totalPages - 1 || animating} style={{ width: 28, height: 28, borderRadius: "50%", border: `1.5px solid var(--border-btn)`, background: "transparent", color: "var(--ink-soft)", fontSize: 18, cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", transition: "all .15s", fontFamily: "system-ui", lineHeight: 1, padding: 0 }}>›</button>
          </div>
        )}
        {totalPages > 1 && <p style={{ textAlign: "center", fontSize: 11, color: "var(--ink-faint)", fontStyle: "italic", paddingTop: 3, fontFamily: "'DM Sans', sans-serif", position: "relative", zIndex: 1 }}>page {page + 1} of {totalPages}</p>}
      </div>

      {/* Toast */}
      {toast && (
        <div style={{ position: "fixed", bottom: 28, left: "50%", transform: "translateX(-50%)", background: "var(--toast-bg)", color: "var(--toast-fg)", padding: "8px 16px", borderRadius: 20, fontSize: 13, fontWeight: 500, boxShadow: "0 4px 20px rgba(0,0,0,.3)", animation: "toastIn .3s ease-out", zIndex: 100, fontFamily: "'DM Sans', sans-serif", display: "flex", alignItems: "center", gap: 10, maxWidth: "calc(100vw - 32px)", width: "auto" }}>
          <span style={{ flex: 1 }}>{toast}</span>
          {undoItem && <button onClick={handleUndo} style={{ background: "transparent", border: "1px solid rgba(128,128,128,.35)", color: "var(--toast-fg)", fontSize: 12, fontWeight: 600, padding: "3px 12px", borderRadius: 12, cursor: "pointer", fontFamily: "'DM Sans', sans-serif", whiteSpace: "nowrap" }}>Undo</button>}
        </div>
      )}
    </div>
  );
}
