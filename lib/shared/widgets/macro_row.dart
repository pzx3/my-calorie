import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class MacroRow extends StatelessWidget {
  const MacroRow({
    super.key,
    required this.protein, required this.carbs, required this.fat,
    required this.pGoal, required this.cGoal, required this.fGoal,
  });
  final int protein, carbs, fat, pGoal, cGoal, fGoal;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: MacroCard(label: 'بروتين', current: protein, goal: pGoal, color: AppColors.protein, unit: 'جم')),
      const SizedBox(width: 8),
      Expanded(child: MacroCard(label: 'كارب', current: carbs, goal: cGoal, color: AppColors.carbs, unit: 'جم')),
      const SizedBox(width: 8),
      Expanded(child: MacroCard(label: 'دهون', current: fat, goal: fGoal, color: AppColors.fat, unit: 'جم')),
    ]);
  }
}

class MacroCard extends StatelessWidget {
  const MacroCard({
    super.key,
    required this.label, required this.current, required this.goal, required this.color, required this.unit
  });
  final String label, unit;
  final int current, goal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    final overGoal = current > goal;
    final overPct = overGoal && goal > 0 ? (((current - goal) / goal) * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: overGoal ? AppColors.coral.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05), width: 1),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (overGoal)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text('+$overPct%', style: GoogleFonts.cairo(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.coral)),
          ),
        Text('$current', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: AppColors.cardBorder,
            valueColor: AlwaysStoppedAnimation(overGoal ? AppColors.coral : color),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 3),
        Text(overGoal ? 'فوق الاحتياج' : '/$goal$unit', 
            style: GoogleFonts.cairo(fontSize: 9, color: overGoal ? AppColors.coral : AppColors.textHint)),
      ]),
    );
  }
}
