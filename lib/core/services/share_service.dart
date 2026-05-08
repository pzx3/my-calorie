import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../models/food_entry.dart';
import '../theme/app_colors.dart';

class ShareService {
  static final ScreenshotController screenshotController = ScreenshotController();

  static Future<void> shareFoodMacros(BuildContext context, FoodEntry entry) async {
    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    try {
      final image = await screenshotController.captureFromWidget(
        _buildShareCard(entry),
        delay: const Duration(milliseconds: 100),
        context: context,
      );

      // Hide loading
      if (context.mounted) Navigator.pop(context);

      final fileName = 'food_macros_${DateTime.now().millisecondsSinceEpoch}.png';

      if (kIsWeb) {
        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile.fromData(image, name: fileName, mimeType: 'image/png')],
          text: 'ماكروز وجبتي: ${entry.name} 🥗',
        );
      } else {
        final directory = await getTemporaryDirectory();
        final imageFile = File('${directory.path}/$fileName');
        await imageFile.writeAsBytes(image);

        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(imageFile.path)],
          text: 'ماكروز وجبتي: ${entry.name} 🥗',
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      debugPrint('Error sharing image: $e');
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
