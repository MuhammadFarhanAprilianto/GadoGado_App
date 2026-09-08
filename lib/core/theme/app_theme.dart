import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Agrandir',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.background,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: TextTheme(
        // Headings using Questrial
        displayLarge: GoogleFonts.questrial(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textMain,
        ),
        displayMedium: GoogleFonts.questrial(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textMain,
        ),
        displaySmall: GoogleFonts.questrial(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textMain,
        ),
        headlineLarge: GoogleFonts.questrial(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textMain,
        ),
        headlineMedium: GoogleFonts.questrial(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textMain,
        ),
        headlineSmall: GoogleFonts.questrial(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textMain,
        ),
        titleLarge: GoogleFonts.questrial(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textMain,
        ),
        titleMedium: GoogleFonts.questrial(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textMain,
        ),
        titleSmall: GoogleFonts.questrial(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textMain,
        ),

        // Body / Paragraphs using Agrandir
        bodyLarge: const TextStyle(
          fontFamily: 'Agrandir',
          fontSize: 16,
          color: AppColors.textMain,
        ),
        bodyMedium: const TextStyle(
          fontFamily: 'Agrandir',
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        bodySmall: const TextStyle(
          fontFamily: 'Agrandir',
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
        labelLarge: const TextStyle(
          fontFamily: 'Agrandir',
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textMain,
        ),
        labelMedium: const TextStyle(
          fontFamily: 'Agrandir',
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
        labelSmall: const TextStyle(
          fontFamily: 'Agrandir',
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textMain),
        titleTextStyle: GoogleFonts.questrial(
          color: AppColors.textMain,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        color: AppColors.surface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.questrial(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
