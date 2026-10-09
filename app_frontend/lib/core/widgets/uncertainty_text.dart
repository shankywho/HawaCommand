import 'package:flutter/material.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';

/// "likely 262 (range 210–330) µg/m³": a model output never appears without its range
/// (CONTRACTS §1). A missing range renders "range unavailable", not a bare number.
class UncertaintyText extends StatelessWidget {
  const UncertaintyText({
    required this.value,
    required this.low,
    required this.high,
    required this.unit,
    this.style,
    super.key,
  });

  final double value;
  final double? low;
  final double? high;
  final String unit;
  final TextStyle? style;

  static String format(BuildContext context, double value, double? low, double? high, String unit) {
    final l = context.l10n;
    final v = value.round();
    if (low == null || high == null) return '$v $unit (${l.commonRangeUnavailable})';
    final to = context.isHindi ? 'से' : 'to';
    final range = low < 0 || high < 0
        ? '${low.round()} $to ${high.round()}'
        : '${low.round()}–${high.round()}';
    return context.isHindi ? '$v ($range) $unit' : '$v ($range) $unit';
  }

  @override
  Widget build(BuildContext context) => Text(format(context, value, low, high, unit), style: style);
}
