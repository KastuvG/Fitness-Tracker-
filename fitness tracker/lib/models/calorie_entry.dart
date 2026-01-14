class CalorieEntry {
  final String id;
  final String name;
  final int calories;
  final int protein; // g
  final int carbs;   // g
  final int sugar;   // g
  final DateTime createdAt;

  CalorieEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.sugar,
    required this.createdAt,
  });

  factory CalorieEntry.fromJson(Map<String, dynamic> j) => CalorieEntry(
    id: j['id'] as String,
    name: j['name'] as String,
    calories: j['calories'] as int,
    protein: j['protein'] as int,
    carbs: j['carbs'] as int,
    sugar: j['sugar'] as int,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'sugar': sugar,
    'createdAt': createdAt.toIso8601String(),
  };
}
