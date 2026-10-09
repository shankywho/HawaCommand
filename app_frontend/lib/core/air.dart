import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawacommand_app/core/api_client.dart';
import 'package:latlong2/latlong.dart';

/// CPCB PM2.5 bands (µg/m³) and their map fills (docs/CONTRACTS.md §10.1).
enum PmBand {
  good(30, Color(0xFF00B050)),
  satisfactory(60, Color(0xFF92D050)),
  moderate(90, Color(0xFFFFD600)),
  poor(120, Color(0xFFFF9900)),
  veryPoor(250, Color(0xFFFF0000)),
  severe(double.infinity, Color(0xFFC00000));

  const PmBand(this.upper, this.color);

  final double upper;
  final Color color;

  static PmBand of(double pm25) => PmBand.values.firstWhere((b) => pm25 <= b.upper);
}

/// One ranked hotspot from `GET /v1/hotspots`.
class Hotspot {
  const Hotspot({
    required this.cellId,
    required this.place,
    required this.point,
    required this.pm25,
    required this.cause,
    required this.causeConf,
    required this.suspect,
    required this.assets,
  });

  factory Hotspot.fromJson(Map<String, dynamic> json) {
    final at = (json['at'] as List<dynamic>).cast<num>();
    final suspect = json['suspectPin'] as Map<String, dynamic>?;
    return Hotspot(
      cellId: json['cellId'] as String,
      place: json['place'] as String,
      point: LatLng(at[1].toDouble(), at[0].toDouble()),
      pm25: (json['pm25'] as num).toDouble(),
      cause: json['cause'] as String? ?? 'Unknown',
      causeConf: (json['causeConf'] as num?)?.toDouble() ?? 0,
      suspect: suspect?['label'] as String? ?? '',
      assets: ((json['assets'] as List<dynamic>?) ?? const []).cast<String>().toList(),
    );
  }

  final String cellId;
  final String place;
  final LatLng point;
  final double pm25;
  final String cause;
  final double causeConf;
  final String suspect;
  final List<String> assets;
}

/// Bundled fallback mirroring the backend fixture (East Delhi subset).
const demoHotspots = <Hotspot>[
  Hotspot(
    cellId: 'ghazipur',
    place: 'Ghazipur',
    point: LatLng(28.625, 77.329),
    pm25: 388,
    cause: 'Burning',
    causeConf: 0.88,
    suspect: 'Landfill edge, open burning',
    assets: ['I-3', 'T-12'],
  ),
  Hotspot(
    cellId: 'anand',
    place: 'Anand Vihar',
    point: LatLng(28.647, 77.316),
    pm25: 212,
    cause: 'Dust',
    causeConf: 0.84,
    suspect: 'Unpaved shoulder, ISBT road',
    assets: ['T-12', 'ASG-07', 'SW-03'],
  ),
  Hotspot(
    cellId: 'shahdara',
    place: 'Shahdara',
    point: LatLng(28.673, 77.289),
    pm25: 341,
    cause: 'Traffic',
    causeConf: 0.72,
    suspect: 'GT Road corridor, idling HGVs',
    assets: ['SW-03'],
  ),
];

final hotspotsProvider = FutureProvider.autoDispose<Sourced<List<Hotspot>>>(
  (ref) => ref
      .watch(hawaApiProvider)
      .fetchOrDemo(
        '/v1/hotspots',
        parse: (json) => (json['items'] as List<dynamic>)
            .map((e) => Hotspot.fromJson(e as Map<String, dynamic>))
            .toList(),
        demo: () => demoHotspots,
      ),
  retry: (retryCount, error) => null,
);
