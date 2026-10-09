import 'package:flutter/material.dart';
import 'package:hawa_app/app/theme/tokens.dart';

/// Semantic colours for widgets, resolved per mode (light, dark, outdoor).
///
/// Fill colours (`brand`, `danger`, `info`, `simulated`) are never used as text in dark mode;
/// use the `*Text` members, which switch to the derived `*-fg-dark` values (DESIGN_SYSTEM §3).
@immutable
class HawaColors extends ThemeExtension<HawaColors> {
  const HawaColors({
    required this.brand,
    required this.brandText,
    required this.onBrand,
    required this.warning,
    required this.warningText,
    required this.onWarning,
    required this.danger,
    required this.dangerText,
    required this.onDanger,
    required this.info,
    required this.infoText,
    required this.onInfo,
    required this.simulated,
    required this.simulatedText,
    required this.onSimulated,
    required this.ink,
    required this.surface,
    required this.surfaceElevated,
    required this.foreground,
    required this.mutedForeground,
    required this.muted,
    required this.border,
    required this.input,
    required this.offline,
    required this.onOffline,
    required this.outdoor,
    required this.cvdPalette,
  });

  static const light = HawaColors(
    brand: HawaTokens.brand,
    brandText: HawaTokens.brand,
    onBrand: HawaTokens.white,
    warning: HawaTokens.warning,
    warningText: HawaTokens.warningFg,
    onWarning: HawaTokens.ink,
    danger: HawaTokens.danger,
    dangerText: HawaTokens.danger,
    onDanger: HawaTokens.white,
    info: HawaTokens.info,
    infoText: HawaTokens.info,
    onInfo: HawaTokens.white,
    simulated: HawaTokens.simulated,
    simulatedText: HawaTokens.simulated,
    onSimulated: HawaTokens.white,
    ink: HawaTokens.ink,
    surface: HawaTokens.surface,
    surfaceElevated: HawaTokens.surfaceElevated,
    foreground: HawaTokens.foreground,
    mutedForeground: HawaTokens.mutedForeground,
    muted: HawaTokens.muted,
    border: HawaTokens.border,
    input: HawaTokens.input,
    offline: HawaTokens.offline,
    onOffline: HawaTokens.white,
    outdoor: false,
    cvdPalette: false,
  );

  static const dark = HawaColors(
    brand: HawaTokens.brand,
    brandText: HawaTokens.brandFgDark,
    onBrand: HawaTokens.white,
    warning: HawaTokens.warning,
    warningText: HawaTokens.warning,
    onWarning: HawaTokens.ink,
    danger: HawaTokens.danger,
    dangerText: HawaTokens.dangerFgDark,
    onDanger: HawaTokens.white,
    info: HawaTokens.info,
    infoText: HawaTokens.infoFgDark,
    onInfo: HawaTokens.white,
    simulated: HawaTokens.simulated,
    simulatedText: HawaTokens.simulatedFgDark,
    onSimulated: HawaTokens.white,
    ink: HawaTokens.ink,
    surface: HawaTokens.surfaceDark,
    surfaceElevated: HawaTokens.surfaceElevatedDark,
    foreground: HawaTokens.foregroundDark,
    mutedForeground: HawaTokens.mutedForegroundDark,
    muted: HawaTokens.mutedDark,
    border: HawaTokens.borderDark,
    input: HawaTokens.input,
    offline: HawaTokens.surfaceOverlayDark,
    onOffline: HawaTokens.foregroundDark,
    outdoor: false,
    cvdPalette: false,
  );

  /// High contrast: white surface, ink text and 2 dp ink borders (ARCHITECTURE §15).
  static const outdoorMode = HawaColors(
    brand: HawaTokens.brand,
    brandText: HawaTokens.brand,
    onBrand: HawaTokens.white,
    warning: HawaTokens.warning,
    warningText: HawaTokens.warningFg,
    onWarning: HawaTokens.ink,
    danger: HawaTokens.danger,
    dangerText: HawaTokens.danger,
    onDanger: HawaTokens.white,
    info: HawaTokens.info,
    infoText: HawaTokens.info,
    onInfo: HawaTokens.white,
    simulated: HawaTokens.simulated,
    simulatedText: HawaTokens.simulated,
    onSimulated: HawaTokens.white,
    ink: HawaTokens.ink,
    surface: HawaTokens.white,
    surfaceElevated: HawaTokens.white,
    foreground: HawaTokens.ink,
    mutedForeground: Color(0xFF334155),
    muted: HawaTokens.muted,
    border: HawaTokens.ink,
    input: HawaTokens.ink,
    offline: HawaTokens.offline,
    onOffline: HawaTokens.white,
    outdoor: true,
    cvdPalette: false,
  );

  final Color brand;
  final Color brandText;
  final Color onBrand;
  final Color warning;
  final Color warningText;
  final Color onWarning;
  final Color danger;
  final Color dangerText;
  final Color onDanger;
  final Color info;
  final Color infoText;
  final Color onInfo;
  final Color simulated;
  final Color simulatedText;
  final Color onSimulated;
  final Color ink;
  final Color surface;
  final Color surfaceElevated;
  final Color foreground;
  final Color mutedForeground;
  final Color muted;
  final Color border;
  final Color input;
  final Color offline;
  final Color onOffline;

  /// Outdoor mode: 2 dp ink borders, no shadows or translucency.
  final bool outdoor;

  /// Viridis AQI fills instead of the CPCB palette (Settings → Display).
  final bool cvdPalette;

  double get borderWidth => outdoor ? 2 : 1;

  @override
  HawaColors copyWith({bool? outdoor, bool? cvdPalette}) => HawaColors(
    brand: brand,
    brandText: brandText,
    onBrand: onBrand,
    warning: warning,
    warningText: warningText,
    onWarning: onWarning,
    danger: danger,
    dangerText: dangerText,
    onDanger: onDanger,
    info: info,
    infoText: infoText,
    onInfo: onInfo,
    simulated: simulated,
    simulatedText: simulatedText,
    onSimulated: onSimulated,
    ink: ink,
    surface: surface,
    surfaceElevated: surfaceElevated,
    foreground: foreground,
    mutedForeground: mutedForeground,
    muted: muted,
    border: border,
    input: input,
    offline: offline,
    onOffline: onOffline,
    outdoor: outdoor ?? this.outdoor,
    cvdPalette: cvdPalette ?? this.cvdPalette,
  );

  @override
  HawaColors lerp(covariant HawaColors? other, double t) => t < 0.5 ? this : (other ?? this);
}

extension HawaColorsX on BuildContext {
  HawaColors get hawaColors => Theme.of(this).extension<HawaColors>() ?? HawaColors.light;
}
