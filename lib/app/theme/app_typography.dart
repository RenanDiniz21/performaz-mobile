import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Espelho do web:
///  - Display / Títulos / Logo  → Outfit (font-display)
///  - Body / Labels / Tabelas   → Inter  (font-sans)
///  - Mono                      → Roboto Mono (raramente)
abstract final class AppTypography {

  static TextTheme get textTheme => TextTheme(
    // ── DISPLAY (Outfit) ─────────────────────────────────────────────
    displayLarge:  GoogleFonts.outfit(fontSize: 57, fontWeight: FontWeight.w700, letterSpacing: -1.5),
    displayMedium: GoogleFonts.outfit(fontSize: 45, fontWeight: FontWeight.w700, letterSpacing: -1.0),
    displaySmall:  GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w600, letterSpacing: -0.5),

    // ── HEADLINE (Outfit) ─────────────────────────────────────────────
    headlineLarge:  GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w700),
    headlineMedium: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w600),
    headlineSmall:  GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600),

    // ── TITLE (Outfit — cards, seções) ───────────────────────────────
    titleLarge:  GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w600),
    titleMedium: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.1),
    titleSmall:  GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),

    // ── BODY (Inter — texto corrido, parágrafos) ──────────────────────
    bodyLarge:   GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.15),
    bodyMedium:  GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25),
    bodySmall:   GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4),

    // ── LABEL (Inter — badges, chips, labels de campo) ───────────────
    labelLarge:  GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
    labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
    labelSmall:  GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
  );

  // ── Helpers estáticos para uso direto ────────────────────────────────
  static TextStyle display(double size) =>
      GoogleFonts.outfit(fontSize: size, fontWeight: FontWeight.w700);

  static TextStyle title(double size, {FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.outfit(fontSize: size, fontWeight: weight);

  static TextStyle body(double size, {FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight);

  static TextStyle mono(double size) =>
      GoogleFonts.robotoMono(fontSize: size, fontWeight: FontWeight.w400);

  /// Número de XP, métricas de dashboard — Outfit bold
  static TextStyle metric(double size) =>
      GoogleFonts.outfit(fontSize: size, fontWeight: FontWeight.w700, letterSpacing: -0.5);

  // ── ALIASES DE COMPATIBILIDADE ──────────────────────────────────────
  // Esses getters mantêm retrocompatibilidade com telas não migradas.
  static TextStyle get displayLarge  => display(36);
  static TextStyle get displayMedium => display(28);
  static TextStyle get displaySmall  => title(22);
  static TextStyle get bodyLarge     => body(16);
  static TextStyle get bodyMedium    => body(14);
  static TextStyle get bodySmall     => body(12);
  static TextStyle get label         => body(12, weight: FontWeight.w500);
  static TextStyle get button        => body(15, weight: FontWeight.w600);
  static TextStyle get statNumber    => metric(28);
}
