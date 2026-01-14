class WorkoutEntry {
  final String id;
  final String exercise;     // e.g., Barbell Bench Press
  final String bodyPart;     // e.g., Chest, Back, Legs, Shoulders, Arms, Core, Full Body, Other
  final double weight;       // use your unit (kg/lb)
  final int reps;
  final DateTime createdAt;
  final String? notes;

  WorkoutEntry({
    required this.id,
    required this.exercise,
    required this.bodyPart,
    required this.weight,
    required this.reps,
    required this.createdAt,
    this.notes,
  });

  factory WorkoutEntry.fromJson(Map<String, dynamic> j) => WorkoutEntry(
    id: j['id'] as String,
    exercise: j['exercise'] as String,
    bodyPart: j['bodyPart'] as String,
    weight: (j['weight'] as num).toDouble(),
    reps: j['reps'] as int,
    createdAt: DateTime.parse(j['createdAt'] as String),
    notes: j['notes'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'exercise': exercise,
    'bodyPart': bodyPart,
    'weight': weight,
    'reps': reps,
    'createdAt': createdAt.toIso8601String(),
    'notes': notes,
  };
}
