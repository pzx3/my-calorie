import 'weight_entry.dart';
import '../utils/calorie_calculator.dart';

class ActivityLevel {
  static const String sedentary  = 'sedentary';
  static const String light      = 'light';
  static const String moderate   = 'moderate';
  static const String active     = 'active';
  static const String veryActive = 'veryActive';

  /// All activity level keys (for UI iteration)
  static const List<String> all = [sedentary, light, moderate, active, veryActive];

  /// Activity level labels per Mithaly.sa
  static String label(String v) => const {
    'sedentary':  'خامل (بدون تمارين)',
    'light':      'نشاط خفيف (1-3 أيام/أسبوع)',
    'moderate':   'نشاط متوسط (3-5 أيام/أسبوع)',
    'active':     'نشاط عالي (6-7 أيام/أسبوع)',
    'veryActive': 'نشاط مكثف (تمارين شاقة جداً)',
  }[v] ?? 'خامل';

  static double multiplier(String v) => const {
    'sedentary':  1.2,
    'light':      1.375,
    'moderate':   1.55,
    'active':     1.725,
    'veryActive': 1.9,
  }[v] ?? 1.2;

  static String emoji(String v) => const {
    'sedentary':  '🛋️',
    'light':      '🚶',
    'moderate':   '🏃',
    'active':     '💪',
    'veryActive': '🔥',
  }[v] ?? '🛋️';
}

class GoalType {
  static const String lose     = 'lose';
  static const String maintain = 'maintain';
  static const String gain     = 'gain';

  static String label(String v, String gender) {
    final isFemale = gender == 'female';
    return {
      'lose':     'إنقاص الوزن',
      'maintain': 'الحفاظ على الوزن',
      'gain':     isFemale ? 'زيادة الوزن وشد الجسم' : 'زيادة الوزن وبناء العضلات',
    }[v] ?? 'الحفاظ على الوزن';
  }

  static int adjustment(String v) =>
      const {'lose': -500, 'maintain': 0, 'gain': 300}[v] ?? 0;

  static String emoji(String v) =>
      const {'lose': '🔥', 'maintain': '⚖️', 'gain': '💪'}[v] ?? '⚖️';
}

class UserProfile {
  final String name;
  final int    age;
  final String gender;
  final double heightCm;
  final double weightKg;
  final String activityLevel;
  final String goal;
  final int    tdeeKcal;
  final int    waterGoalMl;
  final int    wakeHour;
  final int    sleepHour;
  final List<int> quickAddMl;
  final List<int> quickAddOz;
  final int? preferredCupMl; // User's preferred cup size in ml
  final bool   waterSetupComplete;
  final List<WeightEntry> weightHistory;
  final DateTime? lastWeightUpdate;

  const UserProfile({
    required this.name,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    required this.goal,
    required this.tdeeKcal,
    required this.waterGoalMl,
    this.wakeHour = 7,
    this.sleepHour = 22,
    this.quickAddMl = const [150, 250, 350, 500],
    this.quickAddOz = const [5, 8, 12, 16],
    this.preferredCupMl,
    this.waterSetupComplete = false,
    this.weightHistory = const [],
    this.lastWeightUpdate,
  });

  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  /// Mithaly.sa BMI classification (5 categories)
  String get bmiCategory => CalorieCalculator.bmiCategory(bmi);

  int get awakeMinutes {
    final raw = sleepHour > wakeHour
        ? (sleepHour - wakeHour) * 60
        : ((24 - wakeHour) + sleepHour) * 60;
    // 30 mins after waking + 30 mins before sleep = 60 mins total deduction
    return (raw - 60).clamp(60, raw);
  }

  int get waterIntervals {
    if (preferredCupMl != null && preferredCupMl! > 0) {
      return (waterGoalMl / preferredCupMl!).ceil().clamp(2, 20);
    }
    
    final awake = awakeMinutes;
    if (awake <= 0) return 4;

    int doses = (awake / 75).round().clamp(4, 16);
    int perCup = (waterGoalMl / doses).round();

    while (perCup > 400 && doses < 16) {
      doses++;
      perCup = (waterGoalMl / doses).round();
    }
    while (perCup < 150 && doses > 4) {
      doses--;
      perCup = (waterGoalMl / doses).round();
    }
    return doses;
  }

  int get perDrinkMl {
    if (preferredCupMl != null && preferredCupMl! > 0) {
      return preferredCupMl!;
    }
    return (waterGoalMl / waterIntervals).round();
  }

  List<Map<String, dynamic>> get waterSchedule {
    final doses = waterIntervals;
    final perDrink = perDrinkMl;
    final awake = awakeMinutes;
    final gap = awake / (doses - 1).clamp(1, 100);

    final schedule = <Map<String, dynamic>>[];
    for (int i = 0; i < doses; i++) {
      // Start 30 minutes after waking up
      final totalMin = (wakeHour * 60) + 30 + (gap * i).round();
      final h = (totalMin ~/ 60) % 24;
      final m = totalMin % 60;
      final period = h >= 12 ? 'م' : 'ص';
      final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);

      String label;
      if (i == 0) {
        label = 'كوب الصباح 🌅';
      } else if (i == doses - 1) {
        label = 'كوب قبل النوم 🌙';
      } else {
        label = 'كوب رقم ${i + 1}';
      }

      schedule.add({
        'time': '${hour12.toString().padLeft(2)}:${m.toString().padLeft(2, '0')} $period',
        'ml': perDrink,
        'label': label,
        'hour': h,
        'minute': m,
      });
    }
    return schedule;
  }

  UserProfile copyWith({
    String? name,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    String? activityLevel,
    String? goal,
    int? tdeeKcal,
    int? waterGoalMl,
    int? wakeHour,
    int? sleepHour,
    List<int>? quickAddMl,
    List<int>? quickAddOz,
    int? preferredCupMl,
    bool? waterSetupComplete,
    List<WeightEntry>? weightHistory,
    DateTime? lastWeightUpdate,
    bool clearPreferredCup = false,
  }) =>
      UserProfile(
        name: name ?? this.name,
        age: age ?? this.age,
        gender: gender ?? this.gender,
        heightCm: heightCm ?? this.heightCm,
        weightKg: weightKg ?? this.weightKg,
        activityLevel: activityLevel ?? this.activityLevel,
        goal: goal ?? this.goal,
        tdeeKcal: tdeeKcal ?? this.tdeeKcal,
        waterGoalMl: waterGoalMl ?? this.waterGoalMl,
        wakeHour: wakeHour ?? this.wakeHour,
        sleepHour: sleepHour ?? this.sleepHour,
        quickAddMl: quickAddMl ?? this.quickAddMl,
        quickAddOz: quickAddOz ?? this.quickAddOz,
        preferredCupMl: clearPreferredCup ? null : (preferredCupMl ?? this.preferredCupMl),
        waterSetupComplete: waterSetupComplete ?? this.waterSetupComplete,
        weightHistory: weightHistory ?? this.weightHistory,
        lastWeightUpdate: lastWeightUpdate ?? this.lastWeightUpdate,
      );

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name']?.toString() ?? '',
        age: (json['age'] as num?)?.toInt() ?? 0,
        gender: json['gender']?.toString() ?? 'male',
        heightCm: (json['heightCm'] as num?)?.toDouble() ?? 0.0,
        weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
        activityLevel: json['activityLevel']?.toString() ?? 'sedentary',
        goal: json['goal']?.toString() ?? 'maintain',
        tdeeKcal: (json['tdeeKcal'] as num?)?.toInt() ?? 0,
        waterGoalMl: (json['waterGoalMl'] as num?)?.toInt() ?? 0,
        wakeHour: (json['wakeHour'] as num?)?.toInt() ?? 7,
        sleepHour: (json['sleepHour'] as num?)?.toInt() ?? 22,
        quickAddMl: (json['quickAddMl'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [150, 250, 350, 500],
        quickAddOz: (json['quickAddOz'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [5, 8, 12, 16],
        preferredCupMl: (json['preferredCupMl'] as num?)?.toInt(),
        waterSetupComplete: json['waterSetupComplete'] as bool? ?? false,
        weightHistory: (json['weightHistory'] as List?)
                ?.map((e) => WeightEntry.fromJson(e))
                .toList() ??
            const [],
        lastWeightUpdate: json['lastWeightUpdate'] != null
            ? DateTime.parse(json['lastWeightUpdate'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'gender': gender,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'activityLevel': activityLevel,
        'goal': goal,
        'tdeeKcal': tdeeKcal,
        'waterGoalMl': waterGoalMl,
        'wakeHour': wakeHour,
        'sleepHour': sleepHour,
        'quickAddMl': quickAddMl,
        'quickAddOz': quickAddOz,
        'preferredCupMl': preferredCupMl,
        'waterSetupComplete': waterSetupComplete,
        'weightHistory': weightHistory.map((e) => e.toJson()).toList(),
        'lastWeightUpdate': lastWeightUpdate?.toIso8601String(),
      };
}
