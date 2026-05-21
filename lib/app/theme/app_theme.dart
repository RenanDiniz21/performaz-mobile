import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_radius.dart';

abstract final class AppTheme {

  // ─── DARK (padrão do app) ──────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary:          AppColors.primaryDark,
      onPrimary:        AppColors.foregroundLight,
      primaryContainer: AppColors.accentDark,
      secondary:        Color(0xFF8B5CF6),       // roxo
      onSecondary:      AppColors.foregroundLight,
      surface:          AppColors.cardDark,
      onSurface:        AppColors.foregroundDark,
      surfaceContainerHighest: AppColors.mutedDark,
      error:            AppColors.destructiveDark,
      outline:          AppColors.borderDark,
    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,
    textTheme: AppTypography.textTheme,
    cardTheme: CardThemeData(
      color: AppColors.cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg), // 12px
        side: const BorderSide(color: AppColors.borderDark, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.sidebarBg,
      indicatorColor: AppColors.primaryDark.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.all(
        GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.sidebarFg),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
        color: states.contains(WidgetState.selected)
            ? AppColors.primaryDark
            : AppColors.mutedForegroundDark,
        size: 22,
      )),
      height: 64,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundDark.withValues(alpha: 0.8),
      foregroundColor: AppColors.foregroundDark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.foregroundDark,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.mutedDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
      ),
      labelStyle: GoogleFonts.inter(color: AppColors.mutedForegroundDark),
      hintStyle: GoogleFonts.inter(color: AppColors.mutedForegroundDark.withValues(alpha: 0.6)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        side: const BorderSide(color: AppColors.borderDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.mutedDark,
      selectedColor: AppColors.primaryDark.withValues(alpha: 0.25),
      labelStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500),
      side: const BorderSide(color: AppColors.borderDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.borderDark, thickness: 1, space: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primaryDark),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.cardDark,
      contentTextStyle: GoogleFonts.inter(color: AppColors.foregroundDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      behavior: SnackBarBehavior.floating,
    ),
  );

  // ─── LIGHT ────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary:          AppColors.primaryLight,
      onPrimary:        Colors.white,
      primaryContainer: AppColors.accentLight,
      secondary:        Color(0xFF7C3AED),
      onSecondary:      Colors.white,
      surface:          AppColors.cardLight,
      onSurface:        AppColors.foregroundLight,
      surfaceContainerHighest: AppColors.mutedLight,
      error:            AppColors.destructive,
      outline:          AppColors.borderLight,
    ),
    scaffoldBackgroundColor: AppColors.backgroundLight,
    textTheme: AppTypography.textTheme,
    cardTheme: CardThemeData(
      color: AppColors.cardLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.borderLight, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.backgroundLight,
      indicatorColor: AppColors.primaryLight.withValues(alpha: 0.1),
      labelTextStyle: WidgetStateProperty.all(
        GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      height: 64,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundLight.withValues(alpha: 0.8),
      foregroundColor: AppColors.foregroundLight,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.foregroundLight,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.mutedLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
      ),
      labelStyle: GoogleFonts.inter(color: AppColors.mutedForegroundLight),
      hintStyle: GoogleFonts.inter(color: AppColors.mutedForegroundLight.withValues(alpha: 0.6)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.borderLight, thickness: 1, space: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primaryLight),
  );
}