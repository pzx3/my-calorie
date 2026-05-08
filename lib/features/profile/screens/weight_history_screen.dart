import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/state/app_state.dart';
import '../../../core/models/weight_entry.dart';

class WeightHistoryScreen extends StatefulWidget {
  const WeightHistoryScreen({super.key});

  @override
  State<WeightHistoryScreen> createState() => _WeightHistoryScreenState();
}

class _WeightHistoryScreenState extends State<WeightHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('وزنك وتطورك 📉', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          final history = state.profile?.weightHistory ?? [];
          if (history.isEmpty) {
            return _EmptyState(onAdd: () => _showAddWeightDialog(context, state));
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    _WeightChart(history: history),
                    const SizedBox(height: 24),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('سجلك الأسبوعي', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                        onPressed: () => _showAddWeightDialog(context, state),
                      ),
                    ]),
                  ]),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry = history.reversed.toList()[index];
                    final weekNum = history.length - index;
                    return _WeightListItem(entry: entry, state: state, weekNum: weekNum)
                        .animate()
                        .fadeIn(delay: (index * 100).ms, duration: 400.ms)
                        .slideX(begin: 0.1, end: 0);
                  },
                  childCount: history.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }

  void _showAddWeightDialog(BuildContext context, AppState state) {
    final ctrl = TextEditingController(text: state.profile?.weightKg.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('سجل وزنك الجديد', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.cairo(color: AppColors.textPrimary),
          decoration: const InputDecoration(labelText: 'الوزن (كجم)', hintText: 'مثال: 75.5'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.cairo(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () {
              final w = double.tryParse(ctrl.text);
              if (w != null && w > 20 && w < 500) {
                state.updateWeight(w);
                Navigator.pop(ctx);
              }
            },
            child: Text('حفظ', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.history});
  final List<WeightEntry> history;

  @override
  Widget build(BuildContext context) {
    final spots = history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.weightKg);
    }).toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }
}

class _WeightListItem extends StatelessWidget {
  const _WeightListItem({required this.entry, required this.state, required this.weekNum});
  final WeightEntry entry;
  final AppState state;
  final int weekNum;

  @override
  Widget build(BuildContext context) {
    // Calculate averages for the week ending at 'entry.date'
    final startDate = entry.date.subtract(const Duration(days: 6));
    int totalCal = 0;
    double totalP = 0, totalC = 0, totalF = 0;
    int daysWithData = 0;

    for (int i = 0; i < 7; i++) {
      final d = startDate.add(Duration(days: i));
      final dayEntries = state.entriesForDate(d);
      if (dayEntries.isNotEmpty) {
        daysWithData++;
        totalCal += dayEntries.fold(0, (s, e) => s + e.calories.round());
        totalP += dayEntries.fold(0.0, (s, e) => s + e.protein);
        totalC += dayEntries.fold(0.0, (s, e) => s + e.carbs);
        totalF += dayEntries.fold(0.0, (s, e) => s + e.fat);
      }
    }

    final avgCal = daysWithData > 0 ? (totalCal / daysWithData).round() : 0;
    final avgP = daysWithData > 0 ? (totalP / daysWithData).round() : 0;
    final avgC = daysWithData > 0 ? (totalC / daysWithData).round() : 0;
    final avgF = daysWithData > 0 ? (totalF / daysWithData).round() : 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                Text('الأسبوع $weekNum', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(width: 8),
                Text('(${entry.date.day}/${entry.date.month}/${entry.date.year})', style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 4),
            Text('${entry.weightKg} كجم', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text('متوسط الأسبوع', style: GoogleFonts.cairo(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 12),
        const Divider(height: 1, color: AppColors.cardBorder),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _MiniStat(label: 'سعرات', value: '$avgCal', color: AppColors.primary),
          _MiniStat(label: 'بروتين', value: '$avgPج', color: AppColors.protein),
          _MiniStat(label: 'كارب', value: '$avgCج', color: AppColors.carbs),
          _MiniStat(label: 'دهون', value: '$avgFج', color: AppColors.fat),
        ]),
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
    Text(label, style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textSecondary)),
  ]);
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.monitor_weight_outlined, size: 80, color: AppColors.cardBorder),
      const SizedBox(height: 16),
      Text('ما فيه سجل أوزان للحين', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
      const SizedBox(height: 8),
      Text('سجل وزنك كل أسبوع عشان تتابع تطورك الحقيقي!', style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textHint)),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add_rounded),
        label: Text('تسجيل الوزن الأول', style: GoogleFonts.cairo()),
      ),
    ]),
  );
}
