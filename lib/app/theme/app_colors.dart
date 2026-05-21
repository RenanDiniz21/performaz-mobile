import 'package:flutter/material.dart';

/// Paleta Performaz — Indigo + Purple
/// Fonte: FRONTEND.md (globals.css) — conversão OKLCH → sRGB
abstract final class AppColors {
  // ── PRIMARY — Indigo ──────────────────────────────────────────────
  /// oklch(0.58 0.19 265) → azul-indigo médio (light mode)
  static const primaryLight = Color(0xFF4F62D4);
  /// oklch(0.68 0.18 265) → indigo claro (dark mode, texto sobre fundo escuro)
  static const primaryDark  = Color(0xFF7B8FE8);

  // ── ACCENT — Lilás/Roxo ───────────────────────────────────────────
  /// oklch(0.95 0.03 295) → lilás muito claro (hover/superfície light)
  static const accentLight  = Color(0xFFF0EEFF);
  /// oklch(0.25 0.05 295) → roxo escuro (hover/superfície dark)
  static const accentDark   = Color(0xFF2A2040);

  // ── BACKGROUND ────────────────────────────────────────────────────
  /// oklch(0.98 0 0) → quase branco
  static const backgroundLight = Color(0xFFFAFAFA);
  /// oklch(0.13 0.02 265) → azul-indigo muito escuro
  static const backgroundDark  = Color(0xFF151520);

  // ── FOREGROUND (texto principal) ──────────────────────────────────
  /// oklch(0.15 0.02 265) → quase preto azulado
  static const foregroundLight = Color(0xFF1A1B2E);
  /// oklch(0.95 0.005 264) → branco levemente azulado
  static const foregroundDark  = Color(0xFFF0F0F8);

  // ── CARD ──────────────────────────────────────────────────────────
  /// oklch(1 0 0) → branco puro
  static const cardLight = Color(0xFFFFFFFF);
  /// oklch(0.18 0.02 265) → indigo escuro, levemente mais claro que o bg
  static const cardDark  = Color(0xFF1E1F32);

  // ── MUTED (superfícies suaves / texto secundário) ─────────────────
  static const mutedLight           = Color(0xFFF4F4F8);
  static const mutedDark            = Color(0xFF252538);
  static const mutedForegroundLight = Color(0xFF6B7280);
  static const mutedForegroundDark  = Color(0xFF9A9AB0);

  // ── BORDER / DIVIDER ─────────────────────────────────────────────
  /// oklch(0.88 0.01 265) com alpha 30% → sutil
  static const borderLight = Color(0x33C5C7E0);
  /// oklch(1 0 0 / 10%) → borda quase invisível no dark
  static const borderDark  = Color(0x1AFFFFFF);

  // ── SIDEBAR ───────────────────────────────────────────────────────
  /// oklch(0.14 0.04 275) → indigo near-black (painel de navegação)
  static const sidebarBg       = Color(0xFF161824);
  /// oklch(0.20 0.05 275) → hover/active na sidebar
  static const sidebarAccent   = Color(0xFF20223A);
  /// oklch(0.24 0.05 275) → border da sidebar
  static const sidebarBorder   = Color(0xFF282B44);
  /// oklch(0.88 0.01 275) → texto da sidebar
  static const sidebarFg       = Color(0xFFDDDEF0);

  // ── DESTRUCTIVE ───────────────────────────────────────────────────
  /// oklch(0.577 0.245 27.3) → vermelho semântico (APENAS erros)
  static const destructive     = Color(0xFFDC2626);
  static const destructiveDark = Color(0xFFEF4444);

  // ── CHARTS ────────────────────────────────────────────────────────
  /// chart-1 a chart-5: indigo, roxo, azul, verde, âmbar
  static const chart1 = Color(0xFF4F62D4); // indigo
  static const chart2 = Color(0xFF8B5CF6); // roxo
  static const chart3 = Color(0xFF06B6D4); // ciano
  static const chart4 = Color(0xFF10B981); // verde
  static const chart5 = Color(0xFFF59E0B); // âmbar/XP

  // ── GAMIFICAÇÃO (XP / Conquistas) ─────────────────────────────────
  /// Âmbar/gold — usado exclusivamente para XP, conquistas e streaks
  static const xpGold     = Color(0xFFF59E0B);
  static const xpGoldDark = Color(0xFFFBBF24);

  // ── STATUS SEMÂNTICOS ─────────────────────────────────────────────
  static const statusSuccess = Color(0xFF10B981); // verde
  static const statusWarning = Color(0xFFF59E0B); // âmbar
  static const statusError   = Color(0xFFEF4444); // vermelho
  static const statusInfo    = Color(0xFF4F62D4); // indigo (= primary)

  // ── ALIASES DE COMPATIBILIDADE (dark-mode defaults) ───────────────
  // Esses aliases existem para manter retrocompatibilidade com telas
  // que ainda não foram migradas para o padrão theme-aware.
  static const primary        = primaryDark;
  static const background     = backgroundDark;
  static const foreground     = foregroundDark;
  static const card           = cardDark;
  static const muted          = mutedDark;
  static const mutedForeground = mutedForegroundDark;
  static const border         = borderDark;
  static const accent         = accentDark;
  static const success        = statusSuccess;
  static const highBg         = Color(0x26EF4444); // destructive 15%
  static const highFg         = statusError;
  static const successBg      = Color(0x2610B981); // success 15%
  static const activeGreen    = statusSuccess;
  static const sidebar        = sidebarBg;
  static const mediumBg       = Color(0x26F59E0B); // warning 15%
  static const mediumFg       = statusWarning;
  static const lowBg          = Color(0x2610B981); // success 15%
  static const lowFg          = statusSuccess;
  static const inactiveGray   = Color(0xFF6B7280); // gray-500
}
