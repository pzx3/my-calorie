import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/state/app_state.dart';
import 'package:provider/provider.dart';

class MacroSharePreview extends StatefulWidget {
  const MacroSharePreview({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const MacroSharePreview(),
    );
  }

  @override
  State<MacroSharePreview> createState() => _MacroSharePreviewState();
}

class _MacroSharePreviewState extends State<MacroSharePreview> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  Future<void> _share() async {
    setState(() => _isSharing = true);
    try {
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/macro_share_${DateTime.now().millisecondsSinceEpoch}.png';
      
      final image = await _screenshotController.capture(delay: const Duration(milliseconds: 10));
      if (image != null) {
        final file = File(imagePath);
        await file.writeAsBytes(image);
        final params = ShareParams(
          text: 'نتائجي اليومية من Mycalorie 🚀',
          files: [XFile(imagePath)],
        );
        await SharePlus.instance.share(params);
      }
    } catch (e) {
      debugPrint('Error capturing screenshot: $e');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final eaten = state.totalCaloriesToday;
    final protein = state.proteinToday.round();
    final carbs = state.carbsToday.round();
    final fat = state.fatToday.round();
    
    final totalGrams = (protein + carbs + fat).clamp(1, double.infinity);
    final pPct = ((protein / totalGrams) * 100).round();
    final cPct = ((carbs / totalGrams) * 100).round();
    final fPct = ((fat / totalGrams) * 100).round();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Screenshot(
            controller: _screenshotController,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E212A), // Dark slate like the image
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Circular Indicator
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularPercentIndicator(
                            radius: 40,
                            lineWidth: 8,
                            percent: 1.0,
                            backgroundColor: Colors.transparent,
                            progressColor: AppColors.protein, // Using protein as main, but technically should be segmented
                            circularStrokeCap: CircularStrokeCap.round,
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$eaten', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1)),
                              Text('cal', style: GoogleFonts.cairo(fontSize: 12, color: const Color(0xFF9CA3AF), height: 1.1)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      // Columns
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _MacroCol(label: 'Carbs', grams: carbs, pct: cPct, color: AppColors.carbs),
                            _MacroCol(label: 'Fat', grams: fat, pct: fPct, color: AppColors.fat),
                            _MacroCol(label: 'Protein', grams: protein, pct: pPct, color: AppColors.protein),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Mycalorie', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white38)),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSharing ? null : _share,
              icon: _isSharing 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.ios_share_rounded),
              label: Text('مشاركة', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق', style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class _MacroCol extends StatelessWidget {
  const _MacroCol({required this.label, required this.grams, required this.pct, required this.color});
  final String label;
  final int grams, pct;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('$pct%', style: GoogleFonts.cairo(fontSize: 14, color: color, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('${grams}g', style: GoogleFonts.cairo(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.cairo(fontSize: 12, color: const Color(0xFF9CA3AF))),
      ],
    );
  }
}
