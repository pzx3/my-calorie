import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/state/app_state.dart';
import '../../../core/models/food_entry.dart';
import '../../../core/services/nutrition_label_service.dart';

/// شاشة مسح ملصق القيمة الغذائية
class NutritionScanScreen extends StatefulWidget {
  const NutritionScanScreen({super.key, required this.mealType});
  final String mealType;

  @override
  State<NutritionScanScreen> createState() => _NutritionScanScreenState();
}

class _NutritionScanScreenState extends State<NutritionScanScreen> {
  final _picker = ImagePicker();
  bool _isScanning = false;
  NutritionLabel? _label;
  String? _error;

  // حقول قابلة للتعديل
  final _nameCtrl = TextEditingController(text: 'منتج غذائي');
  final _calCtrl = TextEditingController();
  final _proCtrl = TextEditingController();
  final _carbCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();

  double _grams = 100.0;
  String _selectedMeal = MealType.breakfast;

  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _selectedMeal = widget.mealType;
    // بدء عملية المسح تلقائياً عند فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScan());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _calCtrl.dispose();
    _proCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    // عرض خيارات مصدر الصورة
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('اختر مصدر الصورة', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            _SourceOption(
              icon: Icons.camera_alt_rounded,
              color: AppColors.primary,
              label: 'التقاط بالكاميرا',
              subtitle: 'صوّر ملصق القيمة الغذائية',
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 8),
            _SourceOption(
              icon: Icons.photo_library_rounded,
              color: AppColors.teal,
              label: 'اختيار من المعرض',
              subtitle: 'اختر صورة موجودة',
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );

    if (source == null) {
      if (mounted && _label == null) Navigator.pop(context);
      return;
    }

    await _processImage(source);
  }

  Future<void> _processImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, maxWidth: 1920, imageQuality: 90);
      if (picked == null) {
        if (mounted && _label == null) Navigator.pop(context);
        return;
      }

      final file = File(picked.path);

      setState(() { 
        _isScanning = true; 
        _error = null; 
        _imageFile = file;
      });

      final label = await NutritionLabelService.scanImage(file);

      if (!mounted) return;

      if (label == null || !label.isValid) {
        setState(() {
          _isScanning = false;
          _error = 'لم نتمكن من قراءة القيمة الغذائية بدقة.\nتأكد من وضوح الصورة وأن الأرقام ظاهرة بشكل جيد.';
        });
        return;
      }

      setState(() {
        _isScanning = false;
        _label = label;
        _calCtrl.text = label.caloriesPer100g.round().toString();
        _proCtrl.text = label.proteinPer100g.toStringAsFixed(1);
        _carbCtrl.text = label.carbsPer100g.toStringAsFixed(1);
        _fatCtrl.text = label.fatPer100g.toStringAsFixed(1);
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _error = 'حصل خطأ أثناء المسح. حاول مرة ثانية.';
        });
      }
    }
  }

  Map<String, double> get _actualValues {
    final cal = double.tryParse(_calCtrl.text) ?? 0;
    final pro = double.tryParse(_proCtrl.text) ?? 0;
    final carb = double.tryParse(_carbCtrl.text) ?? 0;
    final fat = double.tryParse(_fatCtrl.text) ?? 0;
    final factor = _grams / 100.0;
    return {
      'calories': cal * factor,
      'protein': pro * factor,
      'carbs': carb * factor,
      'fat': fat * factor,
    };
  }

  void _addToLog() {
    final vals = _actualValues;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('أدخل اسم المنتج', style: GoogleFonts.cairo(color: Colors.white)),
        backgroundColor: AppColors.coral,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final entry = FoodEntry(
      id: const Uuid().v4(),
      name: name,
      mealType: _selectedMeal,
      dateTime: DateTime.now(),
      calories: vals['calories']!,
      protein: vals['protein']!,
      carbs: vals['carbs']!,
      fat: vals['fat']!,
      quantity: _grams,
      unit: 'جم',
    );

    context.read<AppState>().addFoodEntry(entry);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✅ تم إضافة $name (${_grams.round()} جم)', style: GoogleFonts.cairo(color: Colors.white)),
      backgroundColor: AppColors.teal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('مسح القيمة الغذائية 📸', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
        actions: [
          if (_label != null)
            IconButton(
              icon: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              onPressed: _startScan,
              tooltip: 'مسح جديد',
            ),
        ],
      ),
      body: _isScanning
          ? _buildScanningState()
          : _error != null
              ? _buildErrorState()
              : _label != null
                  ? _buildResultState()
                  : const SizedBox.shrink(),
    );
  }

  Widget _buildScanningState() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(
        width: 60, height: 60,
        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
      ),
      const SizedBox(height: 24),
      Text('جارِ تحليل الملصق...', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      Text('نقرأ البيانات الغذائية من الصورة', style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textSecondary)),
    ]),
  );

  Widget _buildErrorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.coral.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.document_scanner_outlined, color: AppColors.coral, size: 48),
        ),
        const SizedBox(height: 24),
        Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _startScan,
          icon: const Icon(Icons.refresh_rounded, size: 20),
          label: Text('حاول مرة ثانية', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ]),
    ),
  );

  Widget _buildResultState() {
    final state = context.read<AppState>();
    final profile = state.profile;
    final vals = _actualValues;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── معاينة الصورة المستخرجة ──
        if (_imageFile != null)
          Container(
            height: 140,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder, width: 1),
              image: DecorationImage(
                image: FileImage(_imageFile!),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                        begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8, right: 12,
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 16),
                      const SizedBox(width: 4),
                      Text('تم استخراج القيم', style: GoogleFonts.cairo(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // ── اسم المنتج ──
        TextField(
          controller: _nameCtrl,
          style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'اسم المنتج',
            prefixIcon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.textSecondary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),

        // ── نوع الوجبة ──
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: MealType.all.map((m) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedMeal = m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _selectedMeal == m ? AppColors.primary : AppColors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _selectedMeal == m ? AppColors.primary : AppColors.cardBorder),
                ),
                child: Text('${MealType.emoji(m)} ${MealType.label(m)}',
                    style: GoogleFonts.cairo(fontSize: 11, color: _selectedMeal == m ? Colors.white : AppColors.textSecondary)),
              ),
            ),
          )).toList()),
        ),
        const SizedBox(height: 16),

        // ── القيم لكل 100 جم (قابلة للتعديل) ──
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 0.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text('القيم لكل 100 جم', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text('قابلة للتعديل', style: GoogleFonts.cairo(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _EditableNutrientField(ctrl: _calCtrl, label: 'سعرات', color: AppColors.primary, icon: Icons.local_fire_department_rounded, onChanged: () => setState(() {}))),
              const SizedBox(width: 8),
              Expanded(child: _EditableNutrientField(ctrl: _proCtrl, label: 'بروتين', color: AppColors.protein, icon: Icons.fitness_center_rounded, onChanged: () => setState(() {}))),
              const SizedBox(width: 8),
              Expanded(child: _EditableNutrientField(ctrl: _carbCtrl, label: 'كارب', color: AppColors.carbs, icon: Icons.grain_rounded, onChanged: () => setState(() {}))),
              const SizedBox(width: 8),
              Expanded(child: _EditableNutrientField(ctrl: _fatCtrl, label: 'دهون', color: AppColors.fat, icon: Icons.water_drop_rounded, onChanged: () => setState(() {}))),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // ── التحليل الصحي ──
        if (profile != null) _buildHealthAnalysis(profile),
        const SizedBox(height: 16),

        // ── اختيار الكمية ──
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 0.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.scale_rounded, color: AppColors.teal, size: 18),
              const SizedBox(width: 8),
              Text('كم جرام ستتناول؟', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Text('${_grams.round()}', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.teal)),
              const SizedBox(width: 4),
              Text('جم', style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textSecondary)),
            ]),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.teal, inactiveTrackColor: AppColors.cardBorder,
                thumbColor: AppColors.teal, overlayColor: AppColors.teal.withValues(alpha: 0.2),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10), trackHeight: 4,
              ),
              child: Slider(
                value: _grams, min: 10, max: 500, divisions: 49,
                onChanged: (v) => setState(() => _grams = (v / 10).round() * 10.0),
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('10 جم', style: GoogleFonts.cairo(fontSize: 9, color: AppColors.textHint)),
              // أزرار سريعة
              Row(children: [
                for (final g in [50, 100, 150, 200])
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _grams = g.toDouble()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _grams == g ? AppColors.teal.withValues(alpha: 0.15) : AppColors.card,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _grams == g ? AppColors.teal : AppColors.cardBorder),
                        ),
                        child: Text('$g', style: GoogleFonts.outfit(fontSize: 11, color: _grams == g ? AppColors.teal : AppColors.textSecondary, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ]),
              Text('500 جم', style: GoogleFonts.cairo(fontSize: 9, color: AppColors.textHint)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // ── القيم الفعلية ──
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.08), AppColors.teal.withValues(alpha: 0.05)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Column(children: [
            Text('القيم الفعلية لـ ${_grams.round()} جم', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _ActualValue(label: 'سعرات', value: vals['calories']!.round().toString(), color: AppColors.primary),
              _ActualValue(label: 'بروتين', value: '${vals['protein']!.toStringAsFixed(1)}g', color: AppColors.protein),
              _ActualValue(label: 'كارب', value: '${vals['carbs']!.toStringAsFixed(1)}g', color: AppColors.carbs),
              _ActualValue(label: 'دهون', value: '${vals['fat']!.toStringAsFixed(1)}g', color: AppColors.fat),
            ]),
          ]),
        ),
        const SizedBox(height: 24),

        // ── زر الإضافة ──
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _addToLog,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text('إضافة ${_grams.round()} جم إلى ${MealType.label(_selectedMeal)}', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHealthAnalysis(dynamic profile) {
    final cal = double.tryParse(_calCtrl.text) ?? 0;
    final pro = double.tryParse(_proCtrl.text) ?? 0;
    final fat = double.tryParse(_fatCtrl.text) ?? 0;
    final goal = profile.goal as String;

    String verdict;
    String emoji;
    Color color;
    String detail;

    if (goal == 'lose') {
      if (cal > 300) {
        verdict = 'عالي السعرات'; emoji = '🔴'; color = AppColors.coral;
        detail = 'هذا المنتج عالي السعرات. حاول تقلل الكمية أو تختار بديل أخف.';
      } else if (fat > 20) {
        verdict = 'نسبة دهون مرتفعة'; emoji = '🟡'; color = AppColors.gold;
        detail = 'الدهون مرتفعة شوي، لكن بكمية معتدلة يكون مقبول.';
      } else if (pro > 15) {
        verdict = 'مصدر بروتين ممتاز'; emoji = '🟢'; color = AppColors.teal;
        detail = 'خيار ممتاز! غني بالبروتين ويساعدك في حرق الدهون وبناء العضلات.';
      } else {
        verdict = 'مناسب بكمية معتدلة'; emoji = '🟢'; color = AppColors.teal;
        detail = 'القيم الغذائية معتدلة. مناسب كجزء من نظامك الغذائي.';
      }
    } else if (goal == 'gain') {
      if (cal > 200 && pro > 10) {
        verdict = 'ممتاز للتضخيم'; emoji = '🟢'; color = AppColors.teal;
        detail = 'سعرات وبروتين عالي — مثالي لهدف زيادة الوزن والعضلات!';
      } else if (cal > 200) {
        verdict = 'مناسب للزيادة'; emoji = '🟢'; color = AppColors.teal;
        detail = 'سعرات جيدة تساعدك في الوصول لهدفك.';
      } else {
        verdict = 'سعرات قليلة'; emoji = '🟡'; color = AppColors.gold;
        detail = 'قد تحتاج كمية أكبر أو مصدر إضافي لتحقيق فائض السعرات.';
      }
    } else {
      if (cal <= 250 && fat <= 15) {
        verdict = 'متوازن وصحي'; emoji = '🟢'; color = AppColors.teal;
        detail = 'خيار متوازن يناسب هدف الثبات.';
      } else if (cal > 350) {
        verdict = 'عالي السعرات نسبياً'; emoji = '🟡'; color = AppColors.gold;
        detail = 'كل الكمية بحذر عشان ما يزيد عن احتياجك اليومي.';
      } else {
        verdict = 'مقبول'; emoji = '🟢'; color = AppColors.teal;
        detail = 'القيم مقبولة لهدف المحافظة على الوزن.';
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(verdict, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(detail, style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary, height: 1.5)),
        ])),
      ]),
    );
  }
}

// ── ودجت حقل غذائي قابل للتعديل ──
class _EditableNutrientField extends StatelessWidget {
  const _EditableNutrientField({required this.ctrl, required this.label, required this.color, required this.icon, required this.onChanged});
  final TextEditingController ctrl;
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(icon, color: color, size: 16),
    const SizedBox(height: 4),
    SizedBox(
      height: 36,
      child: TextField(
        controller: ctrl,
        onChanged: (_) => onChanged(),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: color.withValues(alpha: 0.3))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: color.withValues(alpha: 0.2))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: color, width: 1.5)),
        ),
      ),
    ),
    const SizedBox(height: 4),
    Text(label, style: GoogleFonts.cairo(fontSize: 9, color: AppColors.textSecondary)),
  ]);
}

// ── ودجت القيمة الفعلية ──
class _ActualValue extends StatelessWidget {
  const _ActualValue({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
    Text(label, style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textSecondary)),
  ]);
}

// ── ودجت خيار مصدر الصورة ──
class _SourceOption extends StatelessWidget {
  const _SourceOption({required this.icon, required this.color, required this.label, required this.subtitle, required this.onTap});
  final IconData icon;
  final Color color;
  final String label, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Text(subtitle, style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary)),
        ])),
        Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
      ]),
    ),
  );
}
