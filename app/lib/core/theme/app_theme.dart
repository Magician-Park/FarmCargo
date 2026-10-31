import 'package:flutter/material.dart';

/// 앱 전역 색상. 화면에서 0xFF... 값을 직접 쓰지 않고 여기서 가져다 쓴다.
abstract final class AppColors {
  static const primary = Color(0xFF2563EB);
  static const primarySoft = Color(0xFFEFF6FF);
  static const primaryDark = Color(0xFF1E40AF);
  static const primaryLight = Color(0xFF3B82F6);

  static const success = Color(0xFF15803D);
  static const successSoft = Color(0xFFF0FDF4);
  static const successText = Color(0xFF16A34A);

  static const warning = Color(0xFFB45309);
  static const warningText = Color(0xFF92400E);
  static const warningSoft = Color(0xFFFEF3C7);
  static const warningBg = Color(0xFFFFFBEB);
  static const warningBorder = Color(0xFFFCD34D);

  static const background = Color(0xFFF9FAFB);
  static const surfaceMuted = Color(0xFFF3F4F6);
  static const border = Color(0xFFE5E7EB);
  static const borderStrong = Color(0xFFD1D5DB);

  static const textStrong = Color(0xFF1F2937);
  static const textMuted = Color(0xFF6B7280);
  static const textChip = Color(0xFF4B5563);

  static const kakaoYellow = Color(0xFFFEE500);
  static const kakaoText = Color(0xFF191919);
}

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: _inputBorder(AppColors.border),
          enabledBorder: _inputBorder(AppColors.border),
          focusedBorder: _inputBorder(AppColors.primary, width: 2),
          errorBorder: _inputBorder(Colors.red),
          focusedErrorBorder: _inputBorder(Colors.red, width: 2),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
}
