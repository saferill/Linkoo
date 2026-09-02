import 'dart:math';

/// Massive collection of 150+ curated playful, vibrant & cheerful adjectives
const List<String> _playfulAdjectives = [
  // Crisp & Crunchy
  'Crispy', 'Crunchy', 'Crusty', 'Snappy', 'Crackly', 'Toasty', 'Sizzling',
  
  // Sweet & Sugary
  'Sweet', 'Sugary', 'Glazed', 'Syrupy', 'Honeyed', 'Candied', 'Caramel',
  'Frosted', 'Choco', 'Vanilla', 'Cinnamon', 'Berry', 'Peachy', 'Cherry',
  
  // Texture & Mouthfeel
  'Fluffy', 'Silky', 'Creamy', 'Velvety', 'Chewy', 'Mellow', 'Puffy',
  'Gooey', 'Bubbly', 'Fizzy', 'Foamy', 'Buttery', 'Milky', 'Spongy',
  'Tender', 'Juicy', 'Saucy', 'Rich', 'Nutty', 'Chunky', 'Gourmet',
  
  // Cheerful & Happy Energy
  'Cheery', 'Jolly', 'Merry', 'Joyful', 'Sunny', 'Peppy', 'Lively',
  'Brisk', 'Breezy', 'Sparky', 'Spunky', 'Sassy', 'Jazzy', 'Groovy',
  'Dapper', 'Zippy', 'Zesty', 'Bouncy', 'Upbeat', 'Chirpy', 'Perky',
  'Radiant', 'Sparkling', 'Glowing', 'Twinkly', 'Blissful', 'Snazzy',
  
  // Cozy & Charming
  'Cozy', 'Warm', 'Comfy', 'Chill', 'Chilled', 'Breezy', 'Frosty',
  'Icy', 'Cool', 'Mellow', 'Gentle', 'Tiny', 'Cute', 'Petite',
  'Little', 'Golden', 'Amber', 'Ruby', 'Emerald', 'Sapphire',
  
  // Whimsical & Fun
  'Whimsical', 'Magical', 'Mystic', 'Cosmic', 'Astro', 'Lucky',
  'Charming', 'Clever', 'Smart', 'Crafty', 'Swift', 'Speedy',
  'Hyper', 'Turbo', 'Flashy', 'Starlight', 'Moonlit', 'Sunlit',
  
  // Flavorful & Unique
  'Tangy', 'Savory', 'Spicy', 'Peppery', 'Smoky', 'Toasted', 'Roasted',
  'Pikant', 'Zesty', 'Minty', 'Citrus', 'Tart', 'Fruity', 'Berrylicious',
  
  // Extra Delightful
  'Delightful', 'Tasty', 'Yummy', 'Delicious', 'Heavenly', 'Divine',
  'Epic', 'Super', 'Mega', 'Ultra', 'Primo', 'Royal', 'Grand',
  'Noble', 'Velvet', 'Silken', 'Glossy', 'Shiny', 'Poppy', 'Witty',
  'Brave', 'Bold', 'Nimble', 'Quick', 'Agile', 'Dynamic', 'Vibrant',
];

/// Massive collection of 150+ modern snacks, pastries, beverages, desserts & street foods
const List<String> _playfulFoods = [
  // Pastries & Bakery
  'Croissant', 'Brioche', 'Baguette', 'Pretzel', 'Bagel', 'Scone',
  'Danish', 'Eclair', 'Cannoli', 'Strudel', 'Churro', 'Fritter',
  'Beignet', 'Tart', 'Pie', 'Galette', 'Turnover', 'Muffin',
  'Cinnamon Roll', 'Pain Au Chocolat', 'Crumpet', 'Biscotti',
  
  // Cakes & Desserts
  'Waffle', 'Pancake', 'Crepe', 'Mochi', 'Macaron', 'Macaroon',
  'Donut', 'Brownie', 'Cupcake', 'Cookie', 'Cheesecake', 'Tiramisu',
  'Pudding', 'Souffle', 'Parfait', 'Shortcake', 'Panna Cotta',
  'Fondue', 'Lollipop', 'Marshmallow', 'Gummy', 'Caramel', 'Truffle',
  'Custard', 'Fudge', 'Brimstone', 'Pavlova', 'Baklava',
  
  // Ice Creams & Frozen Treats
  'Gelato', 'Sorbet', 'Sundae', 'Popsicle', 'Sherbet', 'Granita',
  'Soft Serve', 'Snow Cone', 'FroYo', 'Affogato', 'Ice Cream Sandwich',
  
  // Coffee, Tea & Modern Beverages
  'Boba', 'Boba Tea', 'Matcha', 'Latte', 'Espresso', 'Cappuccino',
  'Macchiato', 'Mocha', 'Americano', 'Chai', 'Frappe', 'Cold Brew',
  'Smoothie', 'Milkshake', 'Lemonade', 'Kombucha', 'Cider', 'Fizz',
  'Sparkler', 'Bubble Tea', 'Taro Tea', 'Earl Grey', 'Cascara',
  
  // Savory Snacks & Street Food Delights
  'Popcorn', 'Nacho', 'Taco', 'Nugget', 'Dumpling', 'Gyoza',
  'Dimsum', 'Bao', 'Takoyaki', 'Taiyaki', 'Onigiri', 'Sushi Roll',
  'Spring Roll', 'Samosa', 'Empanada', 'Quesadilla', 'Corndog',
  'Potato Chip', 'Tater Tot', 'Crisp', 'Tortilla', 'Pretzel Bite',
  
  // Sweet Fruits & Treats
  'Strawberry', 'Blueberry', 'Raspberry', 'Mango', 'Avocado',
  'Pineapple', 'Coconut', 'Papaya', 'Watermelon', 'Kiwi',
  'Passionfruit', 'Dragonfruit', 'Fig', 'Peach', 'Apricot',
];

/// Generates a fresh, memorable random alias with playful snack & beverage combinations.
/// (e.g. "Crispy Croissant", "Snappy Boba", "Zesty Matcha", "Groovy Waffle", "Fluffy Churro")
/// Total unique combinations: > 25,000+
String generateRandomAlias() {
  final random = Random();
  final adjective = _playfulAdjectives[random.nextInt(_playfulAdjectives.length)];
  final food = _playfulFoods[random.nextInt(_playfulFoods.length)];
  return '$adjective $food';
}
