import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Light mode ───────────────────────────────────────

  // Primary — Purple
  static const primary = Color(0xFF7C3AED);

  // Backgrounds (cool-tinted)
  static const background = Color(0xFFF8F7FC);
  static const card = Color(0xFFFFFFFF);

  // Text
  static const foreground = Color(0xFF1A1625);
  static const mutedForeground = Color(0xFF6B6780);

  // Borders & Surfaces (cool-tinted)
  static const border = Color(0xFFE4E2EE);
  static const muted = Color(0xFFF3F2F8);
  static const accent = Color(0xFFF0EDFF);

  // Sidebar (dark, purple-tinted)
  static const sidebar = Color(0xFF1A1628);
  static const sidebarForeground = Color(0xFFD4D0E8);
  static const sidebarAccent = Color(0xFF2A2540);
  static const sidebarBorder = Color(0xFF3D3658);

  // ─── Dark mode ────────────────────────────────────────

  static const darkPrimary = Color(0xFFA78BFA);

  static const darkBackground = Color(0xFF1A1628);
  static const darkCard = Color(0xFF241F38);

  static const darkForeground = Color(0xFFF0EDF8);
  static const darkMutedForeground = Color(0xFF9590A8);

  static const darkBorder = Color(0xFF342E4A);
  static const darkMuted = Color(0xFF2A2540);
  static const darkAccent = Color(0xFF322B4D);

  // ─── Shared (same in both modes) ──────────────────────

  // Chart palette (purple-blue spectrum)
  static const chart1 = Color(0xFF7C3AED);
  static const chart2 = Color(0xFF3B82F6);
  static const chart3 = Color(0xFF06B6D4);
  static const chart4 = Color(0xFFC026D3);
  static const chart5 = Color(0xFF14B8A6);

  // Dark mode chart palette (brighter for dark backgrounds)
  static const darkChart1 = Color(0xFFA78BFA);
  static const darkChart2 = Color(0xFF60A5FA);
  static const darkChart3 = Color(0xFF22D3EE);
  static const darkChart4 = Color(0xFFD946EF);
  static const darkChart5 = Color(0xFF2DD4BF);

  // Priority badge colors
  static const highBg = Color(0xFFFEE2E2);
  static const highFg = Color(0xFFDC2626);
  static const mediumBg = Color(0xFFFEF3C7);
  static const mediumFg = Color(0xFFD97706);
  static const lowBg = Color(0xFFDBEAFE);
  static const lowFg = Color(0xFF2563EB);

  // Dark priority badges
  static const darkHighBg = Color(0xFF3B1515);
  static const darkHighFg = Color(0xFFFCA5A5);
  static const darkMediumBg = Color(0xFF3B2E10);
  static const darkMediumFg = Color(0xFFFCD34D);
  static const darkLowBg = Color(0xFF152040);
  static const darkLowFg = Color(0xFF93C5FD);

  // Status dots
  static const activeGreen = Color(0xFF10B981);
  static const inactiveGray = Color(0xFFCBD5E1);

  // Dot grid
  static const dotGrid = Color(0xFFCDC9DA);
  static const darkDotGrid = Color(0xFF342E4A);

  // Destructive
  static const destructive = Color(0xFFEF4444);
  static const destructiveForeground = Color(0xFFFFFFFF);
  static const darkDestructive = Color(0xFFF87171);

  // Success
  static const success = Color(0xFF10B981);
  static const successBg = Color(0xFFD1FAE5);
  static const darkSuccessBg = Color(0xFF0D3B2B);

  // ─── Helper: resolve by brightness ────────────────────

  static Color resolve(
    BuildContext context, {
    required Color light,
    required Color dark,
  }) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}
