/// Evidence-based health calculators aligned with Saudi MOH guidelines.
///
/// References:
///   - وزارة الصحة السعودية (MOH) — حاسبة كتلة الجسم
///   - وزارة الصحة السعودية (MOH) — حساب احتياج البالغين للماء
///   - BMR: Mifflin-St Jeor equation (ACSM / ADA recommended)
///   - TDEE: BMR × activity multiplier (Harris-Benedict revised factors)
///
/// BMI Classification (Saudi MOH / WHO):
///   < 18.5        → نقص في الوزن (نحافة)
///   18.5 – 24.9   → وزن طبيعي
///   25.0 – 29.9   → زيادة في الوزن
///   30.0 – 34.9   → سمنة درجة أولى
///   35.0 – 39.9   → سمنة درجة ثانية
///   ≥ 40.0        → سمنة مفرطة
///
/// Water formula (Saudi MOH):
///   Base: 30-35 مل لكل كيلوجرام من وزن الجسم
///   Activity adjustment: +5 مل/كجم for active individuals
///
/// Ideal Weight:
///   Based on BMI 21.7 (midpoint of MOH healthy range 18.5–24.9)
class CalorieCalculator {
  // ──────────────────── BMR ────────────────────
  /// Mifflin-St Jeor (1990)
  /// Men:   (10 × weight_kg) + (6.25 × height_cm) − (5 × age) + 5
  /// Women: (10 × weight_kg) + (6.25 × height_cm) − (5 × age) − 161
  static double bmr({
    required double weightKg,
    required double heightCm,
    required int    age,
    required String gender,
  }) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return gender == 'male' ? base + 5 : base - 161;
  }

  // ──────────────────── TDEE ────────────────────
  /// TDEE = BMR × Activity Factor (Harris-Benedict revised)
  static double tdee({required double bmr, required String activityLevel}) {
    const factors = {
      'sedentary':  1.2,    // Desk job, no exercise
      'light':      1.375,  // Light exercise 1-3 days/week
      'moderate':   1.55,   // Moderate exercise 3-5 days/week
      'active':     1.725,  // Hard exercise 6-7 days/week
      'veryActive': 1.9,    // 2× training or physical job
    };
    return bmr * (factors[activityLevel] ?? 1.2);
  }

  // ──────────────────── Goal Calories ────────────────────
  /// Applies a percentage adjustment to TDEE:
  ///   lose:     −20% (moderate deficit ≈ 500 kcal for average TDEE)
  ///   maintain: ±0%
  ///   gain:     +15% (lean surplus, minimise fat gain)
  ///
  /// Result is clamped to safe floor to prevent metabolic damage.
  static int goalCalories({
    required double tdee,
    required String goal,
    required String gender,
  }) {
    double raw;
    switch (goal) {
      case 'lose':
        raw = tdee * 0.80;
        break;
      case 'gain':
        raw = tdee * 1.15;
        break;
      default:
        raw = tdee;
    }
    // Never below safe minimum
    final floor = safeFloor(gender);
    return raw.round().clamp(floor, 9999);
  }

  /// Minimum daily calories (NHS / WebMD consensus)
  static int safeFloor(String gender) => gender == 'male' ? 1500 : 1200;

  // ──────────────────── Slider Ranges ────────────────────
  /// Min for the custom calorie slider on results screen
  static int minCalories({required double tdee, required String goal, required String gender}) {
    final floor = safeFloor(gender);
    switch (goal) {
      case 'lose':
        // Allow up to 30% deficit but never below safe floor
        return (tdee * 0.70).round().clamp(floor, tdee.round());
      case 'gain':
        return tdee.round();
      default:
        return (tdee * 0.90).round().clamp(floor, tdee.round());
    }
  }

  static int maxCalories({required double tdee, required String goal}) {
    switch (goal) {
      case 'lose':
        return (tdee * 0.95).round(); // Small deficit still counts
      case 'gain':
        return (tdee * 1.30).round(); // Max 30% surplus
      default:
        return (tdee * 1.10).round();
    }
  }

  // ──────────────────── Water Goal (Saudi MOH) ────────────────────
  /// Water intake calculation based on Saudi MOH guidelines.
  ///
  /// وزارة الصحة السعودية — حساب احتياج البالغين للماء:
  ///   القاعدة: 30-35 مل لكل كيلوجرام من وزن الجسم في حالة الراحة
  ///   يزداد الاحتياج مع زيادة النشاط البدني والأجواء الحارة
  ///
  /// Implementation:
  ///   Base rate: 30 mL/kg (sedentary / rest)
  ///   Activity adjustment: +2 mL/kg per activity level step
  ///   Final rounded to nearest 50 mL
  ///   Clamped: min 1500 mL, max 5000 mL
  static int waterGoalMl({
    required double weightKg,
    required String gender,
    String activityLevel = 'sedentary',
  }) {
    // MOH base: 30 مل/كجم في حالة الراحة
    // Activity increases rate (Saudi climate consideration +2 mL/kg per level)
    const mlPerKg = {
      'sedentary':  30.0,   // راحة تامة — 30 مل/كجم
      'light':      33.0,   // نشاط خفيف — 33 مل/كجم
      'moderate':   35.0,   // نشاط متوسط — 35 مل/كجم
      'active':     38.0,   // نشاط مكثف — 38 مل/كجم
      'veryActive': 40.0,   // نشاط عالي جداً — 40 مل/كجم
    };
    final rate = mlPerKg[activityLevel] ?? 30.0;
    final waterMl = weightKg * rate;

    // Round to nearest 50 mL for cleanliness
    return ((waterMl / 50).round() * 50).clamp(1500, 5000);
  }

  // ──────────────────── BMI (Saudi MOH / WHO) ────────────────────
  /// BMI = weight(kg) / height(m)²
  static double calculateBMI(double weightKg, double heightCm) =>
      weightKg / ((heightCm / 100) * (heightCm / 100));

  /// BMI classification per Saudi MOH / WHO standards (6 categories)
  ///   < 18.5        → نقص في الوزن (نحافة)
  ///   18.5 – 24.9   → وزن طبيعي
  ///   25.0 – 29.9   → زيادة في الوزن
  ///   30.0 – 34.9   → سمنة درجة أولى
  ///   35.0 – 39.9   → سمنة درجة ثانية
  ///   ≥ 40.0        → سمنة مفرطة
  static String bmiCategory(double bmi) {
    if (bmi < 18.5) return 'نقص في الوزن';
    if (bmi < 25.0) return 'وزن طبيعي ✅';
    if (bmi < 30.0) return 'زيادة في الوزن';
    if (bmi < 35.0) return 'سمنة درجة أولى';
    if (bmi < 40.0) return 'سمنة درجة ثانية';
    return 'سمنة مفرطة ⚠️';
  }

  // ──────────────────── Ideal Weight (Saudi MOH) ────────────────────
  /// Ideal weight = target BMI × height(m)²
  ///
  /// Target BMI: 21.7 (midpoint of MOH healthy range 18.5–24.9)
  /// Age adjustment: slight increase for older adults (+0.03/year over 40)
  /// as WHO acknowledges slightly higher BMI may be protective in elderly.
  ///
  /// Clamped between 40-130 kg for safety.
  static double idealWeight({required double heightCm, required int age}) {
    final hMeters = heightCm / 100;
    // Midpoint of Saudi MOH healthy range (18.5 + 24.9) / 2 = 21.7
    double targetBmi = 21.7;

    // Minor age adjustment for adults over 40 (WHO consideration)
    if (age > 40) {
      targetBmi += (age - 40) * 0.03;
    }

    // Cap target BMI at 24.9 (upper healthy limit per MOH)
    targetBmi = targetBmi.clamp(18.5, 24.9);

    return (targetBmi * hMeters * hMeters).clamp(40.0, 130.0);
  }

  /// Returns the healthy weight range per Saudi MOH (BMI 18.5–24.9)
  static Map<String, double> healthyWeightRange({required double heightCm}) {
    final hMeters = heightCm / 100;
    return {
      'min': (18.5 * hMeters * hMeters),
      'max': (24.9 * hMeters * hMeters),
    };
  }

  static Map<String, double> macroGoals({required int kcal, required String goal}) {
    double proteinRatio, carbsRatio, fatRatio;
    switch (goal) {
      case 'lose':
        proteinRatio = 0.40;
        carbsRatio = 0.30;
        fatRatio = 0.30;
        break;
      case 'gain':
        proteinRatio = 0.30;
        carbsRatio = 0.50;
        fatRatio = 0.20;
        break;
      case 'maintain':
      default:
        proteinRatio = 0.30;
        carbsRatio = 0.40;
        fatRatio = 0.30;
        break;
    }
    return {
      'protein': (kcal * proteinRatio / 4).roundToDouble(),
      'carbs':   (kcal * carbsRatio / 4).roundToDouble(),
      'fat':     (kcal * fatRatio / 9).roundToDouble(),
    };
  }
}

