import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/app_notifications.dart';
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

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _page = 0;
  static const _totalPages = 6;

  // Form data
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  String _gender = '';
  String _activity = 'sedentary';
  String _goal = 'maintain';
  int _wakeHour = 7;
  int _sleepHour = 22;

  double? get _bmi {
    final w = double.tryParse(_weightCtrl.text);
    final h = double.tryParse(_heightCtrl.text);
    if (w == null || h == null || h == 0) return null;
    return w / ((h / 100) * (h / 100));
  }

  void _next() {
    FocusScope.of(context).unfocus(); // Hide keyboard
    final error = _validatePage(_page);
    if (error != null) {
      AppNotifications.showTop(context, error);
      return;
    }

    if (_page < _totalPages - 1) {
      // Smart Auto-Goal Selection (Best for User)
      if (_page == 2) {
        final bmi = _bmi;
        if (bmi != null) {
          if (bmi < 18.5) {
            _goal = 'gain';
          } else if (bmi >= 25.0) {
            _goal = 'lose';
          } else {
            _goal = 'maintain';
          }
        }
      }

      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
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
        final ageErr = Validator.age(_ageCtrl.text);
        if (ageErr != null) return ageErr;
        if (_gender.isEmpty) return 'يرجى اختيار الجنس';
        return null;
      case 2:
        final hErr = Validator.height(_heightCtrl.text);
        if (hErr != null) return hErr;
        return Validator.weight(_weightCtrl.text);
      case 4:
        return null;
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
    final isLastPage = _page == _totalPages - 1;
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            if (_page > 0) {
                              _pageCtrl.previousPage(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOutCubic);
                              setState(() => _page--);
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.cardBorder, width: 0.5),
                            ),
                            child: const Icon(Icons.arrow_back_ios_rounded,
                                color: AppColors.textSecondary, size: 18),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${_page + 1} / $_totalPages',
                              style: GoogleFonts.cairo(
                                  color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: (_page + 1) / _totalPages),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (_, value, __) => ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: value,
                          backgroundColor: AppColors.cardBorder,
                          valueColor:
                              const AlwaysStoppedAnimation(AppColors.primary),
                          minHeight: 5,
                        ),
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
                    _ActivityPage(
                        selected: _activity,
                        onSelect: (v) => setState(() => _activity = v)),
                    _GoalPage(selected: _goal, bmi: _bmi, gender: _gender, onSelect: (v) => setState(() => _goal = v)),
                    _SchedulePage(
                        wakeHour: _wakeHour,
                        sleepHour: _sleepHour,
                        onWakeChanged: (h) => setState(() => _wakeHour = h),
                        onSleepChanged: (h) => setState(() => _sleepHour = h)),
                  ],
                ),
              ),
              // ── Next / Finish Button ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: isLastPage
                          ? const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark])
                          : const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          isLastPage ? 'احسب احتياجي ✨' : 'التالي',
                          key: ValueKey(isLastPage),
                          style: GoogleFonts.cairo(
                              fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
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
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s\u0600-\u06FF]')),
            ],
            style:
                GoogleFonts.cairo(fontSize: 18, color: AppColors.textPrimary),
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
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.cairo(fontSize: 18, color: AppColors.textPrimary),
              decoration: InputDecoration(
                  hintText: 'عمرك',
                  suffixText: 'سنة',
                  hintStyle: GoogleFonts.cairo(color: AppColors.textHint))),
          const SizedBox(height: 16),
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected == value ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected == value
                    ? AppColors.primary
                    : AppColors.cardBorder),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                  fontSize: 14,
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
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontSize: 18, color: AppColors.textPrimary),
            decoration: InputDecoration(
                hintText: 'طولك',
                suffixText: 'سم',
                hintStyle: GoogleFonts.cairo(color: AppColors.textHint))),
        const SizedBox(height: 14),
        TextField(
            controller: weightCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontSize: 18, color: AppColors.textPrimary),
            decoration: InputDecoration(
                hintText: 'وزنك',
                suffixText: 'كجم',
                hintStyle: GoogleFonts.cairo(color: AppColors.textHint))),
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

  static List<Widget> _items(ValueChanged<String> onSelect, String selected) {
    final items = <Widget>[];
    for (final level in ActivityLevel.all) {
      if (items.isNotEmpty) items.add(const SizedBox(height: 8));
      items.add(_ActivityBtn(value: level, selected: selected, onSelect: onSelect));
    }
    return items;
  }
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 1.5 : 0.5),
        ),
        child: Row(children: [
          Text(ActivityLevel.emoji(value),
              style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(ActivityLevel.label(value),
                  style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500))),
          if (isSelected)
            const Icon(Icons.check_circle_rounded,
                color: AppColors.primary, size: 18),
        ]),
      ),
    );
  }
}

class _GoalPage extends StatelessWidget {
  const _GoalPage({required this.selected, required this.bmi, required this.gender, required this.onSelect});
  final String selected, gender;
  final double? bmi;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) {
    final isFemale = gender == 'female';
    final isUnderweight = bmi != null && bmi! < 18.5;
    final showWarning = selected == 'lose' && isUnderweight;
    final showTip = selected == 'maintain' && isUnderweight;

    String? recommended;
    if (bmi != null) {
      if (bmi! < 18.5) recommended = 'gain';
      else if (bmi! >= 25.0) recommended = 'lose';
      else recommended = 'maintain';
    }
    final isSmartSelected = selected == recommended;

    return _SetupPage(
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
        if (showWarning) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.coral.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.coral.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.coral, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('تنبيه صحي ⚠️', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.coral, fontSize: 14)),
                  Text(
                    'وزنك الحالي (${bmi!.toStringAsFixed(1)}) تحت المعدل الطبيعي. لا ننصح بإنقاص الوزن حالياً لسلامتك.',
                    style: GoogleFonts.cairo(color: AppColors.textPrimary, fontSize: 12, height: 1.4),
                  ),
                ]),
              ),
            ]),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
        ],
        if (showTip) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.teal, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isFemale 
                    ? 'على الرغم من أنكِ تحت المعدل الطبيعي، إلا أن الحفاظ على وزنك الحالي خيار متاح إذا كنتِ مرتاحةً معه.'
                    : 'على الرغم من أنك تحت المعدل الطبيعي، إلا أن الحفاظ على وزنك الحالي خيار متاح إذا كنت مرتاحاً معه.',
                  style: GoogleFonts.cairo(color: AppColors.textPrimary, fontSize: 12, height: 1.5),
                ),
              ),
            ]),
          ).animate().fadeIn(duration: 600.ms),
        ],
        if (isSmartSelected && !showWarning) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'هذا هو الخيار الذكي والأفضل لحالتك الصحية بناءً على مؤشر كتلة جسمك الحالي.',
                  style: GoogleFonts.cairo(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ]),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ]),
    );
  }
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? color : AppColors.cardBorder,
              width: isSelected ? 1.5 : 0.5),
        ),
        child: Row(children: [
          Text(GoalType.emoji(value), style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Text(GoalType.label(value),
              style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const Spacer(),
          if (isSelected) Icon(Icons.check_circle_rounded, color: color, size: 20),
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
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              Text(emoji, style: const TextStyle(fontSize: 42))
                  .animate(key: ValueKey('emoji_$title'))
                  .scale(duration: 400.ms, curve: Curves.elasticOut)
                  .fadeIn(),
              const SizedBox(height: 14),
              Text(title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary))
                  .animate(key: ValueKey('title_$title'))
                  .fadeIn(delay: 100.ms)
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: 6),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                      fontSize: 12, color: AppColors.textSecondary))
                  .animate(key: ValueKey('sub_$title'))
                  .fadeIn(delay: 200.ms),
              const SizedBox(height: 24),
              child.animate(key: ValueKey('child_$title')).fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 16),
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 3),
          Text('$h12:00 $p', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ]),
      ),
    );
  }
}
