import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_logo.dart';
import 'profile_setup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF13132B), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                const AppLogo()
                    .animate()
                    .scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 20),
                Text('My Calorie', style: GoogleFonts.cairo(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white))
                    .animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0),
                const SizedBox(height: 8),
                Text(
                  'تتبع سعراتك وماءك بذكاء\nاحسب احتياجك اليومي بدقة',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
                ).animate().fadeIn(delay: 600.ms),
                const Spacer(flex: 2),
                const _FeatureRow(icon: Icons.local_fire_department_rounded, color: AppColors.coral,  text: 'حساب السعرات الحرارية'),
                const SizedBox(height: 10),
                const _FeatureRow(icon: Icons.water_drop_rounded,            color: AppColors.water,  text: 'تتبع شرب الماء اليومي'),
                const SizedBox(height: 10),
                const _FeatureRow(icon: Icons.bar_chart_rounded,             color: AppColors.teal,   text: 'تحليل التقدم الأسبوعي'),
                const SizedBox(height: 10),
                const _FeatureRow(icon: Icons.restaurant_menu_rounded,       color: AppColors.gold,   text: 'سجل الوجبات بسهولة'),
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 6))],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context, 
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const ProfileSetupScreen(),
                          transitionsBuilder: (_, anim, __, child) => FadeTransition(
                            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
                            child: SlideTransition(
                              position: anim.drive(Tween(begin: const Offset(0, 0.05), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic))),
                              child: child,
                            ),
                          ),
                          transitionDuration: const Duration(milliseconds: 500),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('ابدأ رحلتك 🚀',
                          style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.3, end: 0),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color    color;
  final String   text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Text(text, style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.2, end: 0);
  }
}
