import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/food_entry.dart';
import '../models/water_entry.dart';
import '../models/weight_entry.dart';
import '../utils/calorie_calculator.dart';
import '../services/notification_service.dart';

class AppState extends ChangeNotifier {
  final SharedPreferences _prefs;

  AppState(this._prefs) {
    _loadAll();
    refreshDay(); // فحص تغير اليوم عند بدء التطبيق
    if (_profile != null) {
      NotificationService().scheduleCalorieReminders(_profile);
    }
  }

  // ──────────────────────────── Daily Reset ────────────────────────────

  /// يُستدعى عند بدء التطبيق أو العودة إليه
  void refreshDay() {
    final today = _todayStr();
    final lastDay = _prefs.getString('last_active_day');

    if (lastDay != null && lastDay != today) {
      // يوم جديد → تصفير السجلات
      _foodEntries.clear();
      _waterEntries.clear();
      _saveFood();
      _saveWater();
    }

    _prefs.setString('last_active_day', today);
    notifyListeners();
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ──────────────────────────── State ────────────────────────────
  UserProfile? _profile;
  List<FoodEntry>  _foodEntries  = [];
  List<WaterEntry> _waterEntries = [];
  int _currentTab = 0;

  // ──────────────────────────── Getters ────────────────────────────
  UserProfile? get profile             => _profile;
  bool         get isOnboardingComplete => _profile != null && _profile!.name.isNotEmpty;
  bool get shouldPromptWeight {
    if (_profile == null) return false;
    if (_profile!.lastWeightUpdate == null) return true;
    final diff = DateTime.now().difference(_profile!.lastWeightUpdate!).inDays;
    return diff >= 7;
  }
  int          get currentTab          => _currentTab;

  List<FoodEntry>  get todayFood  => _todayEntries(_foodEntries,  (e) => e.dateTime);
  List<WaterEntry> get todayWater => _todayWaterEntries();

  int get totalCaloriesToday =>
      todayFood.fold(0, (s, e) => s + e.calories.round());
  int get remainingCalories =>
      (_profile?.tdeeKcal ?? 2000) - totalCaloriesToday;
  int get totalWaterToday =>
      todayWater.fold(0, (s, e) => s + e.amountMl);

  double get proteinToday => todayFood.fold(0.0, (s, e) => s + e.protein);
  double get carbsToday   => todayFood.fold(0.0, (s, e) => s + e.carbs);
  double get fatToday     => todayFood.fold(0.0, (s, e) => s + e.fat);

  bool get canCelebrateCalories => false;
  void markCalorieCelebrated() {}

  bool get canCelebrateWater => false;
  void markWaterCelebrated() {}

  List<FoodEntry> entriesForMeal(String mealType) =>
      todayFood.where((e) => e.mealType == mealType).toList();

  int caloriesForDate(DateTime date) => entriesForDate(date).fold(0, (s, e) => s + e.calories.round());
  List<FoodEntry> entriesForDate(DateTime date) => _foodEntries
      .where((e) => e.dateTime.year == date.year && e.dateTime.month == date.month && e.dateTime.day == date.day)
      .toList();

  // ──────────────────────────── Helpers ────────────────────────────
  List<FoodEntry> _todayEntries(List<FoodEntry> all, DateTime Function(FoodEntry) dt) {
    final now = DateTime.now();
    return all.where((e) {
      final d = dt(e);
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
  }

  List<WaterEntry> _todayWaterEntries() {
    final now = DateTime.now();
    return _waterEntries.where((e) =>
      e.dateTime.year == now.year &&
      e.dateTime.month == now.month &&
      e.dateTime.day == now.day).toList();
  }

  // ──────────────────────────── Load ────────────────────────────
  void _loadAll() {
    // Profile
    try {
      final pJson = _prefs.getString('user_profile');
      if (pJson != null) {
        _profile = UserProfile.fromJson(jsonDecode(pJson) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
    // Food
    try {
      final fJson = _prefs.getString('all_food_entries');
      if (fJson != null) {
        final list = jsonDecode(fJson) as List;
        _foodEntries = list.map((e) => FoodEntry.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error loading food entries: $e');
    }
    // Water
    try {
      final wJson = _prefs.getString('all_water_entries');
      if (wJson != null) {
        final list = jsonDecode(wJson) as List;
        _waterEntries = list.map((e) => WaterEntry.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error loading water entries: $e');
    }
    notifyListeners();
  }

  // ──────────────────────────── Save ────────────────────────────
  Future<void> _saveProfile() async {
    await _prefs.setString('user_profile', jsonEncode(_profile!.toJson()));
  }

  Future<void> _saveFood() async {
    await _prefs.setString('all_food_entries', jsonEncode(_foodEntries.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveWater() async {
    await _prefs.setString('all_water_entries', jsonEncode(_waterEntries.map((e) => e.toJson()).toList()));
  }

  // ──────────────────────────── Actions ────────────────────────────
  Future<void> saveProfile(UserProfile p) async {
    _profile = p;
    await _saveProfile();
    // Schedule all reminders
    final notif = NotificationService();
    await notif.scheduleCalorieReminders(p);
    if (p.waterSetupComplete) {
      await notif.scheduleWaterReminders(p);
    }
    notifyListeners();
  }

  Future<void> updateWeight(double newWeight) async {
    if (_profile == null) return;
    final entry = WeightEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      weightKg: newWeight,
      date: DateTime.now(),
    );
    final history = List<WeightEntry>.from(_profile!.weightHistory)..add(entry);
    
    // Recalculate metrics based on new weight
    // If losing weight, we use a blend of current and ideal weight for BMR to target the ideal weight
    double weightToCalculateWith = newWeight;
    if (_profile!.goal == 'lose') {
      final ideal = CalorieCalculator.idealWeight(heightCm: _profile!.heightCm, age: _profile!.age);
      // If overweight, eating for the ideal weight helps reach it
      if (newWeight > ideal) {
        weightToCalculateWith = ideal;
      }
    }

    final bmr = CalorieCalculator.bmr(
      weightKg: weightToCalculateWith,
      heightCm: _profile!.heightCm,
      age: _profile!.age,
      gender: _profile!.gender,
    );
    final tdeeVal = CalorieCalculator.tdee(bmr: bmr, activityLevel: _profile!.activityLevel);
    final newGoalKcal = CalorieCalculator.goalCalories(tdee: tdeeVal, goal: _profile!.goal, gender: _profile!.gender);
    final newWaterGoal = CalorieCalculator.waterGoalMl(weightKg: newWeight, gender: _profile!.gender, activityLevel: _profile!.activityLevel);

    _profile = _profile!.copyWith(
      weightKg: newWeight,
      tdeeKcal: newGoalKcal,
      waterGoalMl: newWaterGoal,
      weightHistory: history,
      lastWeightUpdate: DateTime.now(),
    );
    await _saveProfile();
    // Sync notifications with new goals
    await NotificationService().scheduleWaterReminders(_profile!);
    notifyListeners();
  }

  Future<void> addFoodEntry(FoodEntry entry) async {
    _foodEntries.add(entry);
    await _saveFood();
    notifyListeners();
  }

  Future<void> updateFoodEntry(FoodEntry entry) async {
    final idx = _foodEntries.indexWhere((e) => e.id == entry.id);
    if (idx != -1) {
      _foodEntries[idx] = entry;
      await _saveFood();
      notifyListeners();
    }
  }

  Future<void> removeFoodEntry(String id) async {
    _foodEntries.removeWhere((e) => e.id == id);
    await _saveFood();
    notifyListeners();
  }

  Future<void> addWater(int ml) async {
    _waterEntries.add(WaterEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amountMl: ml,
      dateTime: DateTime.now(),
    ));
    await _saveWater();
    notifyListeners();
  }

  Future<void> removeWaterEntry(String id) async {
    _waterEntries.removeWhere((e) => e.id == id);
    await _saveWater();
    notifyListeners();
  }

  void setTab(int index) {
    _currentTab = index;
    notifyListeners();
  }

  Future<void> resetOnboarding() async {
    await _prefs.remove('user_profile');
    await _prefs.remove('all_food_entries');
    await _prefs.remove('all_water_entries');
    await NotificationService().cancelAll();
    _profile = null;
    _foodEntries = [];
    _waterEntries = [];
    _currentTab = 0;
    notifyListeners();
  }


  Future<void> updateWaterGoal(int newGoalMl) async {
    if (_profile != null) {
      _profile = _profile!.copyWith(waterGoalMl: newGoalMl);
      await _saveProfile();
      notifyListeners();
    }
  }

  Future<void> updateWaterSchedule({
    int? wakeHour,
    int? sleepHour,
    int? goalMl,
    List<int>? quickAddMl,
    List<int>? quickAddOz,
    int? preferredCupMl,
    bool clearPreferredCup = false,
  }) async {
    if (_profile != null) {
      _profile = _profile!.copyWith(
        wakeHour: wakeHour,
        sleepHour: sleepHour,
        waterGoalMl: goalMl,
        quickAddMl: quickAddMl,
        quickAddOz: quickAddOz,
        preferredCupMl: preferredCupMl,
        waterSetupComplete: true,
        clearPreferredCup: clearPreferredCup,
      );
      await _saveProfile();
      await NotificationService().scheduleWaterReminders(_profile!);
      notifyListeners();
    }
  }

  Future<void> updateQuickAddAmounts({required List<int> ml, required List<int> oz}) async {
    if (_profile != null) {
      _profile = _profile!.copyWith(quickAddMl: ml, quickAddOz: oz);
      await _saveProfile();
      notifyListeners();
    }
  }
}
