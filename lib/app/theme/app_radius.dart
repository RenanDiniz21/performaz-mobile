import 'package:flutter/material.dart';

/// Escala "soft SaaS" — espelho exato do web (--radius: 0.75rem base)
/// Convertido para pixels (1rem = 16px)
abstract final class AppRadius {
  static const double xs   = 7.0;   // rounded-sm   = 0.45rem
  static const double sm   = 9.6;   // rounded-md   = 0.6rem
  static const double md   = 12.0;  // rounded-lg   = 0.75rem (base)
  static const double lg   = 16.8;  // rounded-xl   = 1.05rem
  static const double xl   = 21.6;  // rounded-2xl  = 1.35rem
  static const double xl2  = 26.4;  // rounded-3xl  = 1.65rem
  static const double xl3  = 31.2;  // rounded-4xl  = 1.95rem
  static const double full = 999.0; // pill

  // ── ALIASES DE COMPATIBILIDADE ──────────────────────────────────
  static BorderRadius get smBorder  => BorderRadius.circular(sm);
  static BorderRadius get mdBorder  => BorderRadius.circular(md);
  static BorderRadius get lgBorder  => BorderRadius.circular(lg);
  static BorderRadius get xlBorder  => BorderRadius.circular(xl);
  static BorderRadius get xl2Border => BorderRadius.circular(xl2);
}
