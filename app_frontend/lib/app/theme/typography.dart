import 'package:flutter/material.dart';

/// Inter with Noto Sans Devanagari as fallback, so Latin digits and IDs stay in Inter inside
/// Hindi text (ARCHITECTURE §14). Hindi line heights follow DESIGN_SYSTEM §5 so matras don't clip;
/// no letter-spacing (it breaks Devanagari conjuncts) and weights stay ≥ 400.
abstract final class HawaTypography {
  static const family = 'Inter';
  static const fallback = ['NotoSansDevanagari'];

  static TextTheme textTheme({
    required Color color,
    required Color muted,
    required bool hindi,
    double scale = 1,
  }) {
    double lh(double en, double hi) => hindi ? hi : en;
    TextStyle s(double size, FontWeight weight, double height, {Color? c}) => TextStyle(
      fontFamily: family,
      fontFamilyFallback: fallback,
      fontSize: size * scale,
      fontWeight: weight,
      height: height,
      letterSpacing: 0,
      color: c ?? color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return TextTheme(
      displaySmall: s(30, FontWeight.w600, lh(1.2, 1.4)),
      headlineMedium: s(24, FontWeight.w600, lh(1.33, 1.45)),
      headlineSmall: s(22, FontWeight.w600, lh(1.3, 1.45)),
      titleLarge: s(20, FontWeight.w600, lh(1.4, 1.5)),
      titleMedium: s(18, FontWeight.w600, lh(1.4, 1.5)),
      titleSmall: s(16, FontWeight.w600, lh(1.4, 1.5)),
      bodyLarge: s(16, FontWeight.w400, lh(1.5, 1.65)),
      bodyMedium: s(15, FontWeight.w400, lh(1.45, 1.65)),
      bodySmall: s(14, FontWeight.w400, lh(1.43, 1.6), c: muted),
      labelLarge: s(16, FontWeight.w600, lh(1.25, 1.45)),
      labelMedium: s(14, FontWeight.w600, lh(1.3, 1.5)),
      labelSmall: s(13, FontWeight.w400, lh(1.3, 1.5), c: muted),
    );
  }
}
