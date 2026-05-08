import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const Color background = Color(0xFF0D0D1A);
  static const Color surface    = Color(0xFF1A1A2E);
  static const Color card       = Color(0xFF16213E);
  static const Color cardBorder = Color(0xFF2A2A4A);

  static const Color primary      = Color(0xFF3B82F6); // Medium Blue
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark  = Color(0xFF2563EB);

  static const Color accent       = Color(0xFF93C5FD);

  static const Color teal       = Color(0xFF2DD4BF);
  static const Color coral      = Color(0xFFFF5722);
  static const Color gold       = Color(0xFFFBBF24);
  static const Color green      = Color(0xFF34D399);
  static const Color water      = Color(0xFF38BDF8);
  static const Color waterLight = Color(0xFF7DD3FC);
  static const Color waterDark  = Color(0xFF0284C7);

  static const Color textPrimary   = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textHint      = Color(0xFF64748B);

  static const Color protein = Color(0xFFFF5722);
  static const Color carbs   = Color(0xFF38BDF8);
  static const Color fat     = Color(0xFFFBBF24);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient waterGradient = LinearGradient(
    colors: [Color(0xFF38BDF8), Color(0xFF3B82F6)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E1E32), Color(0xFF161626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
