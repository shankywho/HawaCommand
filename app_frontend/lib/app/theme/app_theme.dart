import 'package:flutter/material.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/app/theme/tokens.dart';
import 'package:hawa_app/app/theme/typography.dart';

/// ThemeData builders: light, dark and outdoor (high contrast). Material 3 colour scheme built
/// from the tokens (no auto-generated seed palette; ARCHITECTURE §15).
abstract final class AppTheme {
  static ThemeData light({required bool hindi, bool cvd = false}) =>
      _build(HawaColors.light.copyWith(cvdPalette: cvd), Brightness.light, hindi: hindi);

  static ThemeData dark({required bool hindi, bool cvd = false}) =>
      _build(HawaColors.dark.copyWith(cvdPalette: cvd), Brightness.dark, hindi: hindi);

  /// White surface, ink text, 2 dp ink borders, no shadows; base body 18 sp.
  static ThemeData outdoor({required bool hindi, bool cvd = false}) => _build(
    HawaColors.outdoorMode.copyWith(cvdPalette: cvd),
    Brightness.light,
    hindi: hindi,
    scale: 1.1,
  );

  static ThemeData _build(
    HawaColors c,
    Brightness brightness, {
    required bool hindi,
    double scale = 1,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.brand,
      onPrimary: c.onBrand,
      secondary: c.info,
      onSecondary: c.onInfo,
      error: c.danger,
      onError: c.onDanger,
      surface: c.surface,
      onSurface: c.foreground,
      surfaceContainerHighest: c.muted,
      surfaceContainerLowest: c.surfaceElevated,
      surfaceContainerLow: c.surfaceElevated,
      surfaceContainer: c.surfaceElevated,
      surfaceContainerHigh: c.muted,
      onSurfaceVariant: c.mutedForeground,
      outline: c.input,
      outlineVariant: c.border,
      tertiary: c.simulated,
      onTertiary: c.onSimulated,
    );
    final text = HawaTypography.textTheme(
      color: c.foreground,
      muted: c.mutedForeground,
      hindi: hindi,
      scale: scale,
    );
    final side = BorderSide(color: c.outdoor ? c.ink : c.border, width: c.borderWidth);
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(HawaTokens.radiusMd),
      side: c.outdoor ? BorderSide(color: c.ink, width: 2) : BorderSide.none,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.surface,
      canvasColor: c.surface,
      fontFamily: HawaTypography.family,
      fontFamilyFallback: HawaTypography.fallback,
      textTheme: text,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      extensions: [c],
      dividerTheme: DividerThemeData(
        color: c.outdoor ? c.ink : c.border,
        thickness: c.borderWidth,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.surfaceElevated,
        foregroundColor: c.foreground,
        elevation: 0,
        scrolledUnderElevation: c.outdoor ? 0 : 1,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        shape: Border(bottom: side),
      ),
      cardTheme: CardThemeData(
        color: c.surfaceElevated,
        elevation: c.outdoor ? 0 : 1,
        shadowColor: const Color(0x1A0B1220),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HawaTokens.radiusLg),
          side: side,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, HawaTokens.buttonHeight),
          backgroundColor: c.brand,
          foregroundColor: c.onBrand,
          disabledBackgroundColor: c.muted,
          disabledForegroundColor: c.mutedForeground,
          textStyle: text.labelLarge,
          shape: buttonShape,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, HawaTokens.buttonHeight),
          foregroundColor: c.foreground,
          side: BorderSide(color: c.outdoor ? c.ink : c.input, width: c.outdoor ? 2 : 1),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HawaTokens.radiusMd)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: c.brandText,
          textStyle: text.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HawaTokens.radiusMd),
          borderSide: BorderSide(color: c.input),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HawaTokens.radiusMd),
          borderSide: BorderSide(color: c.outdoor ? c.ink : c.input, width: c.outdoor ? 2 : 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HawaTokens.radiusMd),
          borderSide: BorderSide(color: c.brand, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HawaTokens.radiusSm),
          side: side,
        ),
        labelStyle: text.labelMedium,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surfaceElevated,
        indicatorColor: c.brand.withValues(alpha: 0.16),
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium?.copyWith(fontSize: 13)),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? c.brandText : c.foreground,
            size: 26,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surfaceElevated,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(HawaTokens.radiusXl)),
        ),
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HawaTokens.radiusXl)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.ink,
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: 10,
        iconColor: c.foreground,
        textColor: c.foreground,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.onBrand : c.input,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.brand : c.muted,
        ),
      ),
    );
  }
}
