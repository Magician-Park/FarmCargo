import 'package:flutter/material.dart';

/// 앱 전역 색상. 화면에서 0xFF... 값을 직접 쓰지 않고 여기서 가져다 쓴다.
abstract final class AppColors {
  // 브랜드 초록(사용자 결정 2026-11-12, 사용자가 준 초록 색상표에서 고름).
  static const primary = Color(0xFF0A7455); // Greasy Greens
  static const primarySoft = Color(0xFFE6F6EF); // 연한 바탕(색상표의 밝은 민트를 더 옅게)
  static const primaryDark = Color(0xFF076646); // Spruce
  static const primaryLight = Color(0xFF19B080); // Mountain Meadow
  static const primaryDeep = Color(0xFF02412A); // Lost in the Woods(머리 영역 배경)
  static const accentMint = Color(0xFF7DD0B2); // Puppeteers(보조 강조)

  static const success = Color(0xFF15803D);
  static const successSoft = Color(0xFFF0FDF4);
  static const successText = Color(0xFF16A34A);

  static const warning = Color(0xFFB45309);
  static const warningText = Color(0xFF92400E);
  static const warningSoft = Color(0xFFFEF3C7);
  static const warningBg = Color(0xFFFFFBEB);
  static const warningBorder = Color(0xFFFCD34D);

  static const background = Color(0xFFF4F8F6); // 초록빛이 아주 살짝 도는 밝은 회색
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
        // 시드가 만드는 파랑은 브랜드 파랑과 달라 보이므로 주 색만 브랜드 색으로 고정한다.
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary)
            .copyWith(primary: AppColors.primary, onPrimary: Colors.white),
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
