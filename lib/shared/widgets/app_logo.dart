import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showShadow;
  const AppLogo({super.key, this.size = 110, this.showShadow = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.27),
        boxShadow: showShadow ? [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4), 
            blurRadius: size * 0.27, 
            spreadRadius: size * 0.045
          ),
        ] : null,
      ),
      child: Icon(
        Icons.local_fire_department_rounded, 
        size: size * 0.55, 
        color: Colors.white
      ),
    );
  }
}

class CalorieIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const CalorieIcon({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.local_fire_department_rounded, 
      size: size, 
      color: color ?? AppColors.coral
    );
  }
}

class WaterIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const WaterIcon({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.water_drop_rounded, 
      size: size, 
      color: color ?? AppColors.water
    );
  }
}

