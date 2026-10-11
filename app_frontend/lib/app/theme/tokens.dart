import 'package:flutter/painting.dart';

/// Colour, radius and spacing tokens mirrored by hand from the web console theme (frontend/tailwind.config.ts)
/// (§2.1, §2.2, §6). If that file changes, update this one in the same PR.
abstract final class HawaTokens {
  // Brand and semantic (DESIGN_SYSTEM §2.1).
  static const brand = Color(0xFF0E7C66);
  static const brandFgDark = Color(0xFF2BB597);
  static const warning = Color(0xFFF59E0B);
  static const warningFg = Color(0xFFB45309);
  static const danger = Color(0xFFDC2626);
  static const dangerFgDark = Color(0xFFF87171);
  static const info = Color(0xFF2563EB);
  static const infoFgDark = Color(0xFF60A5FA);
  static const simulated = Color(0xFF7C3AED);
  static const simulatedFgDark = Color(0xFFA78BFA);
  static const ink = Color(0xFF0B1220);
  static const white = Color(0xFFFFFFFF);

  // Light neutrals (§2.2).
  static const surface = Color(0xFFF8FAFC);
  static const surfaceElevated = Color(0xFFFFFFFF);
  static const Color foreground = ink;
  static const mutedForeground = Color(0xFF475569);
  static const muted = Color(0xFFF1F5F9);
  static const border = Color(0xFFE2E8F0);
  static const input = Color(0xFF64748B);

  // Dark neutrals (§2.2).
  static const surfaceDark = Color(0xFF0B1220);
  static const surfaceElevatedDark = Color(0xFF111A2E);
  static const surfaceOverlayDark = Color(0xFF18233B);
  static const foregroundDark = Color(0xFFE2E8F0);
  static const mutedForegroundDark = Color(0xFF94A3B8);
  static const mutedDark = Color(0xFF1A2540);
  static const borderDark = Color(0xFF24314D);

  /// Blue-grey offline banner (SCREENS §0.1); slate-700 with white text (10.4:1).
  static const offline = Color(0xFF334155);

  // Radius (§6): chips 4, buttons 6, cards 8, dialogs 12.
  static const radiusSm = 4.0;
  static const radiusMd = 6.0;
  static const radiusLg = 8.0;
  static const radiusXl = 12.0;

  // Spacing.
  static const gutter = 16.0;
  static const gap = 8.0;
  static const section = 24.0;

  /// Primary buttons: 64 dp in driver/inspector shells, 48 dp elsewhere (ARCHITECTURE §15).
  static const fieldButtonHeight = 64.0;
  static const buttonHeight = 48.0;
}
