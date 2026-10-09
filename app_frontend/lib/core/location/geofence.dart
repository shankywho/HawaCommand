import 'package:hawa_app/core/utils/geo.dart';

/// Arrival detection: within [radiusM] of the target continuously for [dwell]
/// (ARCHITECTURE §11.3: 150 m, 20 s). For drivers arrival is a local UI state only.
class ArrivalDetector {
  ArrivalDetector({this.radiusM = 150, this.dwell = const Duration(seconds: 20)});

  final double radiusM;
  final Duration dwell;

  String? _targetId;
  DateTime? _insideSince;
  bool _fired = false;

  /// Feeds one fix; returns true exactly once per target when arrival is confirmed.
  bool feed({
    required String targetId,
    required GeoPoint target,
    required GeoPoint position,
    required DateTime at,
  }) {
    if (targetId != _targetId) {
      _targetId = targetId;
      _insideSince = null;
      _fired = false;
    }
    if (_fired) return false;
    final inside = Geo.distanceM(target, position) <= radiusM;
    if (!inside) {
      _insideSince = null;
      return false;
    }
    _insideSince ??= at;
    if (at.difference(_insideSince!) >= dwell) {
      _fired = true;
      return true;
    }
    return false;
  }

  void reset() {
    _targetId = null;
    _insideSince = null;
    _fired = false;
  }
}
