import 'package:intl/intl.dart';

/// Number formatting per DESIGN_SYSTEM §12: Latin digits, en-IN grouping, a true minus sign
/// (U+2212), en-dash ranges and "to" when a bound is negative.
abstract final class Numbers {
  static const minus = '−';

  static final _grouped = NumberFormat.decimalPattern('en_IN');

  /// "18,450"; whole numbers only.
  static String whole(num value) => _grouped.format(value.round());

  /// "−18.2" with [digits] decimals and a true minus sign.
  static String signed(num value, {int digits = 1}) {
    final text = value.abs().toStringAsFixed(digits);
    return value < 0 ? '$minus$text' : text;
  }

  /// "137–191", or "−26.0 to −9.9" when a bound is negative. [to] is localized by the caller.
  static String range(num low, num high, {int digits = 0, String to = 'to'}) {
    if (low < 0 || high < 0) {
      return '${signed(low, digits: digits)} $to ${signed(high, digits: digits)}';
    }
    return '${low.toStringAsFixed(digits)}–${high.toStringAsFixed(digits)}';
  }

  /// 0.86 → "86".
  static String percent(double fraction) => (fraction * 100).round().toString();
}
