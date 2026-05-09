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
    // تنظيف النص
    final cleanText = text
        .replaceAll(RegExp(r'[,،]'), '.')
        .replaceAll(RegExp(r'\s+'), ' ');

    final lines = cleanText.split('\n').map((l) => l.trim()).toList();
    final fullText = lines.join(' ');

    // استخراج القيم
    final calories = _extractValue(fullText, [
      r'(?:calories?|energy|سعر|طاقة|cal|kcal)[:\s]*(\d+\.?\d*)',
      r'(\d+\.?\d*)\s*(?:kcal|cal|سعر)',
    ]);

    final protein = _extractValue(fullText, [
      r'(?:protein|بروتين|prote[ií]n)[:\s]*(\d+\.?\d*)',
      r'(\d+\.?\d*)\s*(?:g|جم|جرام)\s*(?:protein|بروتين)',
    ]);

    final carbs = _extractValue(fullText, [
      r'(?:carbohydrate|carbs?|كربوهيدرات|نشويات|total\s*carb)[:\s]*(\d+\.?\d*)',
      r'(\d+\.?\d*)\s*(?:g|جم|جرام)\s*(?:carb|كربو)',
    ]);

    final fat = _extractValue(fullText, [
      r'(?:total\s*fat|fat|دهون|دهن|lipid)[:\s]*(\d+\.?\d*)',
      r'(\d+\.?\d*)\s*(?:g|جم|جرام)\s*(?:fat|دهون)',
    ]);

    final fiber = _extractValue(fullText, [
      r'(?:fiber|fibre|ألياف)[:\s]*(\d+\.?\d*)',
    ]);

    final sugar = _extractValue(fullText, [
      r'(?:sugar|سكر|سكريات)[:\s]*(\d+\.?\d*)',
    ]);

    final sodium = _extractValue(fullText, [
      r'(?:sodium|صوديوم|ملح)[:\s]*(\d+\.?\d*)',
    ]);

    // حجم الحصة
    final servingSize = _extractValue(fullText, [
      r'(?:serving\s*size|حجم الحصة|الحصة)[:\s]*(\d+\.?\d*)\s*(?:g|جم|مل|ml)',
      r'(?:per|لكل)\s*(\d+\.?\d*)\s*(?:g|جم)',
    ]);

    // اكتشاف إذا كانت القيم لكل حصة وليس لكل 100 جم
    double factor = 1.0;
    if (servingSize != null && servingSize > 0 && servingSize != 100) {
      // تحقق إذا كانت القيم لكل حصة (وليس لكل 100 جم)
      final hasPerServing = RegExp(r'per\s*serving|لكل حصة|per\s*portion', caseSensitive: false).hasMatch(fullText);
      final hasPer100 = RegExp(r'per\s*100|لكل 100', caseSensitive: false).hasMatch(fullText);

      if (hasPerServing && !hasPer100) {
        // القيم لكل حصة → حوّل لكل 100 جم
        factor = 100.0 / servingSize;
      }
    }

    final result = NutritionLabel(
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

    return result.isValid ? result : null;
  }

  /// استخراج قيمة رقمية من النص باستخدام أنماط Regex متعددة
  static double? _extractValue(String text, List<String> patterns) {
    for (final pattern in patterns) {
      final match = RegExp(pattern, caseSensitive: false).firstMatch(text);
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
