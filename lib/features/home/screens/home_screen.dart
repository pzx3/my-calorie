import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/state/app_state.dart';
import '../../../core/models/food_entry.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../food_log/screens/food_log_screen.dart';
import '../../profile/screens/weight_history_screen.dart';

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
                expandedHeight: 120,
                pinned: true,
                backgroundColor: AppColors.background,
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  const AppLogo(size: 28, showShadow: false),
                                  const SizedBox(width: 8),
                                  Text('مرحباً، ${profile?.name ?? 'صديقي'} 👋',
                                      style: GoogleFonts.cairo(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary)),
                                ],
                              ),
                              Text(_todayDate(),
                                  style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      color: AppColors.textSecondary)),
                            ]),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: AppColors.cardBorder, width: 0.5)),
                          child: const Icon(Icons.notifications_rounded,
                              color: AppColors.textSecondary, size: 22),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    // ── Weight Reminder Banner ──
                    if (state.shouldPromptWeight) ...[
                      _WeightReminderBanner(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeightHistoryScreen()))),
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
                    _MacroRow(state: state, goal: goal),
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
                    const SizedBox(height: 20),
                    // ── Meals ──
                    ...MealType.all
                        .map((m) => _MealSection(mealType: m, state: state)),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          );
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

class _CalorieCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final overEaten = eaten > goal;
    final ringColor = overEaten ? AppColors.coral : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
      ),
      child: Column(children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(scale: Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.bounceOut)), child: child),
          ),
          child: eaten >= goal
              ? Padding(
                  key: const ValueKey('cal_done_v2'),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('قفلت سعراتك 🔥',
                      style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)))
              : const SizedBox.shrink(key: ValueKey('cal_not_done_v2')),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CalorieIcon(size: 18),
            const SizedBox(width: 6),
            Text('السعرات الحرارية',
                style: GoogleFonts.cairo(
                    fontSize: 14, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularPercentIndicator(
            radius: 85,
            lineWidth: 12,
            percent: percent,
            animation: true,
            animationDuration: 800,
            center: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('$remaining',
                  style: GoogleFonts.cairo(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color:
                          overEaten ? AppColors.coral : AppColors.textPrimary)),
              Text(overEaten ? 'تجاوزت' : 'متبقي',
                  style: GoogleFonts.cairo(
                      fontSize: 12, color: AppColors.textSecondary)),
            ]),
            progressColor: ringColor,
            backgroundColor: AppColors.cardBorder,
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(width: 32),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _CalorieStat(label: 'الهدف', value: '$goal', color: AppColors.teal),
            const SizedBox(height: 16),
            _CalorieStat(
                label: 'مُتناول', value: '$eaten', color: AppColors.primary),
            const SizedBox(height: 16),
            const _CalorieStat(label: 'محروق', value: '0', color: AppColors.coral),
          ]),
        ]),
      ]),
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
                fontSize: 11, color: AppColors.textSecondary)),
        Text(value,
            style: GoogleFonts.cairo(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ]);
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({required this.state, required this.goal});
  final AppState state;
  final int goal;
  @override
  Widget build(BuildContext context) {
    final pGoal = (goal * 0.30 / 4).round();
    final cGoal = (goal * 0.45 / 4).round();
    final fGoal = (goal * 0.25 / 9).round();
    return Row(children: [
      Expanded(
          child: _MacroCard(
              label: 'بروتين',
              current: state.proteinToday.round(),
              goal: pGoal,
              color: AppColors.protein,
              unit: 'جم')),
      const SizedBox(width: 10),
      Expanded(
          child: _MacroCard(
              label: 'كارب',
              current: state.carbsToday.round(),
              goal: cGoal,
              color: AppColors.carbs,
              unit: 'جم')),
      const SizedBox(width: 10),
      Expanded(
          child: _MacroCard(
              label: 'دهون',
              current: state.fatToday.round(),
              goal: fGoal,
              color: AppColors.fat,
              unit: 'جم')),
    ]);
  }
}

class _MacroCard extends StatelessWidget {
  const _MacroCard(
      {required this.label,
      required this.current,
      required this.goal,
      required this.color,
      required this.unit});
  final String label, unit;
  final int current, goal;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final pct = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1)),
      child: Column(children: [
        Text('$current$unit',
            style: GoogleFonts.cairo(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.cairo(
                fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.cardBorder,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 5),
        ),
        const SizedBox(height: 4),
        Text('/$goal$unit',
            style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textHint)),
      ]),
    );
  }
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

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
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
                  child: Text('قفلت احتياجك من الماء 💧',
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
              Text(MealType.label(mealType),
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
          ],
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
  const _WeightReminderBanner({required this.onTap});
  final VoidCallback onTap;

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
              Text('مر أسبوع منذ آخر تحديث، سجل وزنك الجديد الآن.', style: GoogleFonts.cairo(fontSize: 11, color: Colors.white70)),
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
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder, width: 0.5),
          ),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                const Icon(Icons.water_drop_rounded, color: AppColors.textHint, size: 20),
                const SizedBox(width: 8),
                Text('الماء اليومي',
                    style: GoogleFonts.cairo(
                        fontSize: 14,
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
                  minHeight: 8),
            ),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              for (final amt in [150, 250, 350, 500])
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: AppColors.cardBorder.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('+$amtمل',
                      style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textHint)),
                ),
            ]),
          ]),
        ),
        // Overlay prompt
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.water_drop_outlined, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                Text('لم يتم إعداد تتبع الماء بعد',
                    style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text('اذهب لصفحة الماء لإعداد جدول شرب الماء 💧',
                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.white70)),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}
