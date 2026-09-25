class MealEntry {
  final int? id;
  final String date; // 'YYYY-MM-DD'
  final String mealName; // 'Завтрак', 'Обед' и т.д.
  final double? glucose;
  final double? breadUnits;
  final double? insulin;
  final String note;

  MealEntry({
    this.id,
    required this.date,
    required this.mealName,
    this.glucose,
    this.breadUnits,
    this.insulin,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'meal_name': mealName,
      'glucose': glucose,
      'bread_units': breadUnits,
      'insulin': insulin,
      'note': note,
    };
  }

  factory MealEntry.fromMap(Map<String, dynamic> map) {
    return MealEntry(
      id: map['id'] as int?,
      date: map['date'] as String,
      mealName: map['meal_name'] as String,
      glucose: (map['glucose'] as num?)?.toDouble(),
      breadUnits: (map['bread_units'] as num?)?.toDouble(),
      insulin: (map['insulin'] as num?)?.toDouble(),
      note: (map['note'] as String?) ?? '',
    );
  }

  bool get isEmpty =>
      glucose == null &&
      breadUnits == null &&
      insulin == null &&
      note.trim().isEmpty;
}
