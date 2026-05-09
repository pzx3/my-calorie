import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/state/app_state.dart';
import '../../../core/models/food_entry.dart';
import '../../../core/utils/calorie_calculator.dart';
import '../../../shared/widgets/macro_row.dart';
import '../../home/widgets/macro_share_preview.dart';
import 'scan_result_screen.dart';

class FoodLogScreen extends StatelessWidget {
  const FoodLogScreen({super.key, this.initialMeal});
  final String? initialMeal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('سجل الطعام', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        centerTitle: true,
        backgroundColor: AppColors.background,
        actions: [
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          final goal = state.profile?.tdeeKcal ?? 2000;
          final profileGoal = state.profile?.goal ?? 'maintain';
          final macroGoals = CalorieCalculator.macroGoals(kcal: goal, goal: profileGoal);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              MacroRow(
                protein: state.proteinToday.round(),
                carbs: state.carbsToday.round(),
                fat: state.fatToday.round(),
                pGoal: macroGoals['protein']!.round(),
                cGoal: macroGoals['carbs']!.round(),
                fGoal: macroGoals['fat']!.round(),
              ),
              const SizedBox(height: 14),
              ...MealType.all.map((m) => _MealLogSection(mealType: m, state: state)),
            ],
          ).animate().fadeIn(duration: 600.ms).moveX(begin: 30, end: 0, curve: Curves.easeOutQuad);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'food_fab',
        onPressed: () => showAddFoodSheet(context, initialMeal ?? MealType.breakfast),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
        label: Text('أضف طعام', style: GoogleFonts.cairo(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  static void showAddFoodSheet(BuildContext context, String initialMeal, {FoodEntry? existingEntry}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddFoodSheet(initialMeal: initialMeal, existingEntry: existingEntry),
    );
  }
}

class _MealLogSection extends StatelessWidget {
  const _MealLogSection({required this.mealType, required this.state});
  final String   mealType;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final entries  = state.entriesForMeal(mealType);
    final totalCal = entries.fold(0.0, (s, e) => s + e.calories).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 6))],
            border: Border.all(color: Colors.white.withValues(alpha: 0.03), width: 1)),
        child: Column(children: [
          _SectionHeader(mealType: mealType, totalCal: totalCal, onAdd: () => FoodLogScreen.showAddFoodSheet(context, mealType)),
          if (entries.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.cardBorder),
            ...entries.map((e) => _FoodRow(entry: e, onDelete: () => state.removeFoodEntry(e.id))),
          ] else
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('لا يوجد طعام مسجل', style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textHint)),
            ),
        ]),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.mealType, required this.totalCal, required this.onAdd});
  final String   mealType;
  final int      totalCal;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
    child: Row(children: [
      Text(MealType.emoji(mealType), style: const TextStyle(fontSize: 22)),
      const SizedBox(width: 10),
      Text(MealType.label(mealType), style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      const Spacer(),
      Text('$totalCal سعرة', style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textSecondary)),
      const SizedBox(width: 8),
      const SizedBox(width: 4),
      GestureDetector(
        onTap: onAdd,
        child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 20)),
      ),
    ]),
  );
}

class _FoodRow extends StatelessWidget {
  const _FoodRow({required this.entry, required this.onDelete});
  final FoodEntry entry;
  final VoidCallback onDelete;

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('حذف الطعام؟', style: GoogleFonts.cairo()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(onPressed: () { onDelete(); Navigator.pop(ctx); }, child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Dismissible(
    key: Key(entry.id),
    direction: DismissDirection.endToStart,
    background: Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20),
      color: AppColors.coral.withValues(alpha: 0.15),
      child: const Icon(Icons.delete_rounded, color: AppColors.coral),
    ),
    onDismissed: (_) => onDelete(),
    child: ListTile(
      dense: true,
      onTap: () => FoodLogScreen.showAddFoodSheet(context, entry.mealType, existingEntry: entry),
      onLongPress: () => _confirmDelete(context),
      title: Text(entry.name, style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textPrimary)),
      subtitle: Text('ب:${entry.protein.round()}  ك:${entry.carbs.round()}  د:${entry.fat.round()} جم',
          style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${entry.calories.round()} سعرة',
              style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 18, color: AppColors.textSecondary),
            onPressed: () => MacroSharePreview.show(
              context,
              calories: entry.calories.round(),
              protein: entry.protein.round(),
              carbs: entry.carbs.round(),
              fat: entry.fat.round(),
              title: 'ماكروز ${entry.name} 🥗',
            ),
          ),
        ],
      ),
    ),
  );
}

// ──────────────────── Add Food Bottom Sheet (Manual Only) ────────────────────
class _AddFoodSheet extends StatefulWidget {
  const _AddFoodSheet({required this.initialMeal, this.existingEntry});
  final String initialMeal;
  final FoodEntry? existingEntry;
  @override State<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<_AddFoodSheet> {
  late String _selectedMeal;
  final _nameCtrl = TextEditingController();
  final _calCtrl  = TextEditingController();
  final _proCtrl  = TextEditingController();
  final _carbCtrl = TextEditingController();
  final _fatCtrl  = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedMeal = widget.existingEntry?.mealType ?? widget.initialMeal;
    if (widget.existingEntry != null) {
      _nameCtrl.text = widget.existingEntry!.name;
      _calCtrl.text = widget.existingEntry!.calories.round().toString();
      _proCtrl.text = widget.existingEntry!.protein.round().toString();
      _carbCtrl.text = widget.existingEntry!.carbs.round().toString();
      _fatCtrl.text = widget.existingEntry!.fat.round().toString();
    }
  }

  String? _nameError;
  String? _calError;

  void _add(BuildContext ctx) {
    final name = _nameCtrl.text.trim();
    final cal  = double.tryParse(_calCtrl.text);
    
    setState(() {
      _nameError = name.isEmpty ? 'اسم الطعام مطلوب' : null;
      _calError = (cal == null || cal <= 0) ? 'مطلوب أكبر من 0' : null;
    });

    if (_nameError != null || _calError != null) return;
    final state = ctx.read<AppState>();
    
    final entry = FoodEntry(
      id: widget.existingEntry?.id ?? const Uuid().v4(),
      name: name,
      mealType: _selectedMeal,
      dateTime: widget.existingEntry?.dateTime ?? DateTime.now(),
      calories: cal ?? 0,
      protein:  double.tryParse(_proCtrl.text)  ?? 0,
      carbs:    double.tryParse(_carbCtrl.text) ?? 0,
      fat:      double.tryParse(_fatCtrl.text)  ?? 0,
    );

    if (widget.existingEntry != null) {
      state.updateFoodEntry(entry);
    } else {
      state.addFoodEntry(entry);
    }
    Navigator.pop(ctx);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75, maxChildSize: 0.95, minChildSize: 0.5,
      builder: (ctx, ctrl) => Container(
        decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(widget.existingEntry != null ? 'تعديل الطعام' : 'إضافة طعام',
                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ),
          if (widget.existingEntry == null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => NutritionScanScreen(mealType: _selectedMeal)));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.teal, AppColors.primary.withValues(alpha: 0.8)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: AppColors.teal.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: Row(children: [
                    const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('مسح ملصق القيمة الغذائية', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('صور الملصق وسنقرأ البيانات تلقائياً', style: GoogleFonts.cairo(fontSize: 11, color: Colors.white70)),
                    ])),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              const Expanded(child: Divider(color: AppColors.cardBorder, indent: 20, endIndent: 10)),
              Text('أو إدخال يدوي', style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textHint)),
              const Expanded(child: Divider(color: AppColors.cardBorder, indent: 10, endIndent: 20)),
            ]),
          ],
          // Meal selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: MealType.all.map((m) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedMeal = m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedMeal == m ? AppColors.primary : AppColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _selectedMeal == m ? AppColors.primary : AppColors.cardBorder),
                    ),
                    child: Text('${MealType.emoji(m)} ${MealType.label(m)}',
                        style: GoogleFonts.cairo(fontSize: 13, color: _selectedMeal == m ? Colors.white : AppColors.textSecondary)),
                  ),
                ),
              )).toList()),
            ),
          ),
          // Manual entry fields
          Expanded(
            child: SingleChildScrollView(
              controller: ctrl,
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                _Field(ctrl: _nameCtrl, label: 'اسم الطعام *', hint: 'مثل: دجاج مشوي', icon: Icons.restaurant_rounded, errorText: _nameError),
                const SizedBox(height: 14),
                _Field(ctrl: _calCtrl, label: 'السعرات الحرارية *', hint: '0', numeric: true, icon: Icons.local_fire_department_rounded, errorText: _calError),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _Field(ctrl: _proCtrl, label: 'بروتين (جم)', hint: '0', numeric: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _Field(ctrl: _carbCtrl, label: 'كارب (جم)', hint: '0', numeric: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _Field(ctrl: _fatCtrl, label: 'دهون (جم)', hint: '0', numeric: true)),
                ]),
              ]),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _add(context),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text(widget.existingEntry != null ? 'حفظ التعديلات' : 'إضافة إلى اليوم', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.ctrl, required this.label, required this.hint, this.numeric = false, this.icon, this.errorText});
  final TextEditingController ctrl;
  final String label, hint;
  final bool numeric;
  final IconData? icon;
  final String? errorText;

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: numeric ? TextInputType.number : TextInputType.text,
    style: GoogleFonts.cairo(color: AppColors.textPrimary),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      prefixIcon: icon != null ? Icon(icon, color: AppColors.textSecondary, size: 20) : null,
    ),
  );
}

