import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/state/app_state.dart';
import '../../../core/utils/calorie_calculator.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AppState>(
        builder: (context, state, _) {
          final profile   = state.profile;
          final goal      = profile?.tdeeKcal ?? 2000;
          final eaten     = state.totalCaloriesToday;
          final waterGoal = profile?.waterGoalMl ?? 2000;
          final water     = state.totalWaterToday;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: AppColors.background,
                pinned: true,
                title: Text('التقدم 📊', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                centerTitle: true,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    // BMI Card
                    if (profile != null) _BmiCard(profile: profile),
                    const SizedBox(height: 16),
                    // Goal Card
                    if (profile != null) _GoalCard(profile: profile),
                    const SizedBox(height: 16),
                    // Today Summary
                    _TodaySummaryCard(eaten: eaten, goal: goal, water: water, waterGoal: waterGoal),
                    const SizedBox(height: 16),
                    // Macro Progress
                    _MacroProgressCard(state: state, goal: goal),
                    const SizedBox(height: 16),
                    // Weekly chart
                    _WeeklyChart(state: state, goal: goal),
                    const SizedBox(height: 16),
                    // Macro Weekly chart
                    _MacroWeeklyChart(state: state, goal: goal),
                    const SizedBox(height: 16),
                    // Weekly Log Details
                    _WeeklyLogList(state: state),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 600.ms).moveY(begin: 30, end: 0, curve: Curves.easeOutQuad);
        },
      ),
    );
  }
}

class _BmiCard extends StatelessWidget {
  const _BmiCard({required this.profile});
  final dynamic profile; // UserProfile

  @override
  Widget build(BuildContext context) {
    final bmi = profile.bmi as double;
    final Color color;
    if (bmi < 18.5) {
      color = AppColors.water;
    } else if (bmi < 25) {
      color = AppColors.green;
    } else if (bmi < 30) {
      color = AppColors.gold;
    } else if (bmi < 35) {
      color = AppColors.coral;
    } else {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Row(children: [
        CircularPercentIndicator(
          radius: 50, lineWidth: 8,
          percent: (bmi / 40).clamp(0.0, 1.0),
          center: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(bmi.toStringAsFixed(1), style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text('BMI', style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textSecondary)),
          ]),
          progressColor: color, backgroundColor: AppColors.cardBorder,
          circularStrokeCap: CircularStrokeCap.round, animation: true,
        ),
        const SizedBox(width: 20),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('مؤشر كتلة الجسم', style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(profile.bmiCategory as String, style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 8),
          Text('الوزن: ${profile.weightKg} كجم · الطول: ${profile.heightCm} سم',
              style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary)),
        ])),
      ]),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.profile});
  final dynamic profile;

  @override
  Widget build(BuildContext context) {
    String recommended = 'maintain';
    final bmi = profile.bmi as double;
    if (bmi < 18.5) recommended = 'gain';
    else if (bmi >= 25.0) recommended = 'lose';

    String goalText = '';
    if (profile.goal == 'lose') goalText = 'إنقاص الوزن 🔥';
    else if (profile.goal == 'gain') goalText = 'زيادة الوزن 💪';
    else goalText = 'المحافظة على الوزن ⚖️';

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: const Icon(Icons.stars_rounded, color: AppColors.gold, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الهدف الحالي', style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textSecondary)),
                  Text(goalText, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
            ],
          ),
        ),
        if (profile.goal != recommended)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.coral.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.coral.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.coral, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  profile.gender == 'female'
                      ? 'هالهدف مو أنسب شيء لكِ بناءً على وزنك، بس القرار بيدك وإحنا بندعمك! 💪'
                      : 'هالهدف مو أنسب شيء لك بناءً على وزنك، بس القرار بيدك وإحنا بندعمك! 💪',
                  style: GoogleFonts.cairo(fontSize: 11, color: AppColors.coral, fontWeight: FontWeight.bold),
                )),
              ]),
            ).animate().fadeIn(delay: 300.ms),
          ),
      ],
    );
  }
}

class _TodaySummaryCard extends StatelessWidget {
  const _TodaySummaryCard({required this.eaten, required this.goal, required this.water, required this.waterGoal});
  final int eaten, goal, water, waterGoal;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder, width: 0.5)),
    child: Column(children: [
      Text('ملخص اليوم', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: _SummaryItem(label: 'سعرات متناولة', value: '$eaten', unit: 'سعرة', color: AppColors.primary, icon: Icons.local_fire_department_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _SummaryItem(label: 'الهدف اليومي', value: '$goal', unit: 'سعرة', color: AppColors.teal, icon: Icons.flag_rounded)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _SummaryItem(label: 'ماء متناول', value: '$water', unit: 'مل', color: AppColors.water, icon: Icons.water_drop_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _SummaryItem(label: 'هدف الماء', value: (waterGoal / 1000).toStringAsFixed(1), unit: 'لتر', color: AppColors.waterLight, icon: Icons.local_drink_rounded)),
      ]),
    ]),
  );
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value, required this.unit, required this.color, required this.icon});
  final String label, value, unit;
  final Color  color;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.cardBorder, width: 0.5)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 8),
      Text(label, style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary)),
      const SizedBox(height: 2),
      RichText(text: TextSpan(
        text: value, style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        children: [TextSpan(text: ' $unit', style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary))],
      )),
    ]),
  );
}

class _MacroProgressCard extends StatelessWidget {
  const _MacroProgressCard({required this.state, required this.goal});
  final AppState state;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final profileGoal = state.profile?.goal ?? 'maintain';
    final macroGoals = CalorieCalculator.macroGoals(kcal: goal, goal: profileGoal, weightKg: state.profile?.weightKg ?? 70.0);
    final pGoal = macroGoals['protein']!.round();
    final cGoal = macroGoals['carbs']!.round();
    final fGoal = macroGoals['fat']!.round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('الماكرو اليوم', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        _MacroBar(label: 'بروتين', current: state.proteinToday.round(), goal: pGoal, color: AppColors.protein),
        const SizedBox(height: 12),
        _MacroBar(label: 'كارب',   current: state.carbsToday.round(),   goal: cGoal, color: AppColors.carbs),
        const SizedBox(height: 12),
        _MacroBar(label: 'دهون',   current: state.fatToday.round(),     goal: fGoal, color: AppColors.fat),
      ]),
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({required this.label, required this.current, required this.goal, required this.color});
  final String label;
  final int    current, goal;
  final Color  color;
  @override
  Widget build(BuildContext context) {
    final pct = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textSecondary)),
        Text('$current / $goal جم', style: GoogleFonts.cairo(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 6),
      LinearPercentIndicator(
        percent: pct, lineHeight: 8, padding: EdgeInsets.zero,
        progressColor: color, backgroundColor: AppColors.cardBorder,
        barRadius: const Radius.circular(4), animation: true,
      ),
    ]);
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.state, required this.goal});
  final AppState state;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayNames = ['س', 'ح', 'إث', 'ث', 'ر', 'خ', 'ج'];
    final bars = List.generate(7, (i) {
      final daysAgo = 6 - i;
      final date = now.subtract(Duration(days: daysAgo));
      final eaten = state.caloriesForDate(date);
      final isToday = i == 6;
      return BarChartGroupData(x: i, barRods: [
        BarChartRodData(
          toY: eaten.toDouble(),
          color: isToday ? AppColors.primary : AppColors.cardBorder,
          width: 22, borderRadius: BorderRadius.circular(6),
        ),
      ]);
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('السعرات الأسبوعية', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Text('الهدف: $goal', style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          height: 160,
          child: BarChart(BarChartData(
            maxY: (goal * 1.3).toDouble(),
            barGroups: bars,
            gridData: FlGridData(
              show: true, drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.cardBorder, strokeWidth: 0.5),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                final dayIndex = (now.weekday - 1 + v.round()) % 7;
                return Text(dayNames[dayIndex], style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary));
              })),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            extraLinesData: ExtraLinesData(horizontalLines: [
              HorizontalLine(y: goal.toDouble(), color: AppColors.teal.withValues(alpha: 0.5), strokeWidth: 1.5, dashArray: [6, 4]),
            ]),
            barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, __) => BarTooltipItem('${rod.toY.round()}', GoogleFonts.cairo(color: Colors.white, fontSize: 12)),
            )),
          )),
        ),
      ]),
    );
  }
}

class _MacroWeeklyChart extends StatelessWidget {
  const _MacroWeeklyChart({required this.state, required this.goal});
  final AppState state;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayNames = ['س', 'ح', 'إث', 'ث', 'ر', 'خ', 'ج'];
    
    final profileGoal = state.profile?.goal ?? 'maintain';
    final macroGoals = CalorieCalculator.macroGoals(kcal: goal, goal: profileGoal, weightKg: state.profile?.weightKg ?? 70.0);
    final pGoal = macroGoals['protein']!.round();
    final cGoal = macroGoals['carbs']!.round();
    final fGoal = macroGoals['fat']!.round();
    final maxGrams = (pGoal + cGoal + fGoal) * 1.3;

    final bars = List.generate(7, (i) {
      final daysAgo = 6 - i;
      final date = now.subtract(Duration(days: daysAgo));
      final entries = state.entriesForDate(date);
      final p = entries.fold(0.0, (s, e) => s + e.protein).roundToDouble();
      final c = entries.fold(0.0, (s, e) => s + e.carbs).roundToDouble();
      final f = entries.fold(0.0, (s, e) => s + e.fat).roundToDouble();
      
      return BarChartGroupData(x: i, barRods: [
        BarChartRodData(
          toY: p + c + f,
          width: 22,
          borderRadius: BorderRadius.circular(6),
          color: AppColors.cardBorder, // fallback color if empty
          rodStackItems: [
            BarChartRodStackItem(0, p, AppColors.protein),
            BarChartRodStackItem(p, p + c, AppColors.carbs),
            BarChartRodStackItem(p + c, p + c + f, AppColors.fat),
          ]
        ),
      ]);
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('المغذيات الأسبوعية (ماكرو)', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _LegendItem(color: AppColors.protein, label: 'بروتين'),
          const SizedBox(width: 12),
          _LegendItem(color: AppColors.carbs, label: 'كارب'),
          const SizedBox(width: 12),
          _LegendItem(color: AppColors.fat, label: 'دهون'),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          height: 160,
          child: BarChart(BarChartData(
            maxY: maxGrams.toDouble(),
            barGroups: bars,
            gridData: FlGridData(
              show: true, drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.cardBorder, strokeWidth: 0.5),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                final dayIndex = (now.weekday - 1 + v.round()) % 7;
                return Text(dayNames[dayIndex], style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary));
              })),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, __) => BarTooltipItem('${rod.toY.round()} جم', GoogleFonts.cairo(color: Colors.white, fontSize: 12)),
            )),
          )),
        ),
      ]),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary)),
  ]);
}

class _WeeklyLogList extends StatelessWidget {
  const _WeeklyLogList({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Show last 7 days, starting from today (i=0) to 6 days ago (i=6)
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder, width: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('السجل الأسبوعي', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),
          ...List.generate(7, (i) {
            final date = now.subtract(Duration(days: i));
            return _DayLogItem(date: date, state: state);
          }),
        ],
      ),
    );
  }
}

class _DayLogItem extends StatelessWidget {
  const _DayLogItem({required this.date, required this.state});
  final DateTime date;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final entries = state.entriesForDate(date);
    final totalCal = entries.fold(0.0, (s, e) => s + e.calories).round();
    final isToday = date.year == DateTime.now().year && date.month == DateTime.now().month && date.day == DateTime.now().day;
    final dayNames = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    final title = isToday ? 'اليوم' : '${dayNames[date.weekday - 1]}، ${date.day}/${date.month}';

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        collapsedIconColor: AppColors.textSecondary,
        iconColor: AppColors.primary,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Text('$totalCal سعرة', style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
        children: entries.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('لا توجد بيانات مسجلة لهذا اليوم.', style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textHint)),
                )
              ]
            : entries.map((e) => ListTile(
                  dense: true,
                  title: Text(e.name, style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textPrimary)),
                  subtitle: Text('ب:${e.protein.round()} ك:${e.carbs.round()} د:${e.fat.round()} جم', style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary)),
                  trailing: Text('${e.calories.round()}', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                )).toList(),
      ),
    );
  }
}
