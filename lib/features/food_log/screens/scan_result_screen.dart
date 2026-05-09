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
  final _gramsCtrl = TextEditingController(text: '100');

  double _grams = 100.0;
  String _selectedMeal = MealType.breakfast;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _selectedMeal = widget.mealType;
    _gramsCtrl.addListener(_onGramsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScan());
  }

  void _onGramsChanged() {
    final val = double.tryParse(_gramsCtrl.text) ?? 0;
    if (val != _grams) {
      setState(() {
        _grams = val;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _calCtrl.dispose();
    _proCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    _gramsCtrl.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Text('اختيار صورة الملصق', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          _SourceOption(
            icon: Icons.camera_alt_rounded,
            color: AppColors.primary,
            label: 'التقاط بالكاميرا',
            subtitle: 'استخدم الكاميرا لمسح الملصق',
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          const SizedBox(height: 12),
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
      setState(() { _isScanning = true; _error = null; _imageFile = file; });
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
        if (label.servingSizeG != null && label.servingSizeG! > 0) {
          _grams = label.servingSizeG!;
        } else {
          _grams = 100.0;
        }
        _gramsCtrl.text = _grams.round().toString();
        _calCtrl.text = label.caloriesPer100g.round().toString();
        _proCtrl.text = label.proteinPer100g.toStringAsFixed(1);
        _carbCtrl.text = label.carbsPer100g.toStringAsFixed(1);
        _fatCtrl.text = label.fatPer100g.toStringAsFixed(1);
      });
    } catch (e) {
      if (mounted) setState(() { _isScanning = false; _error = 'حصل خطأ أثناء المسح.'; });
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل اسم المنتج')));
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('نتائج المسح الضوئي', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
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
      const CircularProgressIndicator(color: AppColors.primary),
      const SizedBox(height: 24),
      Text('جارِ تحليل الملصق...', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _buildErrorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline_rounded, color: AppColors.coral, size: 64),
        const SizedBox(height: 24),
        Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _startScan, child: const Text('إعادة المحاولة')),
      ]),
    ),
  );

  Widget _buildResultState() {
    final vals = _actualValues;
    final state = context.read<AppState>();
    final profile = state.profile;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── معاينة الصورة ──
        if (_imageFile != null)
          Container(
            height: 160,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              image: DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
            ),
          ),

        // ── بطاقة اسم المنتج والوجبة ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.cardBorder)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('معلومات المنتج', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true, fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: MealType.all.map((m) => Padding(
                padding: const EdgeInsets.only(left: 10),
                child: ChoiceChip(
                  label: Text(MealType.label(m), style: GoogleFonts.cairo(fontSize: 12)),
                  selected: _selectedMeal == m,
                  onSelected: (s) => setState(() => _selectedMeal = m),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(color: _selectedMeal == m ? Colors.white : AppColors.textSecondary),
                ),
              )).toList()),
            ),
          ]),
        ),
        const SizedBox(height: 20),

        // ── بطاقة الكمية (تحويل السلايدر لمدخل يدوي) ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.teal.withValues(alpha: 0.1), Colors.white]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
          ),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.scale_rounded, color: AppColors.teal, size: 20),
              const SizedBox(width: 8),
              Text('كم جرام ستتناول؟', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.teal)),
            ]),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _gramsCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.teal),
                  decoration: const InputDecoration(border: InputBorder.none, suffixText: 'جم', suffixStyle: TextStyle(fontSize: 16)),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [50, 100, 150, 200, 300].map((g) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text('$g جم', style: GoogleFonts.cairo(fontSize: 12)),
                  selected: _grams.round() == g,
                  onSelected: (s) => _gramsCtrl.text = g.toString(),
                ),
              )).toList()),
            ),
          ]),
        ),
        const SizedBox(height: 20),

        // ── بطاقة القيم الغذائية لكل 100 جم ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.cardBorder)),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('القيم لكل 100 جم (قابلة للتعديل)', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _EditableField(ctrl: _calCtrl, label: 'سعرات', color: AppColors.primary, onChanged: () => setState(() {}))),
              const SizedBox(width: 12),
              Expanded(child: _EditableField(ctrl: _proCtrl, label: 'بروتين', color: AppColors.protein, onChanged: () => setState(() {}))),
              const SizedBox(width: 12),
              Expanded(child: _EditableField(ctrl: _carbCtrl, label: 'كارب', color: AppColors.carbs, onChanged: () => setState(() {}))),
              const SizedBox(width: 12),
              Expanded(child: _EditableField(ctrl: _fatCtrl, label: 'دهون', color: AppColors.fat, onChanged: () => setState(() {}))),
            ]),
          ]),
        ),
        const SizedBox(height: 20),

        // ── التحليل الصحي والنتيجة النهائية ──
        if (profile != null) _buildHealthAnalysis(profile),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Column(children: [
            Text('النتيجة النهائية لـ ${_grams.round()} جم', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _FinalValue(label: 'سعرات', value: vals['calories']!.round().toString(), color: AppColors.primary),
              _FinalValue(label: 'بروتين', value: vals['protein']!.toStringAsFixed(1), color: AppColors.protein),
              _FinalValue(label: 'كارب', value: vals['carbs']!.toStringAsFixed(1), color: AppColors.carbs),
              _FinalValue(label: 'دهون', value: vals['fat']!.toStringAsFixed(1), color: AppColors.fat),
            ]),
          ]),
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _addToLog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 4,
            ),
            child: Text('إضافة إلى السجل', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildHealthAnalysis(dynamic profile) {
    final vals = _actualValues;
    final cal = vals['calories']!;
    final pro = vals['protein']!;
    
    String msg = 'الكمية المختارة تناسب هدفك.';
    Color color = AppColors.teal;
    IconData icon = Icons.check_circle_rounded;

    if (cal > 400) {
      msg = 'انتبه! السعرات مرتفعة لهذه الوجبة.';
      color = AppColors.coral;
      icon = Icons.warning_rounded;
    } else if (pro > 20) {
      msg = 'رائع! الوجبة غنية جداً بالبروتين.';
      color = AppColors.teal;
      icon = Icons.bolt_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Row(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text(msg, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: color))),
      ]),
    );
  }
}

class _EditableField extends StatelessWidget {
  const _EditableField({required this.ctrl, required this.label, required this.color, required this.onChanged});
  final TextEditingController ctrl;
  final String label;
  final Color color;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TextField(
        controller: ctrl,
        onChanged: (_) => onChanged(),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: color.withValues(alpha: 0.2))),
        ),
      ),
      const SizedBox(height: 4),
      Text(label, style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textSecondary)),
    ]);
  }
}

class _FinalValue extends StatelessWidget {
  const _FinalValue({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
      Text(label, style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary)),
    ]);
  }
}

class _SourceOption extends StatelessWidget {
  const _SourceOption({required this.icon, required this.color, required this.label, required this.subtitle, required this.onTap});
  final IconData icon;
  final Color color;
  final String label, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.1))),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 24)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Text(subtitle, style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary)),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
        ]),
      ),
    );
  }
}
