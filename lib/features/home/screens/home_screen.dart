import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/state/app_state.dart';
import '../../../core/models/food_entry.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../food_log/screens/food_log_screen.dart';
import '../../profile/screens/weight_history_screen.dart';
import '../../../core/utils/calorie_calculator.dart';
import '../../../shared/widgets/macro_row.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AppState>(
        builder: (context, state, _) {
          final profile = state.profile;
          final goal = profile?.tdeeKcal ?? 2000;
          final eaten = state.totalCaloriesToday;
          final remaining = (goal - eaten).clamp(0, goal);
          final percent = (eaten / goal).clamp(0.0, 1.0);
          final waterGoal = profile?.waterGoalMl ?? 2000;
          final water = state.totalWaterToday;
          final waterPct = (water / waterGoal).clamp(0.0, 1.0);

          return CustomScrollView(
            slivers: [
              // ── App Bar ──
              SliverAppBar(
                expandedHeight: 100,
                pinned: true,
                backgroundColor: AppColors.background,
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 52, 18, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  const AppLogo(size: 18, showShadow: false),
                                  const SizedBox(width: 6),
                                  Text('مرحباً، ${profile?.name ?? (profile?.gender == 'female' ? 'صديقتي' : 'صديقي')} 👋',
                                      style: GoogleFonts.cairo(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary)),
                                ],
                              ),
                              Text(_todayDate(),
                                  style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      color: AppColors.textSecondary)),
                            ]),
                        Row(
                          children: [
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppColors.cardBorder, width: 0.5)),
                                child: const Icon(Icons.notifications_rounded,
                                  color: AppColors.textSecondary, size: 18),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    // ── Weight Reminder Banner ──
                    if (state.shouldPromptWeight) ...[
                      _WeightReminderBanner(
                        profile: state.profile,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeightHistoryScreen())),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // ── Calorie Ring Card ──
                    _CalorieCard(
                        eaten: eaten,
                        goal: goal,
                        remaining: remaining,
                        percent: percent,
                        state: state),
                    const SizedBox(height: 16),
                    // ── Macros Row ──
                    Builder(builder: (context) {
                      final profileGoal = state.profile?.goal ?? 'maintain';
                      final macroGoals = CalorieCalculator.macroGoals(kcal: goal, goal: profileGoal);
                      return MacroRow(
                        protein: state.proteinToday.round(),
                        carbs: state.carbsToday.round(),
                        fat: state.fatToday.round(),
                        pGoal: macroGoals['protein']!.round(),
                        cGoal: macroGoals['carbs']!.round(),
                        fGoal: macroGoals['fat']!.round(),
                      );
                    }),
                    const SizedBox(height: 16),
                    // ── Water Quick ──
                    if (state.profile?.waterSetupComplete == true)
                      _WaterQuickCard(
                          water: water,
                          waterGoal: waterGoal,
                          waterPct: waterPct,
                          state: state)
                    else
                      _WaterSetupPrompt(),
                    const SizedBox(height: 24),
                    // ── Meals ──
                    ...MealType.all
                        .map((m) => _MealSection(mealType: m, state: state)),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 600.ms).moveY(begin: 20, end: 0, curve: Curves.easeOutQuad);
        },
      ),
    );
  }

  String _todayDate() {
    const days = [
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد'
    ];
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    final now = DateTime.now();
    return '${days[now.weekday - 1]}، ${now.day} ${months[now.month - 1]}';
  }
}

class _CalorieCard extends StatefulWidget {
  const _CalorieCard(
      {required this.eaten,
      required this.goal,
      required this.remaining,
      required this.percent,
      required this.state});
  final int eaten, goal, remaining;
  final double percent;
  final AppState state;

  @override
  State<_CalorieCard> createState() => _CalorieCardState();
}

class _CalorieCardState extends State<_CalorieCard> {
  @override
  Widget build(BuildContext context) {
    final reachedGoal = widget.eaten >= widget.goal;
    final overEaten = widget.eaten > widget.goal;
    final ringColor = reachedGoal ? AppColors.coral : AppColors.primary;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6)),
            ],
            border: Border.all(
                color: reachedGoal ? AppColors.coral.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05), width: 1),
          ),
          child: Column(children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                    scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                        CurvedAnimation(
                            parent: anim, curve: Curves.bounceOut)),
                    child: child),
              ),
              child: widget.eaten > widget.goal
                  ? Padding(
                      key: const ValueKey('cal_over_v2'),
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('تجاوزت هدفك ⚠️',
                          style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.coral)))
                  : widget.eaten >= widget.goal
                      ? Padding(
                          key: const ValueKey('cal_done_v2'),
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(widget.state.profile?.gender == 'female' ? 'قفلتِ سعراتك 🔥' : 'قفلت سعراتك 🔥',
                              style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.coral)))
                      : const SizedBox.shrink(key: ValueKey('cal_not_done_v2')),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CalorieIcon(size: 15),
                const SizedBox(width: 5),
                Text('السعرات الحرارية',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              CircularPercentIndicator(
                radius: 60,
                lineWidth: 8,
                percent: widget.percent,
                animation: true,
                animationDuration: 800,
                center: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${widget.remaining}',
                      style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: reachedGoal
                              ? AppColors.coral
                              : AppColors.textPrimary)),
                  Text(overEaten ? 'تجاوزت' : 'متبقي',
                      style: GoogleFonts.cairo(
                          fontSize: 9, color: AppColors.textSecondary)),
                ]),
                progressColor: ringColor,
                backgroundColor: AppColors.cardBorder,
                circularStrokeCap: CircularStrokeCap.round,
              ),
              const SizedBox(width: 24),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _CalorieStat(
                    label: 'الهدف', value: '${widget.goal}', color: AppColors.teal),
                const SizedBox(height: 12),
                _CalorieStat(
                    label: 'مُتناول',
                    value: '${widget.eaten}',
                    color: AppColors.primary),
                const SizedBox(height: 12),
                const _CalorieStat(
                    label: 'محروق', value: '0', color: AppColors.coral),
              ]),
            ]),
          ]),
        ),
      ],
    ).animate(target: reachedGoal ? 1 : 0).shimmer(duration: 2.seconds, color: Colors.white12).boxShadow(
      begin: const BoxShadow(color: Colors.transparent, blurRadius: 0),
      end: BoxShadow(color: AppColors.coral.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2),
    );
  }
}


class _CalorieStat extends StatelessWidget {
  const _CalorieStat(
      {required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: GoogleFonts.cairo(
                fontSize: 10, color: AppColors.textSecondary)),
        Text(value,
            style: GoogleFonts.cairo(
                fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ]);
}

class _WaterQuickCard extends StatefulWidget {
  const _WaterQuickCard(
      {required this.water,
      required this.waterGoal,
      required this.waterPct,
      required this.state});
  final int water, waterGoal;
  final double waterPct;
  final AppState state;

  @override
  State<_WaterQuickCard> createState() => _WaterQuickCardState();
}

class _WaterQuickCardState extends State<_WaterQuickCard> {
  bool _isOz = false;

  int _ozToMl(int oz) => (oz * 29.5735).round();
  String _mlToOzStr(int ml) => (ml / 29.5735).toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final reachedGoal = widget.waterPct >= 1.0;
    final profile = widget.state.profile;
    final goalUnit = _isOz ? 'oz' : 'لتر';
    final currentUnit = _isOz ? 'oz' : 'مل';
    
    // Display values
    final displayCurrent = _isOz ? _mlToOzStr(widget.water) : '${widget.water}';
    final displayGoal = _isOz ? _mlToOzStr(widget.waterGoal) : (widget.waterGoal / 1000).toStringAsFixed(1);

    // Buttons based on unit
    final amounts = _isOz 
        ? (profile?.quickAddOz ?? [5, 8, 12, 16])
        : (profile?.quickAddMl ?? [150, 250, 350, 500]);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: reachedGoal ? AppColors.water.withValues(alpha: 0.3) : AppColors.cardBorder,
                width: 0.5),
          ),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                const WaterIcon(size: 20),
                const SizedBox(width: 8),
                Text('الماء اليومي',
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
              ]),
              Row(children: [
                Text('$displayCurrent $currentUnit / $displayGoal $goalUnit',
                    style: GoogleFonts.cairo(fontSize: 12, color: AppColors.water)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _isOz = !_isOz),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.water.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(_isOz ? 'oz' : 'ml', 
                      style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.water)),
                  ),
                ),
              ]),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                  value: widget.waterPct,
                  backgroundColor: AppColors.cardBorder,
                  valueColor: const AlwaysStoppedAnimation(AppColors.water),
                  minHeight: 8),
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.bounceOut)), child: child),
              ),
              child: (widget.waterPct >= 1.0)
                  ? Padding(
                      key: const ValueKey('water_done_v2'),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(profile?.gender == 'female' ? 'قفلتِ احتياجك من الماء 💧' : 'قفلت احتياجك من الماء 💧',
                          style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)))
                  : const SizedBox.shrink(key: ValueKey('water_not_done_v2')),
            ),
            if (widget.waterPct < 1.0)
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                for (final amt in amounts.take(4))
                  _QuickAddBtn(
                    amount: amt, 
                    unit: currentUnit,
                    onTap: () => widget.state.addWater(_isOz ? _ozToMl(amt) : amt)
                  ),
              ]),
          ]),
        ),
      ],
    ).animate(target: reachedGoal ? 1 : 0).boxShadow(
      begin: const BoxShadow(color: Colors.transparent, blurRadius: 0),
      end: BoxShadow(color: AppColors.water.withValues(alpha: 0.15), blurRadius: 15, spreadRadius: 1),
    );
  }
}

class _QuickAddBtn extends StatelessWidget {
  const _QuickAddBtn({required this.amount, required this.unit, required this.onTap});
  final int amount;
  final String unit;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: AppColors.water.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.water.withValues(alpha: 0.4))),
          child: Text('+$amount$unit',
              style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: AppColors.waterDark,
                  fontWeight: FontWeight.bold)),
        ),
      );
}

class _MealSection extends StatelessWidget {
  const _MealSection({required this.mealType, required this.state});
  final String mealType;
  final AppState state;
  @override
  Widget build(BuildContext context) {
    final entries = state.entriesForMeal(mealType);
    final totalCal = entries.fold(0.0, (s, e) => s + e.calories).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder, width: 0.5)),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(children: [
              Text(MealType.emoji(mealType),
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(GoalType.label(mealType, state.profile?.gender ?? 'male'),
                  style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const Spacer(),
              Text('$totalCal سعرة',
                  style: GoogleFonts.cairo(
                      fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => FoodLogScreen(initialMeal: mealType))),
                child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.add_rounded,
                        color: AppColors.primary, size: 20)),
              ),
            ]),
          ),
          if (entries.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.cardBorder),
            ...entries.map((e) => _FoodTile(entry: e, state: state)),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Opacity(
                opacity: 0.5,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.add_circle_outline_rounded, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(state.profile?.gender == 'female' ? 'سجلي وجبة ${MealType.label(mealType)}' : 'سجل وجبة ${MealType.label(mealType)}', style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary)),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}

class _FoodTile extends StatelessWidget {
  const _FoodTile({required this.entry, required this.state});
  final FoodEntry entry;
  final AppState state;
  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        title: Text(entry.name,
            style:
                GoogleFonts.cairo(fontSize: 14, color: AppColors.textPrimary)),
        subtitle: Text(
            '${entry.protein.round()}ب · ${entry.carbs.round()}ك · ${entry.fat.round()}د جرام',
            style: GoogleFonts.cairo(
                fontSize: 11, color: AppColors.textSecondary)),
        trailing: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${entry.calories.round()}',
              style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary)),
          Text('سعرة',
              style: GoogleFonts.cairo(
                  fontSize: 10, color: AppColors.textSecondary)),
        ]),
        onTap: () => FoodLogScreen.showAddFoodSheet(context, entry.mealType, existingEntry: entry),
        onLongPress: () => _confirmDelete(context),
      );
  void _confirmDelete(BuildContext context) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text('حذف الطعام',
                  style: GoogleFonts.cairo(color: AppColors.textPrimary)),
              content: Text('هل تريد حذف "${entry.name}"؟',
                  style: GoogleFonts.cairo(color: AppColors.textSecondary)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('إلغاء',
                        style:
                            GoogleFonts.cairo(color: AppColors.textSecondary))),
                TextButton(
                    onPressed: () {
                      state.removeFoodEntry(entry.id);
                      Navigator.pop(context);
                    },
                    child: Text('حذف',
                        style: GoogleFonts.cairo(color: AppColors.coral))),
              ],
            ));
  }
}

class _WeightReminderBanner extends StatelessWidget {
  const _WeightReminderBanner({required this.onTap, this.profile});
  final VoidCallback onTap;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          const Icon(Icons.monitor_weight_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('حان وقت تسجيل وزنك! ⚖️', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('مر أسبوع منذ آخر تحديث، ${profile?.gender == 'female' ? 'سجلي' : 'سجل'} وزنك الجديد الآن.', style: GoogleFonts.cairo(fontSize: 11, color: Colors.white70)),
            ]),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
        ]),
      ),
    );
  }
}

class _WaterSetupPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Disabled gray card background
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 0.5),
          ),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                const Icon(Icons.water_drop_rounded, color: AppColors.textHint, size: 20),
                const SizedBox(width: 8),
                Text('الماء اليومي',
                    style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textHint)),
              ]),
              Text('0 مل / 0 لتر',
                  style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textHint)),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: const LinearProgressIndicator(
                  value: 0,
                  backgroundColor: AppColors.cardBorder,
                  valueColor: AlwaysStoppedAnimation(AppColors.cardBorder),
                  minHeight: 6),
            ),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              for (final amt in [150, 250, 350, 500])
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: AppColors.cardBorder.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('+$amtمل',
                      style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textHint)),
                ),
            ]),
          ]),
        ),
        // Overlay prompt
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.water_drop_outlined, color: Colors.white, size: 24),
                const SizedBox(height: 6),
                Text('تتبع الماء غير مُفعل',
                    style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 2),
                Text('اذهب لصفحة الماء لإعداد الجدول 💧',
                    style: GoogleFonts.cairo(fontSize: 11, color: Colors.white70)),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}
