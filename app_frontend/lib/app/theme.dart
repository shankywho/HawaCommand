import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Colour tokens taken from the HawaCommand mobile design (MOBILE · 390).
abstract final class HawaColors {
  static const ink = Color(0xFF0B1215);
  static const paper = Color(0xFFFAF9F6);
  static const chat = Color(0xFFECE8DF);
  static const line = Color(0xFFE6E3DC);
  static const muted = Color(0xFF5F6B70);
  static const muted2 = Color(0xFF3B474D);
  static const teal = Color(0xFF0F766E);
  static const tealBright = Color(0xFF2DD4BF);
  static const outgoing = Color(0xFFD4EDE8);
  static const alert = Color(0xFFC02A2A);
  static const white = Color(0xFFFFFFFF);
  static const canvas = Color(0xFFEDEBE5);
}

/// Font families bundled in `assets/fonts`.
abstract final class HawaFonts {
  static const sans = 'Geist';
  static const mono = 'GeistMono';
  static const deva = 'NotoDeva';
  static const pixel = 'Silkscreen';
}

/// Text style helpers that mirror the CSS `font:` shorthands in the design.
///
/// CSS line-height distributes leading evenly above and below the glyphs, so
/// every style uses [TextLeadingDistribution.even].
abstract final class HawaText {
  static TextStyle _base(
    String family,
    List<String> fallback,
    double size, {
    FontWeight weight = FontWeight.w400,
    double? height,
    Color color = HawaColors.ink,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: family,
      fontFamilyFallback: fallback,
      fontSize: size,
      fontWeight: weight,
      height: height,
      leadingDistribution: TextLeadingDistribution.even,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  /// `Geist`, with Devanagari fallback for mixed strings.
  static TextStyle sans(
    double size, {
    FontWeight weight = FontWeight.w400,
    double? height,
    Color color = HawaColors.ink,
    double letterSpacing = 0,
  }) => _base(
    HawaFonts.sans,
    const [HawaFonts.deva],
    size,
    weight: weight,
    height: height,
    color: color,
    letterSpacing: letterSpacing,
  );

  /// `'Noto Sans Devanagari', Geist`: Hindi-first strings.
  static TextStyle deva(
    double size, {
    FontWeight weight = FontWeight.w400,
    double? height,
    Color color = HawaColors.ink,
    double letterSpacing = 0,
  }) => _base(
    HawaFonts.deva,
    const [HawaFonts.sans],
    size,
    weight: weight,
    height: height,
    color: color,
    letterSpacing: letterSpacing,
  );

  /// `'Geist Mono'`: times, counts, IDs.
  static TextStyle mono(
    double size, {
    FontWeight weight = FontWeight.w400,
    double? height,
    Color color = HawaColors.ink,
  }) => _base(
    HawaFonts.mono,
    const [HawaFonts.sans, HawaFonts.deva],
    size,
    weight: weight,
    height: height,
    color: color,
  );

  /// `'Silkscreen'`: pixel labels such as the AQI chip.
  static TextStyle pixel(double size, {Color color = HawaColors.ink}) => _base(
    HawaFonts.pixel,
    const [HawaFonts.mono],
    size,
    color: color,
  );
}

ThemeData buildHawaTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: HawaColors.teal,
      primary: HawaColors.teal,
      surface: HawaColors.paper,
      onSurface: HawaColors.ink,
    ),
    scaffoldBackgroundColor: HawaColors.paper,
    fontFamily: HawaFonts.sans,
    fontFamilyFallback: const [HawaFonts.deva],
    splashFactory: InkSparkle.splashFactory,
  );
  return base.copyWith(
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: HawaColors.teal,
      selectionHandleColor: HawaColors.teal,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: HawaColors.ink,
      contentTextStyle: HawaText.sans(14, color: HawaColors.paper),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: HawaColors.paper,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: HawaColors.line,
    ),
  );
}

/// Light status/navigation bars over the paper background.
const hawaSystemUi = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: HawaColors.paper,
  systemNavigationBarIconBrightness: Brightness.dark,
);
