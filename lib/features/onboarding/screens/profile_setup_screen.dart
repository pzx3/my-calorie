import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/utils/calorie_calculator.dart';
import '../../../core/utils/validator.dart';
import 'results_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageCtrl = PageController();
  int _page = 0;
  static const _totalPages = 7;

  // Form data
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  String _gender = 'male';
  String _activity = 'sedentary';
  String _goal = 'maintain';
  int _wakeHour = 7;
  int _sleepHour = 22;

  void _next() {
    final error = _validatePage(_page);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: GoogleFonts.cairo(color: Colors.white)),
          backgroundColor: AppColors.coral,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (_page < _totalPages - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      setState(() => _page++);
    } else {
      _finish();
    }
  }

  String? _validatePage(int page) {
    switch (page) {
      case 0:
        return Validator.name(_nameCtrl.text);
      case 1:
        return Validator.age(_ageCtrl.text);
      case 2:
        final hErr = Validator.height(_heightCtrl.text);
        if (hErr != null) return hErr;
        return Validator.weight(_weightCtrl.text);
      default:
        return null;
    }
  }

  void _finish() {
    final weightKg = double.parse(_weightCtrl.text);
    final heightCm = double.parse(_heightCtrl.text);
    final age = int.parse(_ageCtrl.text);

    final bmrVal = CalorieCalculator.bmr(
        weightKg: weightKg, heightCm: heightCm, age: age, gender: _gender);
    final tdeeVal = CalorieCalculator.tdee(bmr: bmrVal, activityLevel: _activity);
    final goalKcal = CalorieCalculator.goalCalories(tdee: tdeeVal, goal: _goal, gender: _gender);
    final waterGoal = CalorieCalculator.waterGoalMl(
        weightKg: weightKg, gender: _gender, activityLevel: _activity);

    final profile = UserProfile(
      name: _nameCtrl.text.trim(),
      age: age,
      gender: _gender,
      heightCm: heightCm,
      weightKg: weightKg,
      activityLevel: _activity,
      goal: _goal,
      tdeeKcal: goalKcal,
      waterGoalMl: waterGoal,
      wakeHour: _wakeHour,
      sleepHour: _sleepHour,
    );
    Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => ResultsScreen(profile: profile, rawTdee: tdeeVal.round()),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: anim.drive(Tween(begin: const Offset(1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic))),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 500),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF13132B), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress bar
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_rounded,
                              color: AppColors.textSecondary),
                          onPressed: () {
                            if (_page > 0) {
                              _pageCtrl.previousPage(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut);
                              setState(() => _page--);
                            } else {
                              Navigator.pop(context);
                            }
                          },
                        ),
                        Text('${_page + 1} / $_totalPages',
                            style: GoogleFonts.cairo(
                                color: AppColors.textSecondary, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_page + 1) / _totalPages,
                        backgroundColor: AppColors.cardBorder,
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.primary),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _NamePage(ctrl: _nameCtrl),
                    _AgePage(
                        ctrl: _ageCtrl,
                        gender: _gender,
                        onGender: (v) => setState(() => _gender = v)),
                    _MeasurePage(
                        heightCtrl: _heightCtrl, weightCtrl: _weightCtrl, ageCtrl: _ageCtrl),
                    _IdealWeightPage(heightCtrl: _heightCtrl, ageCtrl: _ageCtrl),
                    _ActivityPage(
                        selected: _activity,
                        onSelect: (v) => setState(() => _activity = v)),
                    _GoalPage(
                        selected: _goal,
                        onSelect: (v) => setState(() => _goal = v)),
                    _SchedulePage(
                        wakeHour: _wakeHour,
                        sleepHour: _sleepHour,
                        onWakeChanged: (h) => setState(() => _wakeHour = h),
                        onSleepChanged: (h) => setState(() => _sleepHour = h)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    child: Text(_page == _totalPages - 1 ? 'احسب احتياجي ✨' : 'التالي',
                        style: GoogleFonts.cairo(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────── Page widgets ────────────────────────
class _NamePage extends StatelessWidget {
  const _NamePage({required this.ctrl});
  final TextEditingController ctrl;
  @override
  Widget build(BuildContext context) => _SetupPage(
        emoji: '👋',
        title: 'وش اسمك؟',
        subtitle: '',
        child: TextField(
            controller: ctrl,
            textAlign: TextAlign.center,
            style:
                GoogleFonts.cairo(fontSize: 20, color: AppColors.textPrimary),
            decoration: InputDecoration(
                hintText: 'اكتب اسمك هنا',
                hintStyle: GoogleFonts.cairo(color: AppColors.textHint))),
      );
}

class _AgePage extends StatelessWidget {
  const _AgePage(
      {required this.ctrl, required this.gender, required this.onGender});
  final TextEditingController ctrl;
  final String gender;
  final ValueChanged<String> onGender;
  @override
  Widget build(BuildContext context) => _SetupPage(
        emoji: '📋',
        title: 'العمر والجنس',
        subtitle: 'لحساب معدل الأيض الأساسي بدقة',
        child: Column(children: [
          TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.cairo(fontSize: 20, color: AppColors.textPrimary),
              decoration: InputDecoration(
                  hintText: 'عمرك بالسنوات',
                  suffixText: 'سنة',
                  hintStyle: GoogleFonts.cairo(color: AppColors.textHint))),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
                child: _GenderBtn(
                    label: 'ذكر 👨',
                    value: 'male',
                    selected: gender,
                    onTap: onGender)),
            const SizedBox(width: 12),
            Expanded(
                child: _GenderBtn(
                    label: 'أنثى 👩',
                    value: 'female',
                    selected: gender,
                    onTap: onGender)),
          ]),
        ]),
      );
}

class _GenderBtn extends StatelessWidget {
  const _GenderBtn(
      {required this.label,
      required this.value,
      required this.selected,
      required this.onTap});
  final String label, value, selected;
  final ValueChanged<String> onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: selected == value ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: selected == value
                    ? AppColors.primary
                    : AppColors.cardBorder),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ),
      );
}

class _MeasurePage extends StatelessWidget {
  const _MeasurePage({required this.heightCtrl, required this.weightCtrl, required this.ageCtrl});
  final TextEditingController heightCtrl, weightCtrl, ageCtrl;


  @override
  Widget build(BuildContext context) {
    return _SetupPage(
      emoji: '📏',
      title: 'الطول والوزن',
      subtitle: 'بالسنتيمتر والكيلوجرام',
      child: Column(children: [
        TextField(
            controller: heightCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontSize: 20, color: AppColors.textPrimary),
            decoration: InputDecoration(
                hintText: 'طولك',
                suffixText: 'سم',
                hintStyle: GoogleFonts.cairo(color: AppColors.textHint))),
        const SizedBox(height: 16),
        TextField(
            controller: weightCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontSize: 20, color: AppColors.textPrimary),
            decoration: InputDecoration(
                hintText: 'وزنك',
                suffixText: 'كجم',
                hintStyle: GoogleFonts.cairo(color: AppColors.textHint))),
      ]),
    );
  }
}

class _IdealWeightPage extends StatelessWidget {
  const _IdealWeightPage({required this.heightCtrl, required this.ageCtrl});
  final TextEditingController heightCtrl, ageCtrl;

  @override
  Widget build(BuildContext context) {
    final height = double.tryParse(heightCtrl.text) ?? 170;
    final age = int.tryParse(ageCtrl.text) ?? 25;
    final ideal = CalorieCalculator.idealWeight(heightCm: height, age: age);
    final range = CalorieCalculator.healthyWeightRange(heightCm: height);

    return _SetupPage(
      emoji: '⭐',
      title: 'وزنك المثالي',
      subtitle: 'بناءً على طولك وعمرك حسب معايير وزارة الصحة 🇸🇦',
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.star_rounded, color: AppColors.primary, size: 80),
        const SizedBox(height: 24),
        Text(
          '${ideal.toStringAsFixed(1)} كجم',
          style: GoogleFonts.cairo(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'النطاق الصحي: ${range['min']!.toStringAsFixed(0)} - ${range['max']!.toStringAsFixed(0)} كجم',
            style: GoogleFonts.cairo(fontSize: 13, color: AppColors.green, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'الوصول لهذا الوزن يحسن من طاقتك وصحتك العامة',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textSecondary),
        ),
      ]),
    );
  }
}

class _ActivityPage extends StatelessWidget {
  const _ActivityPage({required this.selected, required this.onSelect});
  final String selected;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) => _SetupPage(
        emoji: '🏃',
        title: 'مستوى النشاط',
        subtitle: 'اختر ما يناسب نمط حياتك',
        child: Column(
            children: ActivityLevel.sedentary == selected
                ? _items(onSelect, selected)
                : _items(onSelect, selected)),
      );

  static List<Widget> _items(ValueChanged<String> onSelect, String selected) =>
      [
        _ActivityBtn(
            value: 'sedentary', selected: selected, onSelect: onSelect),
        const SizedBox(height: 10),
        _ActivityBtn(value: 'light', selected: selected, onSelect: onSelect),
        const SizedBox(height: 10),
        _ActivityBtn(value: 'moderate', selected: selected, onSelect: onSelect),
        const SizedBox(height: 10),
        _ActivityBtn(value: 'active', selected: selected, onSelect: onSelect),
      ];
}

class _ActivityBtn extends StatelessWidget {
  const _ActivityBtn(
      {required this.value, required this.selected, required this.onSelect});
  final String value, selected;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 2 : 0.5),
        ),
        child: Row(children: [
          Text(ActivityLevel.emoji(value),
              style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 14),
          Expanded(
              child: Text(ActivityLevel.label(value),
                  style: GoogleFonts.cairo(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500))),
          if (isSelected)
            const Icon(Icons.check_circle_rounded,
                color: AppColors.primary, size: 22),
        ]),
      ),
    );
  }
}

class _GoalPage extends StatelessWidget {
  const _GoalPage({required this.selected, required this.onSelect});
  final String selected;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) => _SetupPage(
        emoji: '🎯',
        title: 'هدفك الصحي',
        subtitle: 'سنحسب سعراتك بناءً على هدفك',
        child: Column(children: [
          _GoalBtn(
              value: 'lose',
              color: AppColors.coral,
              selected: selected,
              onSelect: onSelect),
          const SizedBox(height: 12),
          _GoalBtn(
              value: 'maintain',
              color: AppColors.teal,
              selected: selected,
              onSelect: onSelect),
          const SizedBox(height: 12),
          _GoalBtn(
              value: 'gain',
              color: AppColors.primary,
              selected: selected,
              onSelect: onSelect),
        ]),
      );
}

class _GoalBtn extends StatelessWidget {
  const _GoalBtn(
      {required this.value,
      required this.color,
      required this.selected,
      required this.onSelect});
  final String value, selected;
  final Color color;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: isSelected ? color : AppColors.cardBorder,
              width: isSelected ? 2 : 0.5),
        ),
        child: Row(children: [
          Text(GoalType.emoji(value), style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 16),
          Text(GoalType.label(value),
              style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const Spacer(),
          if (isSelected) Icon(Icons.check_circle_rounded, color: color),
        ]),
      ),
    );
  }
}

class _SetupPage extends StatelessWidget {
  const _SetupPage(
      {required this.emoji,
      required this.title,
      required this.subtitle,
      required this.child});
  final String emoji, title, subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(emoji, style: const TextStyle(fontSize: 56))
                  .animate(key: ValueKey('emoji_$title'))
                  .scale(duration: 400.ms, curve: Curves.elasticOut)
                  .fadeIn(),
              const SizedBox(height: 20),
              Text(title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary))
                  .animate(key: ValueKey('title_$title'))
                  .fadeIn(delay: 100.ms)
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: 8),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                      fontSize: 14, color: AppColors.textSecondary))
                  .animate(key: ValueKey('sub_$title'))
                  .fadeIn(delay: 200.ms),
              const SizedBox(height: 36),
              child.animate(key: ValueKey('child_$title')).fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
}

// ──────────── Schedule Page (Wake / Sleep) ────────────
class _SchedulePage extends StatelessWidget {
  const _SchedulePage({
    required this.wakeHour,
    required this.sleepHour,
    required this.onWakeChanged,
    required this.onSleepChanged,
  });
  final int wakeHour, sleepHour;
  final ValueChanged<int> onWakeChanged, onSleepChanged;

  String _fmt(int h) {
    final p = h >= 12 ? 'مساءً' : 'صباحاً';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:00 $p';
  }

  @override
  Widget build(BuildContext context) => _SetupPage(
    emoji: '⏰',
    title: 'مواعيدك اليومية',
    subtitle: 'لتوزيع شرب الماء بذكاء على مدار يومك',
    child: Column(children: [
      Row(children: [
        Expanded(child: _TimeCard(
          label: 'وقت الاستيقاظ',
          emoji: '🌅',
          hour: wakeHour,
          context: context,
          onChanged: onWakeChanged,
        )),
        const SizedBox(width: 16),
        Expanded(child: _TimeCard(
          label: 'وقت النوم',
          emoji: '🌙',
          hour: sleepHour,
          context: context,
          onChanged: onSleepChanged,
        )),
      ]),
      const SizedBox(height: 24),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.water.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.water.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.water, size: 20),
          const SizedBox(height: 8),
          Text(
            'سيقوم النظام بتقسيم شرب الماء تلقائياً\nمن 30 دقيقة بعد ${_fmt(wakeHour)} حتى 30 دقيقة قبل ${_fmt(sleepHour)}',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary, height: 1.6),
          ),
        ]),
      ),
    ]),
  );
}

class _TimeCard extends StatelessWidget {
  const _TimeCard({
    required this.label,
    required this.emoji,
    required this.hour,
    required this.context,
    required this.onChanged,
  });
  final String label, emoji;
  final int hour;
  final BuildContext context;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext ctx) {
    final p = hour >= 12 ? 'م' : 'ص';
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: 0),
          builder: (c, child) => Theme(
            data: Theme.of(c).copyWith(
              colorScheme: const ColorScheme.dark(primary: AppColors.water, surface: AppColors.surface),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked.hour);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text('$h12:00 $p', style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ]),
      ),
    );
  }
}
