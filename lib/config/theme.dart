import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2563EB); // 신뢰감 있는 블루
  static const primaryDark = Color(0xFF1D4ED8);
  static const accent = Color(0xFF3B82F6);
  static const background = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textTertiary = Color(0xFF94A3B8);
  static const border = Color(0xFFE2E8F0);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const caution = Color(0xFFEF4444);
  static const earlybird = Color(0xFFFF6B35); // 얼리버드 강조색
}

class AppTheme {
  static ThemeData get light => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Pretendard',
        useMaterial3: true,
      );
}
