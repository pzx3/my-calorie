import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/state/app_state.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/utils/calorie_calculator.dart';
import 'weight_history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AppState>(
        builder: (context, state, _) {
          final p = state.profile;
          if (p == null) return const SizedBox.shrink();
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: AppColors.background,
                pinned: true,
                title: Text('حسابي 👤',
                    style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded,
                        color: AppColors.primary),
                    onPressed: () => _showEditSheet(context, state, p),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    // Avatar & name
                    _AvatarCard(profile: p),
                    const SizedBox(height: 16),
                    // Stats row
                    _StatsRow(profile: p),
                    const SizedBox(height: 16),
                    // Goals card
                    _GoalsCard(profile: p),
                    const SizedBox(height: 16),
                    // Info card
                    _InfoCard(profile: p),
                    const SizedBox(height: 24),
                    // Weight history button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeightHistoryScreen())),
                        icon: const Icon(Icons.analytics_outlined),
                        label: Text('سجل الوزن والتطور الأسبوعي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Reset button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDelete(context, state),
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.coral),
                        label: Text('حذف الحساب',
                            style: GoogleFonts.cairo(
                                color: AppColors.coral,
                                fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.coral),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),

                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditSheet(BuildContext context, AppState state, UserProfile p) {
    final weightCtrl = TextEditingController(text: p.weightKg.toString());
    final heightCtrl = TextEditingController(text: p.heightCm.toString());
    final ageCtrl = TextEditingController(text: p.age.toString());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('تحديث القياسات',
              style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          TextField(
              controller: weightCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.cairo(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'الوزن (كجم)')),
          const SizedBox(height: 12),
          TextField(
              controller: heightCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.cairo(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'الطول (سم)')),
          const SizedBox(height: 12),
          TextField(
              controller: ageCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.cairo(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'العمر')),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final w = double.tryParse(weightCtrl.text) ?? p.weightKg;
                final h = double.tryParse(heightCtrl.text) ?? p.heightCm;
                final a = int.tryParse(ageCtrl.text) ?? p.age;
                final bmrVal = CalorieCalculator.bmr(
                    weightKg: w, heightCm: h, age: a, gender: p.gender);
                final tdeeVal = CalorieCalculator.tdee(
                    bmr: bmrVal, activityLevel: p.activityLevel);
                final newGoal =
                    CalorieCalculator.goalCalories(tdee: tdeeVal, goal: p.goal, gender: p.gender);
                state.saveProfile(p.copyWith(
                    weightKg: w,
                    heightCm: h,
                    age: a,
                    tdeeKcal: newGoal,
                    waterGoalMl: CalorieCalculator.waterGoalMl(weightKg: w, gender: p.gender, activityLevel: p.activityLevel)));
                Navigator.pop(context);
              },
              child: Text('حفظ',
                  style: GoogleFonts.cairo(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppState state) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text('حذف الحساب',
                  style: GoogleFonts.cairo(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold)),
              content: Text('سيتم حذف جميع بياناتك وسجلاتك نهائياً ولن تتمكن من استعادتها. هل أنت متأكد؟',
                  style: GoogleFonts.cairo(color: AppColors.textSecondary)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('إلغاء',
                        style:
                            GoogleFonts.cairo(color: AppColors.textSecondary))),
                ElevatedButton(
                  onPressed: () {
                    state.resetOnboarding();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coral),
                  child: Text('حذف', style: GoogleFonts.cairo()),
                ),
              ],
            ));
  }
}

class _AvatarCard extends StatelessWidget {
  const _AvatarCard({required this.profile});
  final UserProfile profile;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(children: [
          CircleAvatar(
              radius: 36,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text(profile.name.isNotEmpty ? profile.name[0] : '؟',
                  style: GoogleFonts.cairo(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white))),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(profile.name,
                style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 4),
            Text(
                '${profile.age} سنة · ${profile.gender == 'male' ? 'ذكر' : 'أنثى'}',
                style: GoogleFonts.cairo(fontSize: 13, color: Colors.white70)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(GoalType.label(profile.goal),
                  style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ]),
      );
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.profile});
  final UserProfile profile;
  @override
  Widget build(BuildContext context) {
    final ideal = CalorieCalculator.idealWeight(heightCm: profile.heightCm, age: profile.age);
    return Row(children: [
        Expanded(
            child: _StatBox(
                label: 'الوزن',
                value: '${profile.weightKg}',
                unit: 'كجم',
                color: AppColors.coral)),
        const SizedBox(width: 8),
        Expanded(
            child: _StatBox(
                label: 'المثالي',
                value: ideal.toStringAsFixed(1),
                unit: '',
                color: AppColors.primary)),
        const SizedBox(width: 8),
        Expanded(
            child: _StatBox(
                label: 'الطول',
                value: '${profile.heightCm}',
                unit: 'سم',
                color: AppColors.teal)),
        const SizedBox(width: 8),
        Expanded(
            child: _StatBox(
                label: 'BMI',
                value: profile.bmi.toStringAsFixed(1),
                unit: '',
                color: AppColors.gold)),
      ]);
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox(
      {required this.label,
      required this.value,
      required this.unit,
      required this.color});
  final String label, value, unit;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 0.5)),
        child: Column(children: [
          Text('$value$unit',
              style: GoogleFonts.cairo(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.cairo(
                  fontSize: 12, color: AppColors.textSecondary)),
        ]),
      );
}

class _GoalsCard extends StatelessWidget {
  const _GoalsCard({required this.profile});
  final UserProfile profile;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder, width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('أهدافي اليومية',
                  style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              TextButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _EditCaloriesDialog(profile: profile),
                  );
                },
                icon: const Icon(Icons.edit_rounded, size: 16, color: AppColors.primary),
                label: Text('تعديل السعرات', style: GoogleFonts.cairo(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _GoalRow(
              icon: Icons.local_fire_department_rounded,
              color: AppColors.primary,
              label: 'السعرات الحرارية',
              value: '${profile.tdeeKcal} سعرة'),
          const SizedBox(height: 12),
          _GoalRow(
              icon: Icons.water_drop_rounded,
              color: AppColors.water,
              label: 'هدف الماء',
              value: '${(profile.waterGoalMl / 1000).toStringAsFixed(1)} لتر'),
          const SizedBox(height: 12),
          _GoalRow(
              icon: Icons.directions_run_rounded,
              color: AppColors.teal,
              label: 'مستوى النشاط',
              value: ActivityLevel.label(profile.activityLevel)),
        ]),
      );
}

class _GoalRow extends StatelessWidget {
  const _GoalRow(
      {required this.icon,
      required this.color,
      required this.label,
      required this.value});
  final IconData icon;
  final Color color;
  final String label, value;
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 12),
        Text(label,
            style: GoogleFonts.cairo(
                fontSize: 14, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
      ]);
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.profile});
  final UserProfile profile;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2))),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
              child: Text(
            'جميع الحسابات (الماء، مؤشر كتلة الجسم، السعرات) مبنية على المعايير الرسمية لوزارة الصحة السعودية 🇸🇦.',
            style: GoogleFonts.cairo(
                fontSize: 13, color: AppColors.textSecondary, height: 1.6),
          )),
        ]),
      );
}

class _EditCaloriesDialog extends StatefulWidget {
  const _EditCaloriesDialog({required this.profile});
  final UserProfile profile;

  @override
  State<_EditCaloriesDialog> createState() => _EditCaloriesDialogState();
}

class _EditCaloriesDialogState extends State<_EditCaloriesDialog> {
  late int _currentKcal;
  late int _tdee;
  late int _safeFloor;

  @override
  void initState() {
    super.initState();
    _currentKcal = widget.profile.tdeeKcal;
    _safeFloor = CalorieCalculator.safeFloor(widget.profile.gender);
    final bmr = CalorieCalculator.bmr(
      weightKg: widget.profile.weightKg,
      heightCm: widget.profile.heightCm,
      age: widget.profile.age,
      gender: widget.profile.gender,
    );
    _tdee = CalorieCalculator.tdee(bmr: bmr, activityLevel: widget.profile.activityLevel).round();
  }

  @override
  Widget build(BuildContext context) {
    bool isTooLow = _currentKcal < _safeFloor;
    bool isTooHigh = _currentKcal > (_tdee * 1.3); // More than 30% surplus

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Text('تعديل السعرات الحرارية', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('الاحتياج اليومي (TDEE) بناءً على بياناتك هو $_tdee سعرة', style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 32),

          Text('$_currentKcal', style: GoogleFonts.cairo(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.primary)),
          Text('سعرة حرارية', style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textSecondary)),
          
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withValues(alpha: 0.2),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: _currentKcal.toDouble(),
              min: 800,
              max: 5000,
              divisions: 84, // (5000-800)/50
              onChanged: (val) => setState(() => _currentKcal = val.round()),
            ),
          ),
          
          if (isTooLow)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(child: Text('تحذر وزارة الصحة من النزول السريع للوزن والأنظمة القاسية، حيث تؤدي إلى إبطاء الحرق، فقدان العضلات، نقص المناعة وتساقط الشعر.', style: GoogleFonts.cairo(fontSize: 12, color: Colors.red))),
              ]),
            )
          else if (isTooHigh)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.coral.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.coral),
                const SizedBox(width: 12),
                Expanded(child: Text('هذا الرقم يتجاوز احتياجك اليومي بكثير. توصي وزارة الصحة بالاعتدال لتفادي المشاكل الصحية وتراكم الدهون السريع.', style: GoogleFonts.cairo(fontSize: 12, color: AppColors.coral))),
              ]),
            ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final state = Provider.of<AppState>(context, listen: false);
                state.saveProfile(widget.profile.copyWith(tdeeKcal: _currentKcal));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('حفظ التعديلات', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
