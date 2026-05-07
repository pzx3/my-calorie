class Validator {
  static String? name(String? v) {
    if (v == null || v.trim().isEmpty) return 'الرجاء إدخال الاسم';
    if (v.length > 20) return 'الاسم طويل جداً';
    return null;
  }

  static String? age(String? v) {
    final n = int.tryParse(v ?? '');
    if (n == null || n < 5 || n > 110) return 'عمر غير منطقي (5-110)';
    return null;
  }

  static String? height(String? v) {
    final n = double.tryParse(v ?? '');
    if (n == null || n < 40 || n > 250) return 'طول غير منطقي (40-250)';
    return null;
  }

  static String? weight(String? v) {
    final n = double.tryParse(v ?? '');
    if (n == null || n < 20 || n > 350) return 'وزن غير منطقي (20-350)';
    return null;
  }

  static String? waterGoal(String? v) {
    final n = int.tryParse(v ?? '');
    if (n == null || n < 500 || n > 10000) return 'هدف غير منطقي (500-10000)';
    return null;
  }

  static String? cupSize(String? v, bool isOz) {
    final n = int.tryParse(v ?? '');
    if (isOz) {
      if (n == null || n < 2 || n > 64) return 'حجم غير منطقي (2-64 oz)';
    } else {
      if (n == null || n < 50 || n > 2000) return 'حجم غير منطقي (50-2000 مل)';
    }
    return null;
  }

  static String? calories(String? v) {
    final n = int.tryParse(v ?? '');
    if (n == null || n < 0 || n > 10000) return 'قيمة غير منطقية';
    return null;
  }
}
