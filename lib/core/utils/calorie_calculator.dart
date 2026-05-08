/// Evidence-based health calculators aligned with Mithaly.sa standards.
///
/// References:
///   - mithaly.sa — حاسبة مؤشر كتلة الجسم
///   - BMR: Mifflin-St Jeor equation (ACSM / ADA recommended)
///   - TDEE: BMR × activity multiplier (Harris-Benedict revised factors)
///
/// BMI Classification (Mithaly.sa):
///   < 18.5        → نقص في الوزن (نحافة)
///   18.5 – 24.9   → وزن طبيعي
///   25.0 – 29.9   → زيادة في الوزن
///   30.0 – 34.9   → سمنة
///   ≥ 35.0        → سمنة مفرطة
///
/// Water formula (Mithaly.sa):
///   الوزن (كجم) × 0.033 = احتياج الماء باللتر
///
/// Ideal Weight (Mithaly.sa):
///   22 × (الطول بالمتر)²
///
/// Activity Levels (Mithaly.sa):
///   خامل (بدون تمارين):              BMR × 1.2
///   نشاط خفيف (1-3 أيام/أسبوع):     BMR × 1.375
///   نشاط متوسط (3-5 أيام/أسبوع):    BMR × 1.55
///   نشاط عالي (6-7 أيام/أسبوع):     BMR × 1.725
///   نشاط مكثف (تمارين شاقة جداً):   BMR × 1.9
class CalorieCalculator {
  // ──────────────────── BMR (Mifflin-St Jeor) ────────────────────
  /// Mifflin-St Jeor (1990) — المعتمدة من mithaly.sa
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

  // ──────────────────── TDEE (Mithaly.sa) ────────────────────
  /// TDEE = BMR × Activity Factor
  /// Activity levels per mithaly.sa:
  ///   sedentary:  1.2   — خامل (بدون تمارين)
  ///   light:      1.375 — نشاط خفيف (1-3 أيام/أسبوع)
  ///   moderate:   1.55  — نشاط متوسط (3-5 أيام/أسبوع)
  ///   active:     1.725 — نشاط عالي (6-7 أيام/أسبوع)
  ///   veryActive: 1.9   — نشاط مكثف (تمارين شاقة جداً)
  static double tdee({required double bmr, required String activityLevel}) {
    const factors = {
      'sedentary':  1.2,    // خامل (بدون تمارين)
      'light':      1.375,  // نشاط خفيف (1-3 أيام/أسبوع)
      'moderate':   1.55,   // نشاط متوسط (3-5 أيام/أسبوع)
      'active':     1.725,  // نشاط عالي (6-7 أيام/أسبوع)
      'veryActive': 1.9,    // نشاط مكثف (تمارين شاقة جداً)
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

  // ──────────────────── Water Goal (Mithaly.sa) ────────────────────
  /// Water intake calculation based on Mithaly.sa formula.
  ///
  /// المعادلة: الوزن (كجم) × 0.033 = احتياج الماء باللتر
  ///
  /// Example: 70 kg × 0.033 = 2.31 liters = 2310 mL
  ///
  /// Result rounded to nearest 50 mL and clamped between 1500-5000 mL.
  static int waterGoalMl({
    required double weightKg,
    required String gender,
    String activityLevel = 'sedentary',
  }) {
    // Mithaly.sa formula: weight × 0.033 liters
    final waterLiters = weightKg * 0.033;
    final waterMl = waterLiters * 1000;

    // Round to nearest 50 mL for cleanliness
    return ((waterMl / 50).round() * 50).clamp(1500, 5000);
  }

  // ──────────────────── BMI (Mithaly.sa) ────────────────────
  /// BMI = weight(kg) / height(m)²
  static double calculateBMI(double weightKg, double heightCm) =>
      weightKg / ((heightCm / 100) * (heightCm / 100));

  /// BMI classification per Mithaly.sa standards (5 categories)
  ///   < 18.5        → نقص في الوزن
  ///   18.5 – 24.9   → وزن طبيعي
  ///   25.0 – 29.9   → زيادة في الوزن
  ///   30.0 – 34.9   → سمنة
  ///   ≥ 35.0        → سمنة مفرطة
  static String bmiCategory(double bmi) {
    if (bmi < 18.5) return 'نقص في الوزن';
    if (bmi < 25.0) return 'وزن طبيعي ✅';
    if (bmi < 30.0) return 'زيادة في الوزن';
    if (bmi < 35.0) return 'سمنة';
    return 'سمنة مفرطة ⚠️';
  }

  // ──────────────────── Ideal Weight (Mithaly.sa) ────────────────────
  /// Ideal weight = 22 × height(m)²
  ///
  /// Mithaly.sa uses target BMI of 22 for both males and females.
  /// Example: height 165 cm → 22 × (1.65)² = 22 × 2.7225 = 59.9 kg
  ///
  /// Clamped between 40-130 kg for safety.
  static double idealWeight({required double heightCm, required int age}) {
    final hMeters = heightCm / 100;
    // Mithaly.sa target BMI = 22
    const targetBmi = 22.0;

    return (targetBmi * hMeters * hMeters).clamp(40.0, 130.0);
  }

  /// Returns the healthy weight range (BMI 18.5–24.9)
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
