import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/weight_entry.dart';
import '../../../core/state/app_state.dart';
import '../../../core/utils/calorie_calculator.dart';
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
    // Round to nearest 50
    _minKcal = (_minKcal / 50).round() * 50;
    _maxKcal = (_maxKcal / 50).round() * 50;
  }

  UserProfile get _finalProfile => widget.profile.copyWith(
        tdeeKcal: _customKcal,
        lastWeightUpdate: DateTime.now(),
        weightHistory: [
          WeightEntry(
            id: 'initial',
            weightKg: widget.profile.weightKg,
            date: DateTime.now(),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {

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
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Text('🎉', style: TextStyle(fontSize: 60)).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 16),
                Text('نتائجك الشخصية',
                    style: GoogleFonts.cairo(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary))
                    .animate().fadeIn(delay: 300.ms),
                Text('جميع الحسابات مبنية على معايير وزارة الصحة السعودية 🇸🇦',
                    style: GoogleFonts.cairo(fontSize: 13, color: AppColors.green))
                    .animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 32),

                // ── TDEE Info Card ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8))],
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
                  ),
                  child: Column(children: [
                    Text('معدل حرقك اليومي (TDEE)', style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Text('${widget.rawTdee}', style: GoogleFonts.cairo(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.teal)),
                    Text('سعرة حرارية / يوم', style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Text(
                      widget.profile.goal == 'lose' ? 'لإنقاص الوزن، ننصحك بتقليل السعرات بنسبة 20%' :
                      widget.profile.goal == 'gain' ? 'لبناء العضلات، ننصحك بزيادة السعرات بنسبة 15%' :
                      'هذا هو عدد السعرات للحفاظ على وزنك الحالي',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textHint),
                    ),
                  ]),
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 20),

                // ── Custom Calorie Target ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.cardGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Column(children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text('حدد هدفك اليومي', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('اسحب المؤشر لتعديل عدد السعرات حسب رغبتك', style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    // Big calorie number
                    Text('$_customKcal', style: GoogleFonts.cairo(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.primary)),
                    Text('سعرة / يوم', style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    // Slider
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: AppColors.cardBorder,
                        thumbColor: AppColors.primary,
                        overlayColor: AppColors.primary.withValues(alpha: 0.2),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
                        trackHeight: 6,
                      ),
                      child: Slider(
                        value: _customKcal.toDouble(),
                        min: _minKcal.toDouble(),
                        max: _maxKcal.toDouble(),
                        divisions: ((_maxKcal - _minKcal) / 50).round().clamp(1, 100),
                        onChanged: (v) => setState(() => _customKcal = (v / 50).round() * 50),
                      ),
                    ),
                    // Min/Max labels
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$_minKcal', style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textHint)),
                          Text('$_maxKcal', style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textHint)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Difference from TDEE
                    _CalorieDiffChip(customKcal: _customKcal, rawTdee: widget.rawTdee),
                  ]),
                ).animate().fadeIn(delay: 600.ms),
                const SizedBox(height: 20),

                // Stats grid
                GridView.count(
                  crossAxisCount: 2, shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12, mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                  children: [
                    _StatCard(icon: Icons.monitor_weight_rounded,   color: AppColors.coral,   label: 'BMI',          value: widget.profile.bmi.toStringAsFixed(1), sub: widget.profile.bmiCategory),
                    _StatCard(icon: Icons.star_rounded,             color: AppColors.primary, label: 'الوزن المثالي', value: '${CalorieCalculator.idealWeight(heightCm: widget.profile.heightCm, age: widget.profile.age).toStringAsFixed(1)} كجم', sub: '${CalorieCalculator.healthyWeightRange(heightCm: widget.profile.heightCm)['min']!.toStringAsFixed(0)}-${CalorieCalculator.healthyWeightRange(heightCm: widget.profile.heightCm)['max']!.toStringAsFixed(0)} كجم'),
                    _StatCard(icon: Icons.water_drop_rounded,       color: AppColors.water,   label: 'ماء يومي',    value: '${(widget.profile.waterGoalMl / 1000).toStringAsFixed(1)} لتر', sub: 'وزارة الصحة 🇸🇦'),
                    _StatCard(icon: GoalType.emoji(widget.profile.goal) == '🔥' ? Icons.local_fire_department_rounded : Icons.fitness_center_rounded,
                                                                    color: AppColors.gold,    label: 'هدفك',         value: GoalType.label(widget.profile.goal), sub: ''),
                  ],
                ).animate().fadeIn(delay: 700.ms),
                const SizedBox(height: 12),

                // Macro info card (uses custom kcal)
                _MacroInfoCard(kcal: _customKcal, goal: widget.profile.goal).animate().fadeIn(delay: 900.ms),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await context.read<AppState>().saveProfile(_finalProfile);
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => const MainNavigation(),
                              transitionsBuilder: (_, anim, __, child) => SlideTransition(
                                position: anim.drive(Tween(begin: const Offset(1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic))),
                                child: child,
                              ),
                              transitionDuration: const Duration(milliseconds: 600),
                            ),
                            (_) => false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: Text('ابدأ التتبع الآن 🚀',
                        style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                ).animate().fadeIn(delay: 1100.ms).slideY(begin: 0.3, end: 0),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
        ? 'عجز ${diff.abs()} سعرة عن حرقك اليومي'
        : diff > 0
            ? 'فائض $diff سعرة عن حرقك اليومي'
            : 'مساوي لحرقك اليومي';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isDeficit ? Icons.trending_down_rounded : diff > 0 ? Icons.trending_up_rounded : Icons.horizontal_rule_rounded, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.cairo(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.color, required this.label, required this.value, required this.sub});
  final dynamic icon;
  final Color  color;
  final String label, value, sub;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.cardBorder, width: 0.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
        child: icon is String ? Text(icon, style: const TextStyle(fontSize: 16)) : Icon(icon as IconData, color: color, size: 18)),
      const SizedBox(height: 8),
      Text(label, style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary)),
      Text(value,  style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      if (sub.isNotEmpty) Text(sub, style: GoogleFonts.cairo(fontSize: 11, color: color), overflow: TextOverflow.ellipsis),
    ]),
  );
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Column(children: [
        Text('توزيع الماكرو المخصص لك', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _MacroItem(label: 'بروتين', value: '$proteinجم', color: AppColors.protein),
          _MacroItem(label: 'كارب',   value: '$carbsجم',   color: AppColors.carbs),
          _MacroItem(label: 'دهون',   value: '$fatجم',     color: AppColors.fat),
        ]),
      ]),
    );
  }
}

class _MacroItem extends StatelessWidget {
  const _MacroItem({required this.label, required this.value, required this.color});
  final String label, value;
  final Color  color;
  @override
  Widget build(BuildContext context) => Column(children: [
    Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
      child: Center(child: Text(value, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: color)))),
    const SizedBox(height: 6),
    Text(label, style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary)),
  ]);
}
