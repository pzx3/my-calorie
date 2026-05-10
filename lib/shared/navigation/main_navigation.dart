import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/food_log/screens/food_log_screen.dart';
import '../../features/water/screens/water_screen.dart';
import '../../features/progress/screens/progress_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        context.read<AppState>().refreshDay();
      }
    }
  }

  final List<Widget> _pages = const [
    HomeScreen(),
    FoodLogScreen(),
    WaterScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.cardBorder, width: 0.5)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_rounded,         label: 'الرئيسية', index: 0, current: _currentIndex, onTap: _onTap),
                _NavItem(icon: Icons.restaurant_rounded,   label: 'الطعام',   index: 1, current: _currentIndex, onTap: _onTap),
                _NavItem(icon: Icons.water_drop_rounded,   label: 'الماء',    index: 2, current: _currentIndex, onTap: _onTap),
                _NavItem(icon: Icons.bar_chart_rounded,    label: 'التقدم',   index: 3, current: _currentIndex, onTap: _onTap),
                _NavItem(icon: Icons.person_rounded,       label: 'ملفي',    index: 4, current: _currentIndex, onTap: _onTap),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(int index) => setState(() => _currentIndex = index);
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.index, required this.current, required this.onTap});
  final IconData icon;
  final String   label;
  final int      index, current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 26, color: isSelected ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.cairo(
            fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          )),
        ]),
      ),
    );
  }
}
