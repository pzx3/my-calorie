class MealType {
  static const String breakfast = 'breakfast';
  static const String lunch     = 'lunch';
  static const String dinner    = 'dinner';
  static const String snack     = 'snack';
  static const List<String> all = [breakfast, lunch, dinner, snack];

  static String label(String t) => const {
    'breakfast': 'الإفطار', 'lunch': 'الغداء',
    'dinner': 'العشاء',    'snack': 'وجبة خفيفة',
  }[t] ?? 'أخرى';

  static String emoji(String t) => const {
    'breakfast': '🌅', 'lunch': '☀️', 'dinner': '🌙', 'snack': '🍎',
  }[t] ?? '🍽️';
}

class FoodItem {
  final String name;
  final double calories, protein, carbs, fat;
  final String serving;
  const FoodItem({required this.name, required this.calories,
    required this.protein, required this.carbs, required this.fat,
    required this.serving});

  static const List<FoodItem> database = [];
}

class FoodEntry {
  final String id, name, mealType;
  final double calories, protein, carbs, fat, quantity;
  final String unit;
  final DateTime dateTime;

  const FoodEntry({
    required this.id, required this.name, required this.mealType,
    required this.calories, required this.protein,
    required this.carbs, required this.fat,
    required this.dateTime, this.quantity = 1.0, this.unit = 'حصة',
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'mealType': mealType,
    'calories': calories, 'protein': protein, 'carbs': carbs, 'fat': fat,
    'quantity': quantity, 'unit': unit, 'dateTime': dateTime.toIso8601String(),
  };

  factory FoodEntry.fromJson(Map<String, dynamic> j) => FoodEntry(
    id: j['id']?.toString() ?? '', 
    name: j['name']?.toString() ?? '', 
    mealType: j['mealType']?.toString() ?? '',
    calories: (j['calories'] as num?)?.toDouble() ?? 0.0,
    protein:  (j['protein']  as num?)?.toDouble() ?? 0.0,
    carbs:    (j['carbs']    as num?)?.toDouble() ?? 0.0,
    fat:      (j['fat']      as num?)?.toDouble() ?? 0.0,
    quantity: (j['quantity'] as num?)?.toDouble() ?? 1.0,
    unit: j['unit']?.toString() ?? 'حصة', 
    dateTime: j['dateTime'] != null ? DateTime.tryParse(j['dateTime'].toString()) ?? DateTime.now() : DateTime.now(),
  );
}
