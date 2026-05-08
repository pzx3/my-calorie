import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/state/app_state.dart';

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

    // Matching image colors exactly
    const Color carbColor = Color(0xFF2DD4BF); // Teal
    const Color fatColor = Color(0xFFA855F7); // Purple
    const Color proColor = Color(0xFFFBBF24); // Yellow/Orange

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Screenshot(
            controller: _screenshotController,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: const Color(0xFF1E212A), // Very dark slate like the image
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  // Circular Segmented Indicator
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(80, 80),
                          painter: _SegmentedRingPainter(
                            pPct: pPct.toDouble(),
                            cPct: cPct.toDouble(),
                            fPct: fPct.toDouble(),
                            pColor: proColor,
                            cColor: carbColor,
                            fColor: fatColor,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$eaten', style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1)),
                            Text('cal', style: GoogleFonts.cairo(fontSize: 14, color: const Color(0xFF9CA3AF), height: 1.1)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Columns
                  _MacroCol(label: 'Carbs', grams: carbs, pct: cPct, color: carbColor),
                  const Spacer(),
                  _MacroCol(label: 'Fat', grams: fat, pct: fPct, color: fatColor),
                  const Spacer(),
                  _MacroCol(label: 'Protein', grams: protein, pct: pPct, color: proColor),
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
        Text('$pct%', style: GoogleFonts.inter(fontSize: 14, color: color, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('${grams} g', style: GoogleFonts.inter(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9CA3AF))),
      ],
    );
  }
}

class _SegmentedRingPainter extends CustomPainter {
  final double pPct;
  final double cPct;
  final double fPct;
  final Color pColor;
  final Color cColor;
  final Color fColor;

  _SegmentedRingPainter({
    required this.pPct,
    required this.cPct,
    required this.fPct,
    required this.pColor,
    required this.cColor,
    required this.fColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final gap = 0.2; // Radians gap

    // Active segments count
    int activeCount = 0;
    if (cPct > 0) activeCount++;
    if (fPct > 0) activeCount++;
    if (pPct > 0) activeCount++;

    if (activeCount == 0) {
      paint.color = Colors.grey.withOpacity(0.2);
      canvas.drawCircle(center, radius, paint);
      return;
    }

    final totalGaps = (activeCount > 1) ? activeCount * gap : 0;
    final availableRadians = 2 * pi - totalGaps;

    double currentAngle = -pi / 2; // Start at top

    // Carbs
    if (cPct > 0) {
      paint.color = cColor;
      final sweep = (cPct / 100) * availableRadians;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), currentAngle, sweep, false, paint);
      currentAngle += sweep + gap;
    }

    // Fat
    if (fPct > 0) {
      paint.color = fColor;
      final sweep = (fPct / 100) * availableRadians;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), currentAngle, sweep, false, paint);
      currentAngle += sweep + gap;
    }

    // Protein
    if (pPct > 0) {
      paint.color = pColor;
      final sweep = (pPct / 100) * availableRadians;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), currentAngle, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
