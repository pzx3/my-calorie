class Validator {
  static String? name(String? v) {
    if (v == null || v.trim().isEmpty) return 'يرجى إدخال الاسم';
    if (v.length > 20) return 'الاسم طويل جداً';
    return null;
  }

  static String? age(String? v) {
    if (v == null || v.trim().isEmpty) return 'يرجى إدخال العمر';
    final n = int.tryParse(v);
    if (n == null) return 'يرجى إدخال رقم صحيح';
    if (n < 5 || n > 110) return 'العمر يجب أن يكون بين 5 و 110';
    return null;
  }

  static String? height(String? v) {
    if (v == null || v.trim().isEmpty) return 'يرجى إدخال الطول';
    final n = double.tryParse(v);
    if (n == null) return 'يرجى إدخال رقم صحيح';
    if (n < 40 || n > 250) return 'الطول يجب أن يكون بين 40 و 250 سم';
    return null;
  }

  static String? weight(String? v) {
    if (v == null || v.trim().isEmpty) return 'يرجى إدخال الوزن';
    final n = double.tryParse(v);
    if (n == null) return 'يرجى إدخال رقم صحيح';
    if (n < 20 || n > 350) return 'الوزن يجب أن يكون بين 20 و 350 كجم';
    return null;
  }

  static String? waterGoal(String? v) {
    if (v == null || v.trim().isEmpty) return 'يرجى إدخال هدف الماء';
    final n = int.tryParse(v);
    if (n == null) return 'يرجى إدخال رقم صحيح';
    if (n < 500 || n > 10000) return 'الهدف يجب أن يكون بين 500 و 10000 مل';
    return null;
  }

  static String? cupSize(String? v, bool isOz) {
    if (v == null || v.trim().isEmpty) return 'يرجى إدخال حجم الكوب';
    final n = int.tryParse(v);
    if (n == null) return 'يرجى إدخال رقم صحيح';
    if (isOz) {
      if (n < 2 || n > 64) return 'الحجم يجب أن يكون بين 2 و 64 oz';
    } else {
      if (n < 50 || n > 2000) return 'الحجم يجب أن يكون بين 50 و 2000 مل';
    }
    return null;
  }

  static String? calories(String? v) {
    if (v == null || v.trim().isEmpty) return 'يرجى إدخال السعرات';
    final n = int.tryParse(v);
    if (n == null) return 'يرجى إدخال رقم صحيح';
    if (n < 0 || n > 10000) return 'السعرات يجب أن تكون بين 0 و 10000';
    return null;
  }
}
