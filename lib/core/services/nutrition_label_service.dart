import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// نموذج بيانات القيمة الغذائية المستخرجة (لكل 100 جم)
class NutritionLabel {
  final String? productName;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double? fiberPer100g;
  final double? sugarPer100g;
  final double? sodiumPer100g;
  final double? servingSizeG;
  final String rawText;

  const NutritionLabel({
    this.productName,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.fiberPer100g,
    this.sugarPer100g,
    this.sodiumPer100g,
    this.servingSizeG,
    required this.rawText,
  });

  /// حساب القيم الفعلية بناءً على الكمية بالجرام
  Map<String, double> calculateForGrams(double grams) {
    final factor = grams / 100.0;
    return {
      'calories': caloriesPer100g * factor,
      'protein': proteinPer100g * factor,
      'carbs': carbsPer100g * factor,
      'fat': fatPer100g * factor,
    };
  }

  bool get isValid => caloriesPer100g > 0 || proteinPer100g > 0 || carbsPer100g > 0 || fatPer100g > 0;
}

/// خدمة مسح وتحليل ملصقات القيمة الغذائية
class NutritionLabelService {
  static final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// مسح صورة واستخراج بيانات القيمة الغذائية
  static Future<NutritionLabel?> scanImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognized = await _textRecognizer.processImage(inputImage);
      final rawText = recognized.text;

      debugPrint('═══ OCR Raw Text ═══\n$rawText\n═══════════════════');

      if (rawText.trim().isEmpty) return null;

      return _parseNutritionText(rawText);
    } catch (e) {
      debugPrint('OCR Error: $e');
      return null;
    }
  }

  /// تحليل النص المستخرج واستخراج القيم الغذائية
  static NutritionLabel? _parseNutritionText(String text) {
    // تنظيف النص الأساسي لتسهيل البحث
    String cleanText = text.replaceAll(RegExp(r'[,،]'), '.').toLowerCase();

    // تحويل الأرقام العربية إلى إنجليزية
    const arabicToEnglish = {
      '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
      '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
    };
    arabicToEnglish.forEach((key, value) {
      cleanText = cleanText.replaceAll(key, value);
    });

    // استخراج القيم باستخدام تعبيرات مرنة
    final calories = _extractValue(cleanText, [
      r'(?:calories?|energy|سعرات|سعره|سعر|طاقة|الطاقة|سعر حراري|كالوري|cal|kcal)[^0-9\n]*(\d+\.?\d*)',
      r'(\d+\.?\d*)\s*(?:kcal|cal|سعر حراري|كالوري|سعر)',
    ]);

    final protein = _extractValue(cleanText, [
      r'(?:protein|بروتين|بروتينات|prote[ií]n)[^0-9\n]*(\d+\.?\d*)',
      r'(\d+\.?\d*)\s*(?:g|جم|جرام|غ|غرام|غ\s*/\s*غ)[^0-9\n]*(?:protein|بروتين)',
      r'(\d+\.?\d*)\s*protein',
    ]);

    final carbs = _extractValue(cleanText, [
      r'(?:carbohydrates?|carbs?|كربوهيدرات|الكربوهيدرات الكلية|كارب|نشويات|total\s*carb|سكريات كلي)[^0-9\n]*(\d+\.?\d*)',
      r'(\d+\.?\d*)\s*(?:g|جم|جرام|غ|غرام|غ\s*/\s*غ)[^0-9\n]*(?:carb|كربوهيدرات|كارب)',
      r'(\d+\.?\d*)\s*total\s*carb',
    ]);

    final fat = _extractValue(cleanText, [
      r'(?:total\s*fat|fat|دهون|الدهون الكلية|مجموع الدهون|الدسم الكلي|دهن|دسم|lipid)[^0-9\n]*(\d+\.?\d*)',
      r'(\d+\.?\d*)\s*(?:g|جم|جرام|غ|غرام|غ\s*/\s*غ)[^0-9\n]*(?:fat|دهون|دسم)',
      r'(\d+\.?\d*)\s*total\s*fat',
    ]);

    final fiber = _extractValue(cleanText, [
      r'(?:fiber|fibre|ألياف|الياف|الألياف الغذائية)[^0-9\n]*(\d+\.?\d*)',
    ]);

    final sugar = _extractValue(cleanText, [
      r'(?:sugar|سكر|سكريات|سكر كلي|سكريات كلية)[^0-9\n]*(\d+\.?\d*)',
    ]);

    final sodium = _extractValue(cleanText, [
      r'(?:sodium|صوديوم|ملح|صوديم)[^0-9\n]*(\d+\.?\d*)',
    ]);

    // حجم الحصة
    final servingSize = _extractValue(cleanText, [
      r'(?:serving\s*size|حجم الحصة|الحصة|لكل حصة|per\s*serving)[^0-9\n]*.*?(\d+\.?\d*)\s*(?:g|جم|مل|ml|غ|غرام)',
      r'(?:per|لكل)[^0-9\n]*(\d+\.?\d*)\s*(?:g|جم|غ|غرام)',
      r'(\d+\.?\d*)\s*(?:g|جم|غ|غرام)[^0-9\n]*serving',
    ]);

    // اكتشاف إذا كانت القيم لكل حصة وليس لكل 100 جم
    double factor = 1.0;
    if (servingSize != null && servingSize > 0 && servingSize != 100) {
      final hasPerServing = RegExp(r'per\s*serving|لكل حصة|per\s*portion', caseSensitive: false).hasMatch(cleanText);
      final hasPer100 = RegExp(r'per\s*100|لكل 100', caseSensitive: false).hasMatch(cleanText);

      if (hasPerServing && !hasPer100) {
        factor = 100.0 / servingSize;
      }
    }

    // إذا لم يجد شيئاً إطلاقاً
    if (calories == null && protein == null && carbs == null && fat == null) {
      return null;
    }

    return NutritionLabel(
      caloriesPer100g: (calories ?? 0) * factor,
      proteinPer100g: (protein ?? 0) * factor,
      carbsPer100g: (carbs ?? 0) * factor,
      fatPer100g: (fat ?? 0) * factor,
      fiberPer100g: fiber != null ? fiber * factor : null,
      sugarPer100g: sugar != null ? sugar * factor : null,
      sodiumPer100g: sodium,
      servingSizeG: servingSize,
      rawText: text,
    );
  }

  /// استخراج قيمة رقمية من النص باستخدام أنماط Regex متعددة
  static double? _extractValue(String text, List<String> patterns) {
    // 1. محاولة البحث في نفس السطر أولاً
    for (final pattern in patterns) {
      final match = RegExp(pattern, caseSensitive: false).firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        final value = double.tryParse(match.group(1)!);
        if (value != null && value >= 0) return value;
      }
    }
    
    // 2. محاولة البحث في الأسطر المجاورة (عن طريق السماح بتخطي مسافات أكثر أو أسطر جديدة)
    for (final pattern in patterns) {
      final crossLinePattern = pattern.replaceAll(r'[^0-9\n]*', r'[^0-9]{0,15}');
      final match = RegExp(crossLinePattern, caseSensitive: false).firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        final value = double.tryParse(match.group(1)!);
        if (value != null && value >= 0) return value;
      }
    }
    
    return null;
  }

  static void dispose() {
    _textRecognizer.close();
  }
}
