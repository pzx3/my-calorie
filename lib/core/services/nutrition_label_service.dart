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
  // ملاحظة: ML Kit يدعم حالياً اللاتينية والصينية والديفاناغاري واليابانية والكورية برمجياً
  // نستخدم المحرك اللاتيني ونعتمد على قوة معالجة النصوص (Logic) لاستخراج البيانات من الملصقات المزدوجة
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
    // 1. تنظيف النص وتحويله لحروف صغيرة
    String cleanText = text.toLowerCase();

    // 2. معالجة الأخطاء الشائعة في الـ OCR (مثل حرف O بدلاً من الصفر 0)
    // نقوم باستبدالها فقط إذا كانت محاطة بأرقام أو نقاط
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

    // 5. استخراج القيم (استراتيجية الخبير: البحث عن الكلمة المفتاحية ثم أقرب رقم بعدها)
    final calories = _expertExtract(cleanText, [
      'calories', 'energy', 'سعرات', 'طاقة', 'الطاقة', 'سعر حراري', 'كالوري', 'kcal'
    ]);

    final protein = _expertExtract(cleanText, [
      'protein', 'بروتين', 'بروتينات', 'prote'
    ]);

    final carbs = _expertExtract(cleanText, [
      'carbohydrate', 'كربوهيدرات', 'كارب', 'نشويات', 'carb', 'سكريات كلي'
    ]);

    final fat = _expertExtract(cleanText, [
      'fat', 'دهون', 'الدسم', 'مجموع الدهون', 'دسم', 'lipid'
    ]);

    final fiber = _expertExtract(cleanText, ['fiber', 'fibre', 'ألياف', 'الياف']);
    final sugar = _expertExtract(cleanText, ['sugar', 'سكر', 'سكريات']);
    final sodium = _expertExtract(cleanText, ['sodium', 'صوديوم', 'ملح', 'صوديم']);

    // حجم الحصة
    final servingSize = _expertExtract(cleanText, [
      'serving size', 'حجم الحصة', 'الحصة', 'per serving', 'size'
    ], isServing: true);

    // اكتشاف إذا كانت القيم لكل حصة وليس لكل 100 جم
    double factor = 1.0;
    if (servingSize != null && servingSize > 0 && servingSize != 100) {
      final hasPerServing = RegExp(r'per\s*serving|لكل حصة|per\s*portion|amount\s*per', caseSensitive: false).hasMatch(cleanText);
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

  /// استراتيجية الخبير لاستخراج القيمة:
  /// تبحث عن الكلمة المفتاحية، ثم تبحث عن أول رقم يظهر بعدها في نطاق معين
  static double? _expertExtract(String text, List<String> keywords, {bool isServing = false}) {
    for (final keyword in keywords) {
      final index = text.indexOf(keyword.toLowerCase());
      if (index == -1) continue;

      // نبحث في الـ 40 حرفاً التالية للكلمة المفتاحية
      final searchArea = text.substring(index + keyword.length, 
          (index + keyword.length + 40).clamp(0, text.length));
      
      // تعبير نمطي للبحث عن رقم (يدعم الفواصل العشرية)
      // إذا كنا نبحث عن حجم حصة، نهتم بالأرقام المتبوعة بـ g أو ml
      if (isServing) {
        final servingMatch = RegExp(r'(\d+\.?\d*)\s*(?:g|جم|مل|ml|غ|غرام)').firstMatch(searchArea);
        if (servingMatch != null) return double.tryParse(servingMatch.group(1)!);
      }

      final numMatch = RegExp(r'(\d+\.?\d*)').firstMatch(searchArea);
      if (numMatch != null) {
        final val = double.tryParse(numMatch.group(1)!);
        // نتجاهل الأرقام الصغيرة جداً (مثل 0.1) في السعرات إذا وجدنا رقماً أكبر
        if (val != null) return val;
      }
    }
    return null;
  }

  static void dispose() {
    _textRecognizer.close();
  }
}
