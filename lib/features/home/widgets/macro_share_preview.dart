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
  const MacroSharePreview({
    super.key,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.title,
  });

  final int? calories;
  final int? protein;
  final int? carbs;
  final int? fat;
  final String? title;

  static void show(BuildContext context, {int? calories, int? protein, int? carbs, int? fat, String? title}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MacroSharePreview(
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        title: title,
      ),
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
        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(imagePath)],
          text: '${widget.title ?? "نتائجي اليومية"} من Mycalorie 🚀',
        );
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
    final eaten = widget.calories ?? state.totalCaloriesToday;
    final protein = widget.protein ?? state.proteinToday.round();
    final carbs = widget.carbs ?? state.carbsToday.round();
    final fat = widget.fat ?? state.fatToday.round();
    
    final totalGrams = (protein + carbs + fat).clamp(1, double.infinity);
    final pPct = ((protein / totalGrams) * 100).round();
    final cPct = ((carbs / totalGrams) * 100).round();
    final fPct = ((fat / totalGrams) * 100).round();

    const Color carbColor = Color(0xFF2DD4BF);
    const Color fatColor = Color(0xFFA855F7);
    const Color proColor = Color(0xFFFBBF24);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 14),
            Text(widget.title ?? 'معاينة المشاركة', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 14),
            // Preview Card
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Screenshot(
                controller: _screenshotController,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E212A),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(72, 72),
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
                                Text('$eaten', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1)),
                                Text('cal', style: GoogleFonts.cairo(fontSize: 12, color: const Color(0xFF9CA3AF), height: 1.1)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      _MacroCol(label: 'Carbs', grams: carbs, pct: cPct, color: carbColor),
                      const Spacer(),
                      _MacroCol(label: 'Fat', grams: fat, pct: fPct, color: fatColor),
                      const Spacer(),
                      _MacroCol(label: 'Protein', grams: protein, pct: pPct, color: proColor),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.cardBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: Text('إغلاق', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isSharing ? null : _share,
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: _isSharing
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'مشاركة النتيجة',
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
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
        Text('$pct%', style: GoogleFonts.inter(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text('$grams g', style: GoogleFonts.inter(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF9CA3AF))),
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
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    const gap = 0.2;

    int activeCount = 0;
    if (cPct > 0) activeCount++;
    if (fPct > 0) activeCount++;
    if (pPct > 0) activeCount++;

    if (activeCount == 0) {
      paint.color = Colors.grey.withValues(alpha: 0.2);
      canvas.drawCircle(center, radius, paint);
      return;
    }

    final totalGaps = (activeCount > 1) ? activeCount * gap : 0;
    final availableRadians = 2 * pi - totalGaps;

    double currentAngle = -pi / 2;

    if (cPct > 0) {
      paint.color = cColor;
      final sweep = (cPct / 100) * availableRadians;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), currentAngle, sweep, false, paint);
      currentAngle += sweep + gap;
    }

    if (fPct > 0) {
      paint.color = fColor;
      final sweep = (fPct / 100) * availableRadians;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), currentAngle, sweep, false, paint);
      currentAngle += sweep + gap;
    }

    if (pPct > 0) {
      paint.color = pColor;
      final sweep = (pPct / 100) * availableRadians;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), currentAngle, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
