import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import '../models/food_entry.dart';
import '../theme/app_colors.dart';
import '../utils/app_notifications.dart';

class ShareService {
  static final ScreenshotController screenshotController = ScreenshotController();

  static Future<void> shareFoodMacros(BuildContext context, FoodEntry entry) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('مشاركة الماكروز', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            _ShareOption(
              icon: Icons.share_rounded,
              color: AppColors.primary,
              label: 'مشاركة عبر التطبيقات',
              subtitle: 'واتساب، تويتر، وغيرها',
              onTap: () {
                Navigator.pop(ctx);
                _shareToApps(context, entry);
              },
            ),
            const SizedBox(height: 8),
            _ShareOption(
              icon: Icons.save_alt_rounded,
              color: AppColors.teal,
              label: 'حفظ في الصور',
              subtitle: 'حفظ كصورة في معرض الصور',
              onTap: () {
                Navigator.pop(ctx);
                _saveToGallery(context, entry);
              },
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  static Future<Uint8List> _captureImage(BuildContext context, FoodEntry entry) async {
    return await screenshotController.captureFromWidget(
      _buildShareCard(entry),
      delay: const Duration(milliseconds: 100),
      context: context,
    );
  }

  static Future<void> _shareToApps(BuildContext context, FoodEntry entry) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)));
    try {
      final image = await _captureImage(context, entry);
      if (context.mounted) Navigator.pop(context);

      final fileName = 'macros_${DateTime.now().millisecondsSinceEpoch}.png';
      if (kIsWeb) {
        // ignore: deprecated_member_use
        await Share.shareXFiles([XFile.fromData(image, name: fileName, mimeType: 'image/png')], text: 'ماكروز وجبتي: ${entry.name} 🥗');
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(image);
        // ignore: deprecated_member_use
        await Share.shareXFiles([XFile(file.path)], text: 'ماكروز وجبتي: ${entry.name} 🥗');
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      debugPrint('Error sharing: $e');
    }
  }

  static Future<void> _saveToGallery(BuildContext context, FoodEntry entry) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.teal)));
    try {
      final image = await _captureImage(context, entry);
      if (context.mounted) Navigator.pop(context);

      final result = await ImageGallerySaverPlus.saveImage(image, quality: 100, name: 'macros_${DateTime.now().millisecondsSinceEpoch}');
      if (context.mounted) {
        final success = result['isSuccess'] == true;
        AppNotifications.showTop(context, success ? 'تم حفظ الصورة في المعرض' : 'فشل حفظ الصورة', isError: !success);
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      debugPrint('Error saving to gallery: $e');
      if (context.mounted) {
        AppNotifications.showTop(context, 'فشل حفظ الصورة');
      }
    }
  }


  static Widget _buildShareCard(FoodEntry entry) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A35), Color(0xFF0F0F1E)],
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CALORIE AI',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary.withValues(alpha: 0.8),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.name,
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  MealType.label(entry.mealType),
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          
          // Calories Circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  entry.calories.round().toString(),
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'KCAL',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Macros Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroItem('بروتين', '${entry.protein.round()}g', AppColors.protein),
              _buildMacroItem('كارب', '${entry.carbs.round()}g', AppColors.carbs),
              _buildMacroItem('دهون', '${entry.fat.round()}g', AppColors.fat),
            ],
          ),
          
          const SizedBox(height: 40),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          Text(
            'تتبع طعامك بذكاء مع Calorie AI 🚀',
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildMacroItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 1),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ShareOption extends StatelessWidget {
  const _ShareOption({required this.icon, required this.color, required this.label, required this.subtitle, required this.onTap});
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
