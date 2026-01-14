class FoodItem {
  final String id;           // unique id
  final String name;
  final int calories;        // per serving
  final int protein;         // grams
  final int carbs;           // grams
  final int sugar;           // grams

  FoodItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.sugar,
  });

  factory FoodItem.fromJson(Map<String, dynamic> j) => FoodItem(
    id: j['id'] as String,
    name: j['name'] as String,
    calories: j['calories'] as int,
    protein: j['protein'] as int,
    carbs: j['carbs'] as int,
    sugar: j['sugar'] as int,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'sugar': sugar,
  };
}
