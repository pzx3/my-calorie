import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/state/app_state.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/water_entry.dart';
import '../../../core/utils/validator.dart';
import '../../../core/services/notification_service.dart';
import '../../../shared/widgets/app_logo.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});
  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  bool _isOz = false; // false = ml, true = oz


  int _ozToMl(int oz) => (oz * 29.5735).round();
  String _mlToOzStr(int ml) => (ml / 29.5735).toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AppState>(
        builder: (context, state, _) {
          final profile = state.profile;
          final goal    = profile?.waterGoalMl ?? 2000;
          final current = state.totalWaterToday;
          final pct     = (current / goal).clamp(0.0, 1.0);
          final displayCurrent = _isOz ? _mlToOzStr(current) : '$current';
          final displayGoal    = _isOz ? _mlToOzStr(goal) : (goal / 1000).toStringAsFixed(1);
          final unit           = _isOz ? 'oz' : 'لتر';
          final currentUnit    = _isOz ? 'oz' : 'مل';

          final quickAmounts = _isOz 
              ? (profile?.quickAddOz ?? [5, 8, 12, 16])
              : (profile?.quickAddMl ?? [150, 250, 350, 500]);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: AppColors.background,
                pinned: true,
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const WaterIcon(size: 16),
                    const SizedBox(width: 6),
                    Text('تتبع الماء', style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ],
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder, width: 0.5),
                      ),
                      child: const Icon(Icons.settings_rounded, color: AppColors.textSecondary, size: 18),
                    ),
                    onPressed: () => _showWaterSettings(context, state),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    _WaterBottle(percent: pct),
                    const SizedBox(height: 16),
                    Text('$displayCurrent $currentUnit', style: GoogleFonts.cairo(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.water)),
                    Text('من أصل $displayGoal $unit', style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Text('${(pct * 100).round()}% من هدفك', style: GoogleFonts.cairo(fontSize: 11, color: pct >= 1.0 ? AppColors.green : AppColors.water)),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: ScaleTransition(scale: Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.bounceOut)), child: child),
                      ),
                      child: pct >= 1.0
                          ? Padding(
                              key: const ValueKey('water_done_screen_v2'),
                              padding: const EdgeInsets.only(top: 6),
                              child: Text('قفلت احتياجك من الماء 💧',
                                  style: GoogleFonts.cairo(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                            )
                          : const SizedBox.shrink(key: ValueKey('water_not_done_screen_v2')),
                    ),
                    const SizedBox(height: 20),
                    _UnitToggle(isOz: _isOz, onToggle: () => setState(() => _isOz = !_isOz)),
                    const SizedBox(height: 20),

                    if (profile != null && !profile.waterSetupComplete) ...[
                      _SetupWaterCard(onTap: () => _showWaterSettings(context, state)),
                    ] else ...[
                      if (pct < 1.0) ...[
                        Text('إضافة سريعة', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            for (final amt in quickAmounts)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 5),
                                child: _QuickWaterBtn(
                                  amount: amt,
                                  unit: currentUnit,
                                  onTap: () => state.addWater(_isOz ? _ozToMl(amt) : amt),
                                ),
                              ),
                          ]),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Water Schedule ──
                      if (state.profile != null) ...[
                        _WaterScheduleCard(profile: state.profile!, consumedCount: state.todayWater.length, isOz: _isOz),
                        const SizedBox(height: 20),
                      ],
                    ],

                    // History
                    if (state.todayWater.isNotEmpty) ...[
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('السجل اليومي', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        Text('${state.todayWater.length} إضافة', style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textSecondary)),
                      ]),
                      const SizedBox(height: 8),
                      ...state.todayWater.reversed.map((e) => _WaterEntryTile(entry: e, isOz: _isOz, onDelete: () => state.removeWaterEntry(e.id))),
                    ],
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<AppState>(
        builder: (context, state, _) {
          final p = state.profile;
          final pct = p == null || p.waterGoalMl <= 0 ? 0.0 : state.totalWaterToday / p.waterGoalMl;
          if (pct >= 1.0) return const SizedBox.shrink();
          return FloatingActionButton(
            heroTag: 'water_fab',
            onPressed: () => _showCustomAmountDialog(context, state),
            backgroundColor: AppColors.water,
            child: const Icon(Icons.add_rounded, color: Colors.white),
          );
        },
      ),
    );
  }

  void _showCustomAmountDialog(BuildContext context, AppState state) {
    final ctrl = TextEditingController();
    bool dialogOz = _isOz;
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final unit = dialogOz ? 'oz' : 'مل';
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('إضافة مخصصة', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                _UnitToggle(
                  isOz: dialogOz,
                  onToggle: () => setDialogState(() {
                    dialogOz = !dialogOz;
                    dialogError = Validator.cupSize(ctrl.text, dialogOz);
                  }),
                ),
              ],
            ),
            content: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.cairo(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'الكمية بال$unit',
                errorText: dialogError,
                errorStyle: GoogleFonts.cairo(fontSize: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              autofocus: true,
              onChanged: (v) => setDialogState(() => dialogError = Validator.cupSize(v, dialogOz)),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء', style: GoogleFonts.cairo(color: AppColors.textSecondary))),
              ElevatedButton(
                onPressed: () {
                  final err = Validator.cupSize(ctrl.text, dialogOz);
                  if (err != null) {
                    setDialogState(() => dialogError = err);
                    return;
                  }
                  final val = int.tryParse(ctrl.text) ?? 0;
                  if (val > 0) {
                    final ml = dialogOz ? _ozToMl(val) : val;
                    state.addWater(ml);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.water,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('إضافة', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showWaterSettings(BuildContext context, AppState state) {
    final profile = state.profile;
    if (profile == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WaterSettingsSheet(
        profile: profile,
        isOz: _isOz,
        onSave: ({required int goalMl, required int wakeHour, required int sleepHour, required List<int> quickMl, required List<int> quickOz, int? preferredCupMl}) {
          state.updateWaterSchedule(
            goalMl: goalMl,
            wakeHour: wakeHour,
            sleepHour: sleepHour,
            quickAddMl: quickMl,
            quickAddOz: quickOz,
            preferredCupMl: preferredCupMl,
          );
        },
      ),
    );
  }
}

// ──────────── Unit Toggle Badge ────────────
class _UnitToggle extends StatelessWidget {
  const _UnitToggle({required this.isOz, required this.onToggle});
  final bool isOz;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onToggle,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleChip(label: 'ml', isActive: !isOz),
          _ToggleChip(label: 'oz', isActive: isOz),
        ],
      ),
    ),
  );
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({required this.label, required this.isActive});
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: isActive ? AppColors.water : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(label, style: GoogleFonts.cairo(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: isActive ? Colors.white : AppColors.textSecondary,
    )),
  );
}

// ──────────── Animated Water Bottle ────────────
class _WaterBottle extends StatefulWidget {
  const _WaterBottle({required this.percent});
  final double percent;
  @override State<_WaterBottle> createState() => _WaterBottleState();
}

class _WaterBottleState extends State<_WaterBottle> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _anim = Tween(begin: 0.0, end: 2 * pi).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0.0, end: widget.percent),
    duration: const Duration(milliseconds: 1500),
    curve: Curves.elasticOut,
    builder: (context, fillValue, child) {
      return AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => CustomPaint(
          size: const Size(130, 200),
          painter: _WaterPainter(fillPercent: fillValue, wavePhase: _anim.value),
        ),
      );
    },
  );
}

class _WaterPainter extends CustomPainter {
  _WaterPainter({required this.fillPercent, required this.wavePhase});
  final double fillPercent, wavePhase;

  @override
  void paint(Canvas canvas, Size size) {
    final bottleRect  = RRect.fromRectAndRadius(const Offset(20, 40) & const Size(120, 190), const Radius.circular(24));
    final bottlePaint = Paint()..color = AppColors.cardBorder..style = PaintingStyle.stroke..strokeWidth = 2.5;
    final bgPaint     = Paint()..color = AppColors.card;
    canvas.drawRRect(bottleRect, bgPaint);

    // Neck
    final neckRect = RRect.fromRectAndRadius(const Offset(50, 10) & const Size(60, 36), const Radius.circular(8));
    canvas.drawRRect(neckRect, bgPaint);
    canvas.drawRRect(neckRect, bottlePaint);

    // Water fill with wave
    if (fillPercent > 0) {
      final fillHeight = 190 * fillPercent;
      final waterTop   = 40 + 190 - fillHeight;
      final wavePath   = Path();
      wavePath.moveTo(20, size.height);
      wavePath.lineTo(20, waterTop + 10);
      for (double x = 20; x <= 140; x += 2) {
        final y = waterTop + sin((x / 20) + wavePhase) * 6;
        wavePath.lineTo(x, y);
      }
      wavePath.lineTo(140, size.height);
      wavePath.close();

      final waterPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [AppColors.waterLight.withValues(alpha: 0.8), AppColors.water],
        ).createShader(Rect.fromLTRB(20, waterTop, 140, 240));

      canvas.save();
      canvas.clipRRect(bottleRect);
      canvas.drawPath(wavePath, waterPaint);
      canvas.restore();
    }

    canvas.drawRRect(bottleRect, bottlePaint);
    // Cap
    canvas.drawRRect(RRect.fromRectAndRadius(const Offset(55, 4) & const Size(50, 14), const Radius.circular(6)), Paint()..color = AppColors.water);

    // Percentage text
    final textPainter = TextPainter(
      text: TextSpan(text: '${(fillPercent * 100).round()}%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: fillPercent > 0.5 ? Colors.white : AppColors.water)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(80 - textPainter.width / 2, 40 + 95 - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(_WaterPainter old) => old.fillPercent != fillPercent || old.wavePhase != wavePhase;
}

class _QuickWaterBtn extends StatelessWidget {
  const _QuickWaterBtn({required this.amount, required this.unit, required this.onTap});
  final int amount;
  final String unit;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.water, AppColors.waterDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.water.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        const Icon(Icons.water_drop_rounded, color: Colors.white, size: 18),
        const SizedBox(height: 3),
        Text('+$amount', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        Text(unit, style: GoogleFonts.cairo(color: Colors.white70, fontSize: 9)),
      ]),
    ),
  );
}

class _WaterEntryTile extends StatelessWidget {
  const _WaterEntryTile({required this.entry, required this.isOz, required this.onDelete});
  final WaterEntry entry;
  final bool isOz;
  final VoidCallback onDelete;

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final display = isOz
        ? '+${(entry.amountMl / 29.5735).toStringAsFixed(1)} oz'
        : '+${entry.amountMl} مل';
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 20),
        color: AppColors.coral.withValues(alpha: 0.15),
        child: const Icon(Icons.delete_rounded, color: AppColors.coral),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cardBorder, width: 0.5)),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.water.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.water_drop_rounded, color: AppColors.water, size: 15)),
          const SizedBox(width: 10),
          Text(display, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const Spacer(),
          Text(_formatTime(entry.dateTime), style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}
// ──────────── Water Settings Sheet ────────────
class _WaterSettingsSheet extends StatefulWidget {
  const _WaterSettingsSheet({
    required this.profile,
    required this.isOz,
    required this.onSave,
  });
  final UserProfile profile;
  final bool isOz;
  final void Function({
    required int goalMl,
    required int wakeHour,
    required int sleepHour,
    required List<int> quickMl,
    required List<int> quickOz,
    int? preferredCupMl,
  }) onSave;

  @override
  State<_WaterSettingsSheet> createState() => _WaterSettingsSheetState();
}

class _WaterSettingsSheetState extends State<_WaterSettingsSheet> {
  late double _goalMl;
  late int _wakeHour;
  late int _sleepHour;
  late List<int> _quickMl;
  late List<int> _quickOz;
  int? _preferredCupMl;
  final _cupCtrl = TextEditingController();
  bool _remindersOn = false;
  late bool _cupIsOz;
  String? _cupError;

  @override
  void initState() {
    super.initState();
    _cupIsOz = widget.isOz;
    _goalMl = widget.profile.waterGoalMl.toDouble();
    _wakeHour = widget.profile.wakeHour;
    _sleepHour = widget.profile.sleepHour;
    _quickMl = List<int>.from(widget.profile.quickAddMl);
    _quickOz = List<int>.from(widget.profile.quickAddOz);
    _preferredCupMl = widget.profile.preferredCupMl;
    if (_preferredCupMl != null) {
      _cupCtrl.text = _cupIsOz 
          ? ( _preferredCupMl! / 29.5735).toStringAsFixed(0)
          : _preferredCupMl!.toString();
    }
  }

  void _updatePreferredCup(String v) {
    final err = Validator.cupSize(v, _cupIsOz);
    setState(() => _cupError = err);
    if (err == null) {
      final val = int.tryParse(v);
      if (val != null) {
        _preferredCupMl = _cupIsOz ? (val * 29.5735).round() : val;
      }
    } else if (v.isEmpty) {
      _preferredCupMl = null;
    }
  }

  String _display(double ml) {
    if (widget.isOz) return '${(ml / 29.5735).toStringAsFixed(0)} oz';
    return '${ml.round()} مل';
  }

  String _displayLiter(double ml) => '${(ml / 1000).toStringAsFixed(1)} لتر';

  String _formatHour(int h) {
    final period = h >= 12 ? 'مساءً' : 'صباحاً';
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour12:00 $period';
  }

  UserProfile get _previewProfile => widget.profile.copyWith(
    waterGoalMl: _goalMl.round(),
    wakeHour: _wakeHour,
    sleepHour: _sleepHour,
    preferredCupMl: _preferredCupMl,
    clearPreferredCup: _preferredCupMl == null,
  );

  Future<void> _saveAndSchedule() async {
    widget.onSave(
      goalMl: _goalMl.round(),
      wakeHour: _wakeHour,
      sleepHour: _sleepHour,
      quickMl: _quickMl,
      quickOz: _quickOz,
      preferredCupMl: _preferredCupMl,
    );

    if (_remindersOn) {
      final notif = NotificationService();
      final granted = await notif.requestPermission();
      if (granted) {
        await notif.scheduleWaterReminders(_previewProfile, isOz: widget.isOz);
      }
    } else {
      await NotificationService().cancelWaterReminders();
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final recommended = (widget.profile.weightKg * 33).round();
    final preview = _previewProfile;
    final autoDoses = preview.waterIntervals;
    final perDrink = preview.perDrinkMl;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14),
            Row(children: [
              const Icon(Icons.settings_rounded, color: AppColors.water, size: 18),
              const SizedBox(width: 8),
              Text('إعدادات الماء', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ]),
            const SizedBox(height: 16),
            _SettingSection(title: '🎯 هدف الماء اليومي', child: Column(children: [
              Text(_display(_goalMl), style: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.water)),
              Text(_displayLiter(_goalMl), style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.water, inactiveTrackColor: AppColors.cardBorder,
                  thumbColor: AppColors.water, overlayColor: AppColors.water.withValues(alpha: 0.2),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10), trackHeight: 4,
                ),
                child: Slider(value: _goalMl, min: 500, max: 5000, divisions: 90,
                  onChanged: (v) => setState(() => _goalMl = (v / 50).round() * 50.0)),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(_display(500), style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textHint)),
                GestureDetector(
                  onTap: () => setState(() => _goalMl = recommended.toDouble()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.water.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                    child: Text('↩ موصى (${_display(recommended.toDouble())})', style: GoogleFonts.cairo(fontSize: 10, color: AppColors.water, fontWeight: FontWeight.bold)),
                  ),
                ),
                Text(_display(5000), style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textHint)),
              ]),
            ])),
            const SizedBox(height: 12),

            // ── Preferred Cup Size ──
            _SettingSection(title: '🥛 حجم الكوب المفضل', child: Column(children: [
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _cupCtrl,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.cairo(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'أدخل حجم الكوب',
                      errorText: _cupError,
                      errorStyle: GoogleFonts.cairo(fontSize: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: _updatePreferredCup,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    _UnitBtn(label: 'ml', active: !_cupIsOz, onTap: () {
                      if (_cupIsOz) {
                         setState(() {
                           _cupIsOz = false;
                           if (_preferredCupMl != null) _cupCtrl.text = '$_preferredCupMl';
                           _updatePreferredCup(_cupCtrl.text);
                         });
                      }
                    }),
                    _UnitBtn(label: 'oz', active: _cupIsOz, onTap: () {
                      if (!_cupIsOz) {
                        setState(() {
                          _cupIsOz = true;
                          if (_preferredCupMl != null) _cupCtrl.text = (_preferredCupMl! / 29.5735).toStringAsFixed(0);
                          _updatePreferredCup(_cupCtrl.text);
                        });
                      }
                    }),
                  ]),
                ),
              ]),
              const SizedBox(height: 10),
              Text(
                _preferredCupMl == null 
                  ? 'سيقوم النظام بحساب حجم الكوب تلقائياً'
                  : 'سيتم تقسيم هدفك بناءً على كوب بحجم ${_display(_preferredCupMl!.toDouble())}',
                style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textHint),
                textAlign: TextAlign.center,
              ),
            ])),
            const SizedBox(height: 12),

            // ── Quick Add Management ──
            _SettingSection(
              title: '⚡ أزرار الإضافة السريعة',
              child: _QuickAddManager(
                mlAmounts: _quickMl,
                ozAmounts: _quickOz,
                onUpdateMl: (list) => setState(() => _quickMl = list),
                onUpdateOz: (list) => setState(() => _quickOz = list),
              ),
            ),
            const SizedBox(height: 12),

            // ── Wake / Sleep Times ──
            _SettingSection(title: '⏰ مواعيد الاستيقاظ والنوم', child: Column(children: [
              Row(children: [
                Expanded(child: _TimePicker(label: 'وقت الاستيقاظ', hour: _wakeHour, emoji: '🌅',
                  onChanged: (h) => setState(() => _wakeHour = h))),
                const SizedBox(width: 12),
                Expanded(child: _TimePicker(label: 'وقت النوم', hour: _sleepHour, emoji: '🌙',
                  onChanged: (h) => setState(() => _sleepHour = h))),
              ]),
              const SizedBox(height: 8),
              Text('سيبدأ التذكير بعد 30 دقيقة من ${_formatHour(_wakeHour)} حتى قبل النوم بـ 30 دقيقة',
                  style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textHint), textAlign: TextAlign.center),
            ])),
            const SizedBox(height: 12),

            // ── Reminders Toggle ──
            _SettingSection(title: '🔔 تذكير شرب الماء', child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('تفعيل إشعارات التذكير', style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textPrimary)),
                  ),
                  Switch.adaptive(
                    value: _remindersOn,
                    activeTrackColor: AppColors.water.withValues(alpha: 0.5),
                    activeThumbColor: AppColors.water,
                    onChanged: (v) => setState(() => _remindersOn = v),
                  ),
                ],
              ),
              if (_remindersOn) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.water.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.notifications_active_rounded, color: AppColors.water, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      'سيتم إرسال $autoDoses إشعار يومياً لتذكيرك بشرب ${_display(perDrink.toDouble())} في كل مرة',
                      style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary, height: 1.5),
                    )),
                  ]),
                ),
              ],
            ])),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveAndSchedule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.water,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('حفظ الإعدادات', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingSection extends StatelessWidget {
  const _SettingSection({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder, width: 0.5)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(title, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      const SizedBox(height: 10),
      child,
    ]),
  );
}

class _TimePicker extends StatelessWidget {
  const _TimePicker({required this.label, required this.hour, required this.emoji, required this.onChanged});
  final String label, emoji;
  final int hour;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final period = hour >= 12 ? 'م' : 'ص';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: 0),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(primary: AppColors.water, surface: AppColors.surface),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked.hour);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.cardBorder)),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text('$hour12:00 $period', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ]),
      ),
    );
  }
}

// ──────────── Quick Add Manager ────────────
class _QuickAddManager extends StatelessWidget {
  const _QuickAddManager({
    required this.mlAmounts,
    required this.ozAmounts,
    required this.onUpdateMl,
    required this.onUpdateOz,
  });
  final List<int> mlAmounts;
  final List<int> ozAmounts;
  final ValueChanged<List<int>> onUpdateMl;
  final ValueChanged<List<int>> onUpdateOz;

  void _add(BuildContext context, bool isOz) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('إضافة كمية جديدة', style: GoogleFonts.cairo(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: isOz ? 'الكمية (oz)' : 'الكمية (مل)'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(ctrl.text) ?? 0;
              if (val > 0) {
                if (isOz) {
                  onUpdateOz([...ozAmounts, val]..sort());
                } else {
                  onUpdateMl([...mlAmounts, val]..sort());
                }
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildUnitSection(context, 'مل لتر (ml)', mlAmounts, false),
      const SizedBox(height: 16),
      _buildUnitSection(context, 'أونصة (oz)', ozAmounts, true),
    ]);
  }

  Widget _buildUnitSection(BuildContext context, String title, List<int> list, bool isOz) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: AppColors.water),
          onPressed: () => _add(context, isOz),
        ),
      ]),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: list.map((amt) => Chip(
          label: Text('$amt', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.surface,
          deleteIcon: const Icon(Icons.close_rounded, size: 14),
          onDeleted: () {
            final newList = List<int>.from(list)..remove(amt);
            if (isOz) {
              onUpdateOz(newList);
            } else {
              onUpdateMl(newList);
            }
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppColors.cardBorder, width: 0.5)),
        )).toList(),
      ),
    ]);
  }
}

// ──────────── Water Schedule Card ────────────
class _WaterScheduleCard extends StatelessWidget {
  const _WaterScheduleCard({required this.profile, required this.consumedCount, required this.isOz});
  final UserProfile profile;
  final int consumedCount;
  final bool isOz;

  String _fmtAmount(int ml) {
    if (isOz) return '${(ml / 29.5735).toStringAsFixed(1)} oz';
    return '$ml مل';
  }

  @override
  Widget build(BuildContext context) {
    final schedule = profile.waterSchedule;
    final perDrinkDisplay = _fmtAmount(profile.perDrinkMl);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Row(children: [
            const Icon(Icons.schedule_rounded, color: AppColors.water, size: 20),
            const SizedBox(width: 8),
            Text('جدول شرب الماء', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.water.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Text('$perDrinkDisplay / مرة', style: GoogleFonts.cairo(fontSize: 11, color: AppColors.water, fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Text('${profile.waterIntervals} كوب من ${_fmtH(profile.wakeHour)} إلى ${_fmtH(profile.sleepHour)}',
              style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary)),
        ),
        const Divider(color: AppColors.cardBorder, height: 8),
        ...List.generate(schedule.length, (i) {
          final done = i < consumedCount;
          final item = schedule[i];
          final time = item['time'] as String;
          final ml = item['ml'] as int;
          final label = item['label'] as String;
          final amountStr = _fmtAmount(ml);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: done ? AppColors.water : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: done ? AppColors.water : AppColors.cardBorder, width: 2),
                ),
                child: done ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: done ? AppColors.textHint : AppColors.textSecondary,
                  )),
                  Text('$time — $amountStr', style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: done ? AppColors.textSecondary : AppColors.textPrimary,
                    fontWeight: done ? FontWeight.normal : FontWeight.w600,
                    decoration: done ? TextDecoration.lineThrough : null,
                  )),
                ],
              )),
              if (done) const Text('✅', style: TextStyle(fontSize: 14)),
            ]),
          );
        }),
        const SizedBox(height: 12),
      ]),
    );
  }

  static String _fmtH(int h) {
    final p = h >= 12 ? 'م' : 'ص';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12 $p';
  }
}

class _UnitBtn extends StatelessWidget {
  const _UnitBtn({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.water : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SetupWaterCard extends StatelessWidget {
  const _SetupWaterCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.water.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(children: [
        const Icon(Icons.water_drop_rounded, color: AppColors.water, size: 48),
        const SizedBox(height: 16),
        Text('إعداد جدول شرب الماء', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text('للحصول على أفضل النتائج وتذكيرات دقيقة، يرجى تحديد حجم الكوب المفضل لديك وأوقات شرب الماء.', 
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.water,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('ابدأ الإعداد الآن 🚀', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ]),
    );
  }
}
