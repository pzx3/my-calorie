import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/weight_entry.dart';
import '../../../core/state/app_state.dart';
import '../../../core/utils/calorie_calculator.dart';
import '../../../core/services/notification_service.dart';
import '../../../shared/navigation/main_navigation.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, required this.profile, required this.rawTdee});
  final UserProfile profile;
  final int rawTdee;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late int _customKcal;
  late int _minKcal;
  late int _maxKcal;

  @override
  void initState() {
    super.initState();
    _customKcal = widget.profile.tdeeKcal;
    _minKcal = CalorieCalculator.minCalories(tdee: widget.rawTdee.toDouble(), goal: widget.profile.goal, gender: widget.profile.gender);
    _maxKcal = CalorieCalculator.maxCalories(tdee: widget.rawTdee.toDouble(), goal: widget.profile.goal);
    _minKcal = (_minKcal / 50).round() * 50;
    _maxKcal = (_maxKcal / 50).round() * 50;
  }

  UserProfile get _finalProfile => widget.profile.copyWith(
        tdeeKcal: _customKcal,
        lastWeightUpdate: DateTime.now(),
        weightHistory: [
          WeightEntry(id: 'initial', weightKg: widget.profile.weightKg, date: DateTime.now()),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final ideal = CalorieCalculator.idealWeight(heightCm: widget.profile.heightCm, age: widget.profile.age);
    final range = CalorieCalculator.healthyWeightRange(heightCm: widget.profile.heightCm);
    final bmi = widget.profile.bmi;
    final waterL = (widget.profile.waterGoalMl / 1000).toStringAsFixed(1);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF13132B), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
            child: Column(
              children: [
                // ── Header ──
                const Text('🎉', style: TextStyle(fontSize: 40))
                    .animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 6),
                Text('نتائجك الشخصية',
                    style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary))
                    .animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('معايير mithaly.sa 🇸🇦',
                      style: GoogleFonts.cairo(fontSize: 10, color: AppColors.green, fontWeight: FontWeight.w600)),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 14),

                // ── Ideal Weight Card ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A5F), Color(0xFF162D4A)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.star_rounded, color: AppColors.primaryLight, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Text('وزنك المثالي', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      '${ideal.toStringAsFixed(1)} كجم',
                      style: GoogleFonts.cairo(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.primary, height: 1.1),
                    ),
                    const SizedBox(height: 6),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _MiniInfoChip(
                        icon: Icons.straighten_rounded,
                        label: 'وزنك الحالي',
                        value: '${widget.profile.weightKg} كجم',
                        color: AppColors.coral,
                      ),
                      const SizedBox(width: 8),
                      _MiniInfoChip(
                        icon: Icons.fitness_center_rounded,
                        label: 'النطاق الصحي',
                        value: '${range['min']!.toStringAsFixed(0)}-${range['max']!.toStringAsFixed(0)} كجم',
                        color: AppColors.green,
                      ),
                    ]),
                  ]),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 10),

                // ── Quick Stats Row ──
                Row(children: [
                  Expanded(child: _QuickStat(
                    icon: Icons.monitor_weight_rounded,
                    label: 'BMI',
                    value: bmi.toStringAsFixed(1),
                    sub: widget.profile.bmiCategory,
                    color: AppColors.coral,
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _QuickStat(
                    icon: Icons.water_drop_rounded,
                    label: 'ماء يومي',
                    value: '$waterL لتر',
                    sub: '${widget.profile.waterGoalMl} مل',
                    color: AppColors.water,
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _QuickStat(
                    icon: widget.profile.goal == 'lose' ? Icons.local_fire_department_rounded : Icons.fitness_center_rounded,
                    label: 'الهدف',
                    value: GoalType.emoji(widget.profile.goal),
                    sub: GoalType.label(widget.profile.goal),
                    color: AppColors.gold,
                  )),
                ]).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 10),

                // ── TDEE Card ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.local_fire_department_rounded, color: AppColors.teal, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('معدل الحرق اليومي (TDEE)', style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textSecondary)),
                      Text('${widget.rawTdee} سعرة', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.teal)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.profile.goal == 'lose' ? '-20%' : widget.profile.goal == 'gain' ? '+15%' : '±0%',
                        style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.teal),
                      ),
                    ),
                  ]),
                ).animate().fadeIn(delay: 550.ms),
                const SizedBox(height: 10),

                // ── Custom Calorie Slider ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  decoration: BoxDecoration(
                    gradient: AppColors.cardGradient,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1),
                  ),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.tune_rounded, color: AppColors.primary, size: 15),
                      const SizedBox(width: 6),
                      Text('حدد هدفك اليومي', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ]),
                    const SizedBox(height: 2),
                    Text('اسحب المؤشر لتعديل السعرات', style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Text('$_customKcal', style: GoogleFonts.cairo(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.primary, height: 1.1)),
                    Text('سعرة / يوم', style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: AppColors.cardBorder,
                        thumbColor: AppColors.primary,
                        overlayColor: AppColors.primary.withValues(alpha: 0.15),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _customKcal.toDouble(),
                        min: _minKcal.toDouble(),
                        max: _maxKcal.toDouble(),
                        divisions: ((_maxKcal - _minKcal) / 50).round().clamp(1, 100),
                        onChanged: (v) => setState(() => _customKcal = (v / 50).round() * 50),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$_minKcal', style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textHint)),
                          Text('$_maxKcal', style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textHint)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    _CalorieDiffChip(customKcal: _customKcal, rawTdee: widget.rawTdee),
                  ]),
                ).animate().fadeIn(delay: 650.ms),
                const SizedBox(height: 10),

                // ── Macro Distribution ──
                _MacroInfoCard(kcal: _customKcal, goal: widget.profile.goal).animate().fadeIn(delay: 750.ms),
                const SizedBox(height: 20),

                // ── Start Button ──
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 6))],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        // Request notification permission before finishing
                        await NotificationService().requestPermission();
                        if (context.mounted) {
                          await context.read<AppState>().saveProfile(_finalProfile);
                        }
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) => const MainNavigation(),
                                transitionsBuilder: (_, anim, __, child) => FadeTransition(
                                  opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
                                  child: child,
                                ),
                                transitionDuration: const Duration(milliseconds: 600),
                              ),
                              (_) => false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('ابدأ التتبع الآن 🚀',
                          style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.15, end: 0),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helper Widgets ──

class _MiniInfoChip extends StatelessWidget {
  const _MiniInfoChip({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 12),
      const SizedBox(width: 5),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.cairo(fontSize: 8, color: color.withValues(alpha: 0.7), height: 1.2)),
        Text(value, style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.bold, color: color, height: 1.2)),
      ]),
    ]),
  );
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({required this.icon, required this.label, required this.value, required this.sub, required this.color});
  final IconData icon;
  final String label, value, sub;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.cardBorder, width: 0.5),
    ),
    child: Column(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 16),
      ),
      const SizedBox(height: 6),
      Text(value, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      Text(label, style: GoogleFonts.cairo(fontSize: 9, color: AppColors.textSecondary, height: 1.2)),
      if (sub.isNotEmpty) Text(sub, style: GoogleFonts.cairo(fontSize: 8, color: color, height: 1.2), overflow: TextOverflow.ellipsis),
    ]),
  );
}

class _CalorieDiffChip extends StatelessWidget {
  const _CalorieDiffChip({required this.customKcal, required this.rawTdee});
  final int customKcal, rawTdee;

  @override
  Widget build(BuildContext context) {
    final diff = customKcal - rawTdee;
    final isDeficit = diff < 0;
    final color = isDeficit ? AppColors.coral : (diff > 0 ? AppColors.green : AppColors.teal);
    final label = isDeficit
        ? 'عجز ${diff.abs()} سعرة عن حرقك'
        : diff > 0
            ? 'فائض $diff سعرة عن حرقك'
            : 'مساوي لحرقك اليومي';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isDeficit ? Icons.trending_down_rounded : diff > 0 ? Icons.trending_up_rounded : Icons.horizontal_rule_rounded, color: color, size: 14),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.cairo(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MacroInfoCard extends StatelessWidget {
  const _MacroInfoCard({required this.kcal, required this.goal});
  final int kcal;
  final String goal;
  @override
  Widget build(BuildContext context) {
    final goals = CalorieCalculator.macroGoals(kcal: kcal, goal: goal);
    final protein = goals['protein']!.round();
    final carbs   = goals['carbs']!.round();
    final fat     = goals['fat']!.round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Column(children: [
        Text('توزيع الماكرو', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _MacroItem(label: 'بروتين', value: '$protein', unit: 'جم', color: AppColors.protein),
          _MacroItem(label: 'كارب',   value: '$carbs',   unit: 'جم', color: AppColors.carbs),
          _MacroItem(label: 'دهون',   value: '$fat',     unit: 'جم', color: AppColors.fat),
        ]),
      ]),
    );
  }
}

class _MacroItem extends StatelessWidget {
  const _MacroItem({required this.label, required this.value, required this.unit, required this.color});
  final String label, value, unit;
  final Color  color;
  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      width: 44, height: 44,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: color, height: 1.2)),
        Text(unit, style: GoogleFonts.cairo(fontSize: 8, color: color, height: 0.8)),
      ])),
    ),
    const SizedBox(height: 4),
    Text(label, style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textSecondary)),
  ]);
}
