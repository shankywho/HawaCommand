import 'package:hawa_api/hawa_api.dart' as api;
import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/core/utils/geo.dart';
import 'package:hawa_app/core/utils/localized_text.dart';
import 'package:hawa_app/features/driver_route/domain/asset_summary.dart';
import 'package:hawa_app/features/driver_route/domain/impact_summary.dart';
import 'package:hawa_app/features/driver_route/domain/shift.dart';
import 'package:hawa_app/features/driver_route/domain/stop.dart';

/// hawa_api models → driver domain. Unknown enum values map to `unknown` (CONTRACTS §12.5).
abstract final class TaskMapper {
  static Stop stop(api.TaskItem t) => Stop(
    taskId: t.id,
    sequence: t.sequence,
    kind: TaskKind.fromWire(t.kind.value),
    status: TaskStatus.fromWire(t.status.value),
    location: GeoPoint.fromLonLat(t.location.coordinates),
    placeName: text(t.placeName),
    windowStart: t.windowStart.toUtc(),
    windowEnd: t.windowEnd.toUtc(),
    isSimulated: t.isSimulated,
    planId: t.planId,
    cellId: t.cellId,
    instructions: t.instructions == null ? null : text(t.instructions!),
    reasonText: t.reasonText == null ? null : text(t.reasonText!),
    targetLitres: t.targetLitres,
    segmentLengthM: t.segmentLengthM,
    durationMin: t.durationMin,
    arrivalRadiusM: t.arrivalRadiusM ?? 150,
    causeLabel: t.causeLabel == null ? null : CauseLabel.fromWire(t.causeLabel!.value),
    causeConf: t.causeConf,
    completionSource: t.completionSource == null
        ? null
        : InterventionSource.fromWire(t.completionSource!.value),
    litres: t.litres,
    impact: t.impactSummary == null ? null : impact(t.impactSummary!),
    skipReason: t.skipReason?.value,
    version: t.version,
  );

  static ImpactSummary impact(api.ImpactSummary i) => ImpactSummary(
    pollutant: Pollutant.fromWire(i.pollutant.value),
    effectPct: i.effectPct,
    ciLow: i.ciLow,
    ciHigh: i.ciHigh,
    method: ImpactMethod.fromWire(i.method.value),
    verdict: ImpactVerdict.fromWire(i.verdict.value),
    durationMin: i.durationMin,
    ciLevel: i.ciLevel,
  );

  /// Impact summary from a WS `task.verified` payload (plain JSON).
  static ImpactSummary? impactFromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = raw.cast<String, Object?>();
    num? n(String k) => m[k] as num?;
    if (n('effect_pct') == null || n('ci_low') == null || n('ci_high') == null) return null;
    return ImpactSummary(
      pollutant: Pollutant.fromWire(m['pollutant'] as String?),
      effectPct: n('effect_pct')!.toDouble(),
      ciLow: n('ci_low')!.toDouble(),
      ciHigh: n('ci_high')!.toDouble(),
      method: ImpactMethod.fromWire(m['method'] as String?),
      verdict: ImpactVerdict.fromWire(m['verdict'] as String?),
      durationMin: n('duration_min')?.toInt(),
      ciLevel: n('ci_level')?.toDouble(),
    );
  }

  static AssetSummary asset(api.TaskAsset a) => AssetSummary(
    id: a.id,
    label: a.label,
    type: a.type.value,
    isSimulated: a.isSimulated,
    tagDeviceId: a.tagDeviceId,
    tagStatus: a.tagStatus == null
        ? DeviceStatus.unknown
        : DeviceStatus.fromWire(a.tagStatus!.value),
    tagLastSeenAt: a.tagLastSeenAt?.toUtc(),
  );

  static Shift shift(api.TaskShift s) => Shift(
    id: s.id,
    status: ShiftStatus.fromWire(s.status.value),
    start: s.start.toUtc(),
    end: s.end.toUtc(),
    startedAt: s.startedAt?.toUtc(),
    endedAt: s.endedAt?.toUtc(),
  );

  static LocalizedText text(api.LocalizedText t) => LocalizedText(en: t.en, hi: t.hi);

  static List<GeoPoint> line(api.GeoLineString? g) =>
      g == null ? const [] : [for (final c in g.coordinates) GeoPoint.fromLonLat(c)];

  static GeoBox? bbox(List<double>? b) => b == null || b.length != 4
      ? null
      : GeoBox(minLon: b[0], minLat: b[1], maxLon: b[2], maxLat: b[3]);
}
