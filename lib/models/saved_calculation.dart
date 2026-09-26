class SavedCalculation {
  final int? id;
  final String createdAt; // ISO 8601
  final String productName;
  final double carbsPer100;
  final double weight;
  final double breadUnits;
  final double carbsInPortion;
  final String? photoPath; // путь к файлу фото

  SavedCalculation({
    this.id,
    required this.createdAt,
    this.productName = '',
    required this.carbsPer100,
    required this.weight,
    required this.breadUnits,
    required this.carbsInPortion,
    this.photoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'created_at': createdAt,
      'product_name': productName,
      'carbs_per_100': carbsPer100,
      'weight': weight,
      'bread_units': breadUnits,
      'carbs_in_portion': carbsInPortion,
      'photo_path': photoPath,
    };
  }

  factory SavedCalculation.fromMap(Map<String, dynamic> map) {
    return SavedCalculation(
      id: map['id'] as int?,
      createdAt: map['created_at'] as String,
      productName: (map['product_name'] as String?) ?? '',
      carbsPer100: (map['carbs_per_100'] as num).toDouble(),
      weight: (map['weight'] as num).toDouble(),
      breadUnits: (map['bread_units'] as num).toDouble(),
      carbsInPortion: (map['carbs_in_portion'] as num).toDouble(),
      photoPath: map['photo_path'] as String?,
    );
  }
}
