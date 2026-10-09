import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/core/utils/geo.dart';
import 'package:hawa_app/core/utils/localized_text.dart';

/// I1 row: "a target, not an area", ordered by priority then task sequence.
class InspectionTarget {
  const InspectionTarget({
    required this.id,
    required this.status,
    required this.origin,
    required this.priority,
    required this.location,
    required this.placeName,
    required this.cause,
    required this.causeConf,
    required this.createdAt,
    this.taskId,
    this.isSimulated = false,
    this.onSiteLocal = false,
  });

  final String id;
  final InspectionStatus status;
  final InspectionOrigin origin;
  final int priority;
  final GeoPoint location;
  final LocalizedText placeName;
  final CauseLabel cause;
  final double causeConf;
  final DateTime createdAt;
  final String? taskId;
  final bool isSimulated;

  /// "Arrived" pressed on the phone (task-less inspections have no on-site transition yet).
  final bool onSiteLocal;

  static GeoPoint? point(Object? geo) {
    final c = (geo as Map<String, Object?>?)?['coordinates'];
    if (c is List && c.length >= 2 && c[0] is num && c[1] is num) {
      return GeoPoint(lat: (c[1] as num).toDouble(), lon: (c[0] as num).toDouble());
    }
    return null;
  }

  static InspectionTarget? fromJson(Map<String, Object?> j, {Set<String> onSite = const {}}) {
    final loc = point(j['target']) ?? point(j['suspect_pin']);
    final name = j['place_name'];
    if (loc == null || j['id'] is! String) return null;
    return InspectionTarget(
      id: j['id']! as String,
      status: InspectionStatus.fromWire(j['status'] as String?),
      origin: InspectionOrigin.fromWire(j['origin'] as String?),
      priority: (j['priority'] as num?)?.toInt() ?? 9,
      location: loc,
      placeName: name is Map<String, Object?> && name['en'] is String
          ? LocalizedText.fromJson(name)
          : const LocalizedText(en: '—'),
      cause: CauseLabel.fromWire(j['cause_label'] as String?),
      causeConf: (j['cause_conf'] as num?)?.toDouble() ?? 0,
      createdAt:
          DateTime.tryParse(j['created_at'] as String? ?? '')?.toUtc() ?? DateTime.now().toUtc(),
      taskId: j['task_id'] as String?,
      isSimulated: j['is_simulated'] as bool? ?? false,
      onSiteLocal: onSite.contains(j['id']),
    );
  }
}

class SpikePoint {
  const SpikePoint(this.ts, this.value);

  final DateTime ts;
  final double value;
}

/// I3 evidence bundle (no reporter identity, ever).
class TargetEvidence {
  const TargetEvidence({
    required this.target,
    this.suspectRadiusM,
    this.backTrajectory = const [],
    this.spikePollutant,
    this.spikeBaseline,
    this.spikePeak,
    this.spikeSource,
    this.spikeSeconds,
    this.spikeSeries = const [],
    this.photos = const [],
    this.photoAt,
  });

  final InspectionTarget target;
  final double? suspectRadiusM;
  final List<GeoPoint> backTrajectory;
  final String? spikePollutant;
  final double? spikeBaseline;
  final double? spikePeak;
  final String? spikeSource;
  final int? spikeSeconds;
  final List<SpikePoint> spikeSeries;

  /// `asset://…` or presigned URLs.
  final List<String> photos;
  final DateTime? photoAt;

  bool get hasEvidence => spikePeak != null || photos.isNotEmpty;

  static TargetEvidence? fromJson(Map<String, Object?> j, {Set<String> onSite = const {}}) {
    final target = InspectionTarget.fromJson(j, onSite: onSite);
    if (target == null) return null;
    final spike = j['spike'] as Map<String, Object?>?;
    final photo = j['photo'] as Map<String, Object?>?;
    final photos = <String>[
      if (photo?['url'] is String) photo!['url']! as String,
      for (final p in (j['photos'] as List<Object?>?) ?? const [])
        if (p is Map<String, Object?> && p['url'] is String)
          p['url']! as String
        else if (p is String)
          p,
    ];
    final traj =
        ((j['back_trajectory'] as Map<String, Object?>?)?['coordinates'] as List<Object?>?) ??
        const [];
    return TargetEvidence(
      target: target,
      suspectRadiusM: (j['suspect_radius_m'] as num?)?.toDouble(),
      backTrajectory: [
        for (final c in traj)
          if (c is List && c.length >= 2)
            GeoPoint(lat: (c[1] as num).toDouble(), lon: (c[0] as num).toDouble()),
      ],
      spikePollutant: spike?['pollutant'] as String?,
      spikeBaseline: (spike?['baseline'] as num?)?.toDouble(),
      spikePeak: (spike?['peak'] as num?)?.toDouble(),
      spikeSource: spike?['vehicle_label'] as String? ?? spike?['device_id'] as String?,
      spikeSeconds: (spike?['duration_s'] as num?)?.toInt(),
      spikeSeries: [
        for (final p in (spike?['series'] as List<Object?>?) ?? const [])
          if (p is Map<String, Object?> && p['value'] is num)
            SpikePoint(DateTime.parse(p['ts']! as String).toUtc(), (p['value']! as num).toDouble()),
      ],
      photos: photos,
      photoAt: DateTime.tryParse(
        photo?['captured_at'] as String? ??
            ((j['photos'] as List<Object?>?)
                    ?.whereType<Map<String, Object?>>()
                    .firstOrNull?['captured_at']
                as String?) ??
            '',
      )?.toUtc(),
    );
  }
}
