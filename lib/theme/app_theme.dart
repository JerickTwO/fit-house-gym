import 'package:flutter/material.dart';

/// Paleta y tema oscuro minimalista compartido por toda la app.
class AppColors {
  AppColors._();

  static const background = Color(0xFF121212);
  static const card = Color(0xFF1E1E1E);
  static const cardAlt = Color(0xFF262626);
  static const textPrimary = Color(0xFFF5F5F5);
  static const textSecondary = Color(0xFF9CA3AF);
  static const activo = Color(0xFF22C55E);
  static const porVencer = Color(0xFFF59E0B);
  static const vencido = Color(0xFFEF4444);

  /// Color de marca de Fit House Gym.
  static const accent = Color(0xFFC0E90E);

  /// Texto/ícono sobre [accent]: el acento es muy claro, así que se usa
  /// un color oscuro encima para mantener el alto contraste pedido.
  static const onAccent = Color(0xFF121212);
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: base.colorScheme.copyWith(
      surface: AppColors.background,
      primary: AppColors.accent,
      secondary: AppColors.activo,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accent,
      foregroundColor: AppColors.onAccent,
      shape: StadiumBorder(),
      extendedTextStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardAlt,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: AppColors.textSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dividerColor: const Color(0xFF2A2A2A),
  );
}
