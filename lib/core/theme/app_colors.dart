import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFFF7A00); // Vibrant Orange
  static const Color primaryLight = Color(0xFFFFE0B2);
  static const Color primaryDark = Color(0xFFE65100);

  static const Color secondary = Color(0xFFFFB000); // Amber
  
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  
  static const Color textMain = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA000);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // Soft Backgrounds for cards (from design)
  static const Color cardPeach = Color(0xFFFFF3E0);
  static const Color cardGreen = Color(0xFFE8F5E9);
  static const Color cardRed = Color(0xFFFFEBEE);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF7A00), Color(0xFFFF9100)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
