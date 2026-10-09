import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/core/utils/geo.dart';
import 'package:hawa_app/core/utils/localized_text.dart';

part 'air_snapshot.freezed.dart';

/// One ~1 km open-air cell (`GET /open/v1/air` feature). The AQI is always indicative and the
/// cell carries the model confidence (honesty rule).
@freezed
abstract class AirCell with _$AirCell {
  const factory AirCell({
    required String cellId,

    /// Outer ring as GeoJSON `[lon, lat]` pairs.
    required List<List<double>> ring,
    required int aqi,
    required AqiCategory category,
    required double confidence,
    required bool isSimulated,
    @Default(Pollutant.unknown) Pollutant dominant,
    @Default(CauseLabel.unknown) CauseLabel cause,
    double? causeConf,
    double? pm25,
    double? pm10,
    double? no2Ppb,
    LocalizedText? placeName,
  }) = _AirCell;

  const AirCell._();

  GeoPoint get center => Geo.ringCenter(ring);
}

/// The open-air payload for one snapped box.
@freezed
abstract class AirSnapshot with _$AirSnapshot {
  const factory AirSnapshot({
    required DateTime asOf,
    required List<AirCell> cells,

    /// Server-written cleaner-route tip (traffic `pollutant_warning`, SCREENS C8).
    LocalizedText? altRoute,
    String? attribution,
  }) = _AirSnapshot;

  const AirSnapshot._();

  bool get anySimulated => cells.any((c) => c.isSimulated);
}

/// A cached snapshot with the time it was fetched (stale-while-revalidate).
class CachedAir {
  const CachedAir({required this.snapshot, required this.fetchedAt});

  final AirSnapshot snapshot;
  final DateTime fetchedAt;
}

/// How the user's cell was found.
enum AirMatch { inside, nearest, none }

/// The cell for the user's (coarse) position, picked on the phone.
class AirPick {
  const AirPick({required this.match, this.cell, this.distanceM});

  /// Picks the cell containing [point], else the cell whose centre is nearest within [maxM]
  /// (5 km), else none ("No air data for your area yet"). Runs locally: the point never leaves
  /// the phone (SCREENS C1).
  factory AirPick.of(AirSnapshot? snapshot, GeoPoint point, {double maxM = 5000}) {
    if (snapshot == null || snapshot.cells.isEmpty) return none;
    for (final cell in snapshot.cells) {
      if (cell.ring.length >= 3 && Geo.contains(cell.ring, point)) {
        return AirPick(match: AirMatch.inside, cell: cell, distanceM: 0);
      }
    }
    AirCell? best;
    var bestM = double.infinity;
    for (final cell in snapshot.cells) {
      if (cell.ring.isEmpty) continue;
      final d = Geo.distanceM(cell.center, point);
      if (d < bestM) {
        bestM = d;
        best = cell;
      }
    }
    if (best == null || bestM > maxM) return none;
    return AirPick(match: AirMatch.nearest, cell: best, distanceM: bestM);
  }

  static const none = AirPick(match: AirMatch.none);

  final AirMatch match;
  final AirCell? cell;

  /// Distance to the nearest cell centre when [match] is [AirMatch.nearest].
  final double? distanceM;
}
