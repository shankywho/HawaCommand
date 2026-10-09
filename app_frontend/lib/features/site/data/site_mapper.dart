import 'package:hawa_api/hawa_api.dart' as api;
import 'package:hawa_app/core/utils/localized_text.dart';
import 'package:hawa_app/features/site/domain/site_score.dart';

/// hawa_api `SiteMeOut` → [SiteScore]. Unknown enum values map to `unknown` (CONTRACTS §12.5).
abstract final class SiteMapper {
  /// The cached payload is the wire JSON; mapping happens on read.
  static SiteScore fromJson(Map<String, Object?> json) => fromApi(api.SiteMeOut.fromJson(json));

  static SiteScore fromApi(api.SiteMeOut o) => SiteScore(
    siteId: o.siteId,
    name: o.name,
    type: type(o.type),
    grade: grade(o.grade),
    wardId: o.wardId,
    placeName: _text(o.placeName),
    gradeSince: o.gradeSince == null ? null : _date(o.gradeSince!),
    score: o.score,
    violations: o.violations,
    flags30d: o.flags30d,
    lastInspectionAt: o.lastInspectionAt?.toUtc(),
    pm10Trend: [
      for (final p in o.pm10Trend ?? const <api.Pm10TrendPoint>[])
        SitePm10Point(date: _date(p.date), pm10P50: p.pm10P50, nObs: p.nObs),
    ]..sort((a, b) => a.date.compareTo(b.date)),
    components: [
      for (final c in o.components ?? const <api.SiteScoreComponent>[])
        SiteScoreComponent(name: c.name, value: c.value, label: _text(c.label)),
    ],
    tips: [
      for (final t in o.tips ?? const <api.LocalizedText>[])
        if (t.en.trim().isNotEmpty) _text(t)!,
    ],
    isSimulated: o.isSimulated,
  );

  static SiteGrade grade(api.SiteGrade g) => switch (g) {
    api.SiteGrade.A => SiteGrade.a,
    api.SiteGrade.B => SiteGrade.b,
    api.SiteGrade.C => SiteGrade.c,
    api.SiteGrade.unknownDefaultOpenApi => SiteGrade.unknown,
  };

  static SiteType type(api.SiteType t) => switch (t) {
    api.SiteType.construction => SiteType.construction,
    api.SiteType.industrialUnit => SiteType.industrialUnit,
    api.SiteType.wasteSite => SiteType.wasteSite,
    api.SiteType.other => SiteType.other,
    api.SiteType.unknownDefaultOpenApi => SiteType.unknown,
  };

  static LocalizedText? _text(api.LocalizedText? t) =>
      t == null ? null : LocalizedText(en: t.en, hi: t.hi);

  /// A wire `date` parses to midnight in the parse zone; keep its calendar fields as-is.
  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

  static String _two(int v) => v.toString().padLeft(2, '0');
}
