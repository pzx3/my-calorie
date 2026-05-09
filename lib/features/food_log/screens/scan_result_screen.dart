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
  final _nameCtrl = TextEditingController(text: 'منتج غذائي');
  final _calCtrl = TextEditingController();
  final _proCtrl = TextEditingController();
  final _carbCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  
  // الدهون المفصلة
  final _satFatCtrl = TextEditingController();
  final _transFatCtrl = TextEditingController();
  
  // الكربوهيدرات المفصلة
  final _fiberCtrl = TextEditingController();
  final _sugarCtrl = TextEditingController();
  final _addedSugarCtrl = TextEditingController();
  
  // المعادن والفيتامينات
  final _sodiumCtrl = TextEditingController();
  final _cholesterolCtrl = TextEditingController();
  final _vitDCtrl = TextEditingController();
  final _calciumCtrl = TextEditingController();
  final _ironCtrl = TextEditingController();
  final _potassiumCtrl = TextEditingController();

  final _gramsCtrl = TextEditingController(text: '1'); // عدد الحصص
  final _unitWeightCtrl = TextEditingController(text: '100'); // وزن الحصة الواحدة بالجرام

  String _selectedUnit = 'جم';
  String _selectedMeal = MealType.breakfast;
  File? _imageFile;

  final List<String> _units = ['جم', 'مل', 'قطعة', 'كوب', 'ملعقة', 'عبوة', 'حصة'];

  @override
  void initState() {
    super.initState();
    _selectedMeal = widget.mealType;
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScan());
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _calCtrl.dispose(); _proCtrl.dispose(); _carbCtrl.dispose(); _fatCtrl.dispose();
    _satFatCtrl.dispose(); _transFatCtrl.dispose(); _fiberCtrl.dispose(); _sugarCtrl.dispose(); _addedSugarCtrl.dispose();
    _sodiumCtrl.dispose(); _cholesterolCtrl.dispose(); _vitDCtrl.dispose(); _calciumCtrl.dispose(); _ironCtrl.dispose(); _potassiumCtrl.dispose();
    _gramsCtrl.dispose(); _unitWeightCtrl.dispose();
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
          Text('تصوير الملصق للمعالجة', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
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
      
      // نقوم بالمسح لكن لا نعبئ البيانات آلياً بناءً على طلب المستخدم
      final label = await NutritionLabelService.scanImage(file);
      
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _label = label ?? NutritionLabel(caloriesPer100g: 0, proteinPer100g: 0, carbsPer100g: 0, fatPer100g: 0, rawText: '');
      });
    } catch (e) {
      if (mounted) setState(() { _isScanning = false; _error = 'حصل خطأ أثناء المعالجة.'; });
    }
  }

  void _addToLog() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل اسم المنتج')));
      return;
    }

    final count = double.tryParse(_gramsCtrl.text) ?? 1.0;
    final unitWeight = double.tryParse(_unitWeightCtrl.text) ?? 100.0;
    final totalGrams = _selectedUnit == 'جم' || _selectedUnit == 'مل' ? count : count * unitWeight;

    // القيم المدخلة (نفترض أنها لكل 100 جرام لتسهيل الحساب)
    final cal100 = double.tryParse(_calCtrl.text) ?? 0.0;
    final pro100 = double.tryParse(_proCtrl.text) ?? 0.0;
    final carb100 = double.tryParse(_carbCtrl.text) ?? 0.0;
    final fat100 = double.tryParse(_fatCtrl.text) ?? 0.0;
    
    final factor = totalGrams / 100.0;

    final entry = FoodEntry(
      id: const Uuid().v4(),
      name: name,
      mealType: _selectedMeal,
      dateTime: DateTime.now(),
      calories: cal100 * factor,
      protein: pro100 * factor,
      carbs: carb100 * factor,
      fat: fat100 * factor,
      quantity: count,
      unit: _selectedUnit,
      saturatedFat: (double.tryParse(_satFatCtrl.text) ?? 0) * factor,
      transFat: (double.tryParse(_transFatCtrl.text) ?? 0) * factor,
      fiber: (double.tryParse(_fiberCtrl.text) ?? 0) * factor,
      sugar: (double.tryParse(_sugarCtrl.text) ?? 0) * factor,
      addedSugar: (double.tryParse(_addedSugarCtrl.text) ?? 0) * factor,
      sodium: (double.tryParse(_sodiumCtrl.text) ?? 0) * factor,
      cholesterol: (double.tryParse(_cholesterolCtrl.text) ?? 0) * factor,
      vitaminD: (double.tryParse(_vitDCtrl.text) ?? 0) * factor,
      calcium: (double.tryParse(_calciumCtrl.text) ?? 0) * factor,
      iron: (double.tryParse(_ironCtrl.text) ?? 0) * factor,
      potassium: (double.tryParse(_potassiumCtrl.text) ?? 0) * factor,
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
        title: Text('إدخال القيمة الغذائية', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
      ),
      body: _isScanning
          ? _buildScanningState()
          : _error != null
              ? _buildErrorState()
              : _label != null
                  ? _buildManualEntryForm()
                  : const SizedBox.shrink(),
    );
  }

  Widget _buildScanningState() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const CircularProgressIndicator(color: AppColors.primary),
      const SizedBox(height: 24),
      Text('جاري معالجة الصورة...', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _buildErrorState() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline_rounded, color: AppColors.coral, size: 64),
      const SizedBox(height: 16),
      Text(_error!, style: GoogleFonts.cairo(color: AppColors.textSecondary)),
      const SizedBox(height: 24),
      ElevatedButton(onPressed: _startScan, child: const Text('إعادة المحاولة')),
    ]),
  );

  Widget _buildManualEntryForm() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── بطاقة المعلومات الأساسية ──
        _buildSectionCard(
          title: 'معلومات المنتج والوجبة',
          icon: Icons.info_outline_rounded,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: _inputDecoration('اسم المنتج', Icons.edit_rounded),
              style: GoogleFonts.cairo(fontSize: 14),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: MealType.all.map((m) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text(MealType.label(m), style: GoogleFonts.cairo(fontSize: 11)),
                  selected: _selectedMeal == m,
                  onSelected: (s) => setState(() => _selectedMeal = m),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(color: _selectedMeal == m ? Colors.white : AppColors.textSecondary),
                ),
              )).toList()),
            ),
          ],
        ),

        // ── بطاقة حجم الحصة ──
        _buildSectionCard(
          title: 'حجم الحصة والكمية المستهلكة',
          icon: Icons.scale_rounded,
          children: [
            Row(children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _gramsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('الكمية', Icons.onetwothree_rounded),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  value: _selectedUnit,
                  items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u, style: GoogleFonts.cairo(fontSize: 14)))).toList(),
                  onChanged: (v) => setState(() => _selectedUnit = v!),
                  decoration: _inputDecoration('الوحدة', Icons.unfold_more_rounded),
                ),
              ),
            ]),
            if (_selectedUnit != 'جم' && _selectedUnit != 'مل') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _unitWeightCtrl,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('وزن الـ $_selectedUnit الواحدة (جم)', Icons.balance_rounded),
              ),
            ],
          ],
        ),

        // ── بطاقة حقائق التغذية (لكل 100 جم) ──
        _buildSectionCard(
          title: 'حقائق التغذية (أدخل القيم لكل 100 جم)',
          icon: Icons.fact_check_rounded,
          children: [
            _buildNutritionGrid([
              _NutrientInput(ctrl: _calCtrl, label: 'سعرات', color: AppColors.primary),
              _NutrientInput(ctrl: _proCtrl, label: 'بروتين', color: AppColors.protein),
              _NutrientInput(ctrl: _carbCtrl, label: 'كارب', color: AppColors.carbs),
              _NutrientInput(ctrl: _fatCtrl, label: 'دهون', color: AppColors.fat),
            ]),
            const Divider(height: 32),
            Text('الدهون التفصيلية', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildNutritionGrid([
              _NutrientInput(ctrl: _satFatCtrl, label: 'مشبعة', color: AppColors.fat),
              _NutrientInput(ctrl: _transFatCtrl, label: 'متحولة', color: AppColors.fat),
              _NutrientInput(ctrl: _cholesterolCtrl, label: 'كوليسترول', color: AppColors.fat),
              _NutrientInput(ctrl: _sodiumCtrl, label: 'صوديوم', color: Colors.orange),
            ]),
            const Divider(height: 32),
            Text('الكربوهيدرات والمعادن', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildNutritionGrid([
              _NutrientInput(ctrl: _fiberCtrl, label: 'ألياف', color: Colors.green),
              _NutrientInput(ctrl: _sugarCtrl, label: 'سكر', color: Colors.pink),
              _NutrientInput(ctrl: _addedSugarCtrl, label: 'سكر مضاف', color: Colors.redAccent),
              _NutrientInput(ctrl: _vitDCtrl, label: 'فيتامين D', color: Colors.amber),
            ]),
            const SizedBox(height: 12),
            _buildNutritionGrid([
              _NutrientInput(ctrl: _calciumCtrl, label: 'كالسيوم', color: Colors.blueGrey),
              _NutrientInput(ctrl: _ironCtrl, label: 'حديد', color: Colors.brown),
              _NutrientInput(ctrl: _potassiumCtrl, label: 'بوتاسيوم', color: Colors.deepPurple),
              const SizedBox.shrink(),
            ]),
          ],
        ),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _addToLog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('حفظ في السجل', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.cardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ]),
        const SizedBox(height: 20),
        ...children,
      ]),
    );
  }

  Widget _buildNutritionGrid(List<Widget> items) {
    return Row(children: items.map((it) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: it))).toList());
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
      labelStyle: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary),
      filled: true, fillColor: AppColors.background,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}

class _NutrientInput extends StatelessWidget {
  const _NutrientInput({required this.ctrl, required this.label, required this.color});
  final TextEditingController ctrl;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: color.withValues(alpha: 0.2))),
        ),
      ),
      const SizedBox(height: 6),
      Text(label, style: GoogleFonts.cairo(fontSize: 9, color: AppColors.textSecondary), textAlign: TextAlign.center),
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
    );
  }
}

