import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography tokens — font, size, weight only.
/// Colors are intentionally omitted so styles adapt to the current theme.
/// Use `.copyWith(color: ...)` when you need an explicit color override.
class AppTypography {
  AppTypography._();

  // Outfit — titles, large numbers, stat cards
  static TextStyle displayLarge = GoogleFonts.outfit(
    fontSize: 32,
    fontWeight: FontWeight.w700,
  );

  static TextStyle displayMedium = GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  static TextStyle displaySmall = GoogleFonts.outfit(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static TextStyle statNumber = GoogleFonts.outfit(
    fontSize: 36,
    fontWeight: FontWeight.w800,
  );

  // Plus Jakarta Sans — body text, labels, table content
  static TextStyle bodyLarge = GoogleFonts.plusJakartaSans(
    fontSize: 16,
  );

  static TextStyle bodyMedium = GoogleFonts.plusJakartaSans(
    fontSize: 14,
  );

  static TextStyle bodySmall = GoogleFonts.plusJakartaSans(
    fontSize: 12,
  );

  static TextStyle label = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static TextStyle button = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
