import 'package:flutter/material.dart';
import 'package:hawa_app/app/theme/tokens.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';

/// AQI category colours (DESIGN_SYSTEM §2.3, CPCB exact values). Never used without the
/// category word and number; the CVD (viridis) palette changes fills only, never names.
class AqiColors {
  const AqiColors({required this.fill, required this.onFill, required this.border});

  final Color fill;
  final Color onFill;

  /// Light fills (moderate, satisfactory) fall below 3:1 on light surfaces, so every chip carries
  /// its border.
  final Color border;
}

abstract final class AqiPalette {
  static AqiColors of(AqiCategory category, {bool cvd = false, bool dark = false}) {
    if (cvd) return _cvd(category);
    return switch (category) {
      AqiCategory.good => const AqiColors(
        fill: Color(0xFF00B050),
        onFill: HawaTokens.ink,
        border: Color(0xFF008A3E),
      ),
      AqiCategory.satisfactory => const AqiColors(
        fill: Color(0xFF92D050),
        onFill: HawaTokens.ink,
        border: Color(0xFF5E8C2C),
      ),
      AqiCategory.moderate => const AqiColors(
        fill: Color(0xFFFFD600),
        onFill: HawaTokens.ink,
        border: Color(0xFF9A8000),
      ),
      AqiCategory.poor => const AqiColors(
        fill: Color(0xFFFF9900),
        onFill: HawaTokens.ink,
        border: Color(0xFFB36B00),
      ),
      AqiCategory.veryPoor => const AqiColors(
        fill: Color(0xFFFF0000),
        onFill: HawaTokens.ink,
        border: Color(0xFFB30000),
      ),
      AqiCategory.severe => AqiColors(
        fill: const Color(0xFFC00000),
        onFill: HawaTokens.white,
        border: dark ? const Color(0xFFFCA5A5) : const Color(0xFF800000),
      ),
      AqiCategory.unknown => const AqiColors(
        fill: HawaTokens.muted,
        onFill: HawaTokens.ink,
        border: HawaTokens.input,
      ),
    };
  }

  static AqiColors _cvd(AqiCategory c) => switch (c) {
    AqiCategory.good => const AqiColors(
      fill: Color(0xFFFDE725),
      onFill: HawaTokens.ink,
      border: Color(0xFF9A8B00),
    ),
    AqiCategory.satisfactory => const AqiColors(
      fill: Color(0xFF7AD151),
      onFill: HawaTokens.ink,
      border: Color(0xFF4A8A2E),
    ),
    AqiCategory.moderate => const AqiColors(
      fill: Color(0xFF22A884),
      onFill: HawaTokens.ink,
      border: Color(0xFF15705A),
    ),
    AqiCategory.poor => const AqiColors(
      fill: Color(0xFF2A788E),
      onFill: HawaTokens.white,
      border: Color(0xFF1B4E5C),
    ),
    AqiCategory.veryPoor => const AqiColors(
      fill: Color(0xFF414487),
      onFill: HawaTokens.white,
      border: Color(0xFF2A2C58),
    ),
    AqiCategory.severe => const AqiColors(
      fill: Color(0xFF440154),
      onFill: HawaTokens.white,
      border: Color(0xFF2A0034),
    ),
    AqiCategory.unknown => const AqiColors(
      fill: HawaTokens.muted,
      onFill: HawaTokens.ink,
      border: HawaTokens.input,
    ),
  };

  /// GRAP stage fills reuse the AQI band that triggers each stage (DESIGN_SYSTEM §2.4).
  static AqiColors grap(int stage) => switch (stage) {
    1 => of(AqiCategory.poor),
    2 => of(AqiCategory.veryPoor),
    3 || 4 => of(AqiCategory.severe),
    _ => of(AqiCategory.unknown),
  };
}
