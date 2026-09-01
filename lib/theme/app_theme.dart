import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF7C33FF); // hsl(260, 100%, 60%)
  static const Color background = Color(0xFF05050A);
  static const Color surface = Color(0xFF121018);
  static const Color mutedText = Color(0xFF9CA3AF);
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.primary,
      secondary: AppColors.primary,
      surface: AppColors.surface,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
    ),
  );
}
