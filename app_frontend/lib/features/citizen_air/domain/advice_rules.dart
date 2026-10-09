import 'package:hawa_app/core/utils/contract_enums.dart';

/// "What to do" lines (SCREENS C1); presentation maps each key to its ARB string.
enum AdviceKey { fine, mask, indoors, avoidRoad, quietStreets, coverDust, rough }

/// Pollutant-specific advice (F16): pure, table-driven and unit tested.
///
/// | Condition                                          | Advice                     |
/// |----------------------------------------------------|----------------------------|
/// | category ≤ satisfactory                            | fine                       |
/// | dominant pm25 and cause burning or regional_smoke  | mask, indoors              |
/// | dominant no2 or cause traffic                      | avoidRoad, quietStreets    |
/// | dominant pm10 or cause dust                        | coverDust                  |
/// | confidence < 0.4 (Low)                             | append rough               |
///
/// When the air is worse than satisfactory but no pollutant row matches (for example PM2.5 with
/// a mixed or unknown cause), the generic [AdviceKey.mask] line is given so the list is never
/// empty. A missing AQI estimate (`unknown` category) gets only the pollutant rows.
abstract final class AdviceRules {
  /// Below this the estimate is Low confidence (DESIGN_SYSTEM §2.5).
  static const roughBelow = 0.4;

  static List<AdviceKey> adviceFor({
    required AqiCategory category,
    required Pollutant dominant,
    required CauseLabel cause,
    required double confidence,
  }) {
    final out = <AdviceKey>[];
    void add(AdviceKey key) {
      if (!out.contains(key)) out.add(key);
    }

    if (category.isAtMostSatisfactory) {
      add(AdviceKey.fine);
    } else {
      final smoke = cause == CauseLabel.burning || cause == CauseLabel.regionalSmoke;
      if (dominant == Pollutant.pm25 && smoke) {
        add(AdviceKey.mask);
        add(AdviceKey.indoors);
      }
      if (dominant == Pollutant.no2 || cause == CauseLabel.traffic) {
        add(AdviceKey.avoidRoad);
        add(AdviceKey.quietStreets);
      }
      if (dominant == Pollutant.pm10 || cause == CauseLabel.dust) add(AdviceKey.coverDust);
      if (out.isEmpty && category != AqiCategory.unknown) add(AdviceKey.mask);
    }
    if (confidence < roughBelow) add(AdviceKey.rough);
    return out;
  }
}
