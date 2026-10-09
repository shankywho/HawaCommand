import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hawa_app/core/utils/localized_text.dart';

part 'site_score.freezed.dart';

/// Site Compliance Score grade (CONTRACTS `SiteGrade`). Unknown wire values render neutrally.
enum SiteGrade {
  a('A'),
  b('B'),
  c('C'),
  unknown('unknown');

  const SiteGrade(this.wire);

  final String wire;

  static SiteGrade fromWire(String? w) =>
      values.firstWhere((g) => g.wire == w?.trim().toUpperCase(), orElse: () => unknown);

  /// The letter shown in the badge, or null when unknown.
  String? get letter => this == unknown ? null : wire;
}

/// `SiteType` (CONTRACTS §3) + unknown.
enum SiteType {
  construction('construction'),
  industrialUnit('industrial_unit'),
  wasteSite('waste_site'),
  other('other'),
  unknown('unknown');

  const SiteType(this.wire);

  final String wire;

  static SiteType fromWire(String? w) =>
      values.firstWhere((t) => t.wire == w, orElse: () => unknown);
}

/// One day of the PM10 trend: median (P50) µg/m³ and how many observations it rests on.
@freezed
abstract class SitePm10Point with _$SitePm10Point {
  const factory SitePm10Point({
    /// IST date `YYYY-MM-DD`.
    required String date,
    double? pm10P50,
    int? nObs,
  }) = _SitePm10Point;
}

/// One input of the score ("Hours with PM10 above the limit", value 11.5).
@freezed
abstract class SiteScoreComponent with _$SiteScoreComponent {
  const factory SiteScoreComponent({
    required String name,
    required double value,
    LocalizedText? label,
  }) = _SiteScoreComponent;
}

/// The site manager's own site (`GET /v1/sites/me`, SCREENS M1). Read-only and indicative: never
/// a legal finding (CONTEXT §2.5).
@freezed
abstract class SiteScore with _$SiteScore {
  const factory SiteScore({
    required String siteId,
    required String name,
    @Default(SiteType.unknown) SiteType type,
    @Default(SiteGrade.unknown) SiteGrade grade,
    String? wardId,
    LocalizedText? placeName,

    /// IST date `YYYY-MM-DD` the current grade started.
    String? gradeSince,
    double? score,
    int? violations,
    int? flags30d,
    DateTime? lastInspectionAt,
    @Default(<SitePm10Point>[]) List<SitePm10Point> pm10Trend,
    @Default(<SiteScoreComponent>[]) List<SiteScoreComponent> components,
    @Default(<LocalizedText>[]) List<LocalizedText> tips,
    @Default(false) bool isSimulated,
  }) = _SiteScore;

  const SiteScore._();

  /// Trend points that carry a value, oldest first.
  List<SitePm10Point> get trendWithValues => [
    for (final p in pm10Trend)
      if (p.pm10P50 != null) p,
  ];
}

/// The cached site with the time it was fetched (for the freshness banner).
@freezed
abstract class SiteSnapshot with _$SiteSnapshot {
  const factory SiteSnapshot({required SiteScore site, required DateTime fetchedAt}) =
      _SiteSnapshot;
}
