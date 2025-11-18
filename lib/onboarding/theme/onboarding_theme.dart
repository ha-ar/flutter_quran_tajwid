import 'package:flutter/material.dart';

class OnboardingColors {
  static const Color background = Color(0xFF0F0F0F);
  static const Color card = Color(0xFF2A2A2A);
  static const Color stroke = Color(0xFF3A3A3A);
  static const Color primary = Color(0xFFF97316); // orange
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB3B3B3);
}

ThemeData buildOnboardingTheme() {
  final base = ThemeData.dark();
  return base.copyWith(
    scaffoldBackgroundColor: OnboardingColors.background,
    colorScheme: base.colorScheme.copyWith(
      primary: OnboardingColors.primary,
      surface: OnboardingColors.card,
      background: OnboardingColors.background,
      onPrimary: Colors.white,
      onSurface: OnboardingColors.textPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: OnboardingColors.card,
      hintStyle: const TextStyle(color: OnboardingColors.textSecondary),
      labelStyle: const TextStyle(color: OnboardingColors.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: OnboardingColors.stroke),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: OnboardingColors.stroke),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: OnboardingColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: OnboardingColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
