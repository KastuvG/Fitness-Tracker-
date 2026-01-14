class WeightEntry {
  final String id;
  final double weight;        // kg (or lb if you prefer)
  final DateTime date;        // date the weight was taken
  final String? note;

  WeightEntry({
    required this.id,
    required this.weight,
    required this.date,
    this.note,
  });

  factory WeightEntry.fromJson(Map<String, dynamic> j) => WeightEntry(
    id: j['id'] as String,
    weight: (j['weight'] as num).toDouble(),
    date: DateTime.parse(j['date'] as String),
    note: j['note'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'weight': weight,
    'date': DateTime(date.year, date.month, date.day).toIso8601String(),
    'note': note,
  };
}
