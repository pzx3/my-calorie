import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:huawei_scan/hms_scan_library.dart';

/// نموذج بيانات القيمة الغذائية المستخرجة (لكل 100 جم داخلياً)
class NutritionLabel {
  final String? productName;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  
  // الدهون المفصلة
  final double? saturatedFatPer100g;
  final double? transFatPer100g;
  
  // الكربوهيدرات المفصلة
  final double? fiberPer100g;
  final double? sugarPer100g;
  final double? addedSugarPer100g;
  
  // المعادن والفيتامينات
  final double? sodiumPer100g;
  final double? cholesterolPer100g;
  final double? vitaminDPer100g;
  final double? calciumPer100g;
  final double? ironPer100g;
  final double? potassiumPer100g;

  final double? servingSizeG; // حجم الحصة المكتشف بالجرام
  final String rawText;

  const NutritionLabel({
    this.productName,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.saturatedFatPer100g,
    this.transFatPer100g,
    this.fiberPer100g,
    this.sugarPer100g,
    this.addedSugarPer100g,
    this.sodiumPer100g,
    this.cholesterolPer100g,
    this.vitaminDPer100g,
    this.calciumPer100g,
    this.ironPer100g,
    this.potassiumPer100g,
    this.servingSizeG,
    required this.rawText,
  });

  bool get isValid => caloriesPer100g > 0 || proteinPer100g > 0 || carbsPer100g > 0 || fatPer100g > 0;
}

/// خدمة مسح وتحليل ملصقات القيمة الغذائية
class NutritionLabelService {

  /// مسح صورة واستخراج بيانات القيمة الغذائية
  static Future<NutritionLabel?> scanImage(File imageFile) async {
    try {
      String rawText = '';
      
      final request = HmsTextAnalyzerRequest(path: imageFile.path);
      final result = await HmsTextAnalyzer.analyzeText(request);
      
      if (result.text != null && result.text!.isNotEmpty) {
        rawText = result.text!;
        debugPrint('═══ Huawei OCR Raw Text ═══\n$rawText\n═══════════════════');
      }

      if (rawText.trim().isEmpty) return null;

      return _parseNutritionText(rawText);
    } catch (e) {
      debugPrint('OCR Error: $e');
      return null;
    }
  }

  /// تحليل النص المستخرج واستخراج القيم الغذائية
  static NutritionLabel? _parseNutritionText(String text) {
    // 1. تنظيف النص وتحويله لحروف صغيرة
    String cleanText = text.toLowerCase();

    // 2. معالجة أخطاء OCR الشائعة (O -> 0)
    cleanText = cleanText.replaceAllMapped(RegExp(r'(\d)[oO](\d)'), (m) => '${m[1]}0${m[2]}');
    cleanText = cleanText.replaceAllMapped(RegExp(r'(\d)[oO]'), (m) => '${m[1]}0');
    cleanText = cleanText.replaceAllMapped(RegExp(r'[oO](\d)'), (m) => '0${m[1]}');

    // 3. توحيد الفواصل العشرية
    cleanText = cleanText.replaceAll(RegExp(r'[,،]'), '.');

    // 4. تحويل الأرقام العربية إلى إنجليزية
    const arabicToEnglish = {
      '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
      '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
    };
    arabicToEnglish.forEach((key, value) {
      cleanText = cleanText.replaceAll(key, value);
    });

    // 5. استخراج حجم الحصة (Serving Size) - ضروري جداً للحسابات الصحيحة
    final servingSize = _expertExtract(cleanText, [
      'serving size', 'حجم الحصة', 'الحصة', 'per serving', 'size', '1 pack', '1 unit', '1 bar', 'لوح'
    ], isServing: true);

    // 6. استخراج القيم الأساسية
    final calories = _expertExtract(cleanText, ['calories', 'energy', 'سعرات', 'طاقة', 'سعر حراري', 'كالوري', 'kcal']);
    final protein = _expertExtract(cleanText, ['protein', 'بروتين', 'بروتينات', 'prote']);
    final carbs = _expertExtract(cleanText, ['carbohydrate', 'كربوهيدرات', 'كارب', 'نشويات', 'carb']);
    final fat = _expertExtract(cleanText, ['fat', 'دهون', 'الدسم', 'مجموع الدهون', 'دسم', 'lipid']);
    
    final fiber = _expertExtract(cleanText, ['fiber', 'fibre', 'ألياف']);
    final sugar = _expertExtract(cleanText, ['sugar', 'سكر', 'سكريات']);
    final sodium = _expertExtract(cleanText, ['sodium', 'صوديوم', 'ملح', 'صوديم']);

    // 7. منطق الحساب المتقدم (Normalization)
    double factor = 1.0;
    if (servingSize != null && servingSize > 0) {
      // نبحث عن مؤشرات أن القيم هي لكل حصة
      final hasPerServing = RegExp(r'per\s*serving|لكل حصة|per\s*portion|amount\s*per|حصة', caseSensitive: false).hasMatch(cleanText);
      final hasPer100 = RegExp(r'per\s*100|لكل 100', caseSensitive: false).hasMatch(cleanText);

      // إذا كانت القيم لكل حصة، نحولها لـ 100 جم للتخزين الموحد
      if (hasPerServing && !hasPer100) {
        factor = 100.0 / servingSize;
      }
    }

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

  static double? _expertExtract(String text, List<String> keywords, {bool isServing = false}) {
    for (final keyword in keywords) {
      final index = text.indexOf(keyword.toLowerCase());
      if (index == -1) continue;

      final searchArea = text.substring(index + keyword.length, 
          (index + keyword.length + 50).clamp(0, text.length));
      
      if (isServing) {
        // نبحث عن وزن الجرامات داخل الأقواس أو بعدها مباشرة
        final servingMatch = RegExp(r'(\d+\.?\d*)\s*(?:g|جم|مل|ml|غ|غرام)').firstMatch(searchArea);
        if (servingMatch != null) return double.tryParse(servingMatch.group(1)!);
      }

      final numMatch = RegExp(r'(\d+\.?\d*)').firstMatch(searchArea);
      if (numMatch != null) {
        return double.tryParse(numMatch.group(1)!);
      }
    }
    return null;
  }

  static void dispose() {}
}
