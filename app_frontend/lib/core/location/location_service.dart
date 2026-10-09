import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:hawa_app/core/utils/geo.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'location_service.g.dart';

enum LocationPermissionState { granted, denied, deniedForever, serviceOff }

class LocationFix {
  const LocationFix({
    required this.point,
    required this.accuracyM,
    required this.at,
    this.speedMps,
    this.coarse = false,
  });

  final GeoPoint point;
  final double accuracyM;
  final DateTime at;
  final double? speedMps;

  /// No fresh fix in time; the last known position was used (`location_quality: coarse`).
  final bool coarse;
}

/// geolocator wrapper: permission status, one-off fixes. Never asks for background location.
class LocationService {
  Future<LocationPermissionState> status() async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationPermissionState.serviceOff;
    return _map(await Geolocator.checkPermission());
  }

  /// Shown only after the education screen (SCREENS §2).
  Future<LocationPermissionState> request() async {
    final current = await Geolocator.checkPermission();
    if (current == LocationPermission.deniedForever) return LocationPermissionState.deniedForever;
    return _map(await Geolocator.requestPermission());
  }

  Future<bool> openSettings() => Geolocator.openAppSettings();

  /// A fix within [timeout]; otherwise the last known position flagged coarse (ARCHITECTURE §13).
  Future<LocationFix?> currentFix({
    Duration timeout = const Duration(seconds: 15),
    bool precise = true,
  }) async {
    if (await status() != LocationPermissionState.granted) return null;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: precise ? LocationAccuracy.high : LocationAccuracy.low,
          timeLimit: timeout,
        ),
      );
      return _fix(pos);
    } on TimeoutException {
      final last = await Geolocator.getLastKnownPosition();
      return last == null ? null : _fix(last, coarse: true);
    } on LocationServiceDisabledException {
      return null;
    }
  }

  static LocationFix _fix(Position p, {bool coarse = false}) => LocationFix(
    point: GeoPoint(lat: p.latitude, lon: p.longitude),
    accuracyM: p.accuracy,
    at: p.timestamp.toUtc(),
    speedMps: p.speed,
    coarse: coarse,
  );

  static LocationFix fromPosition(Position p) => _fix(p);

  static LocationPermissionState _map(LocationPermission p) => switch (p) {
    LocationPermission.always || LocationPermission.whileInUse => LocationPermissionState.granted,
    LocationPermission.deniedForever => LocationPermissionState.deniedForever,
    LocationPermission.denied ||
    LocationPermission.unableToDetermine => LocationPermissionState.denied,
  };
}

@Riverpod(keepAlive: true)
LocationService locationService(Ref ref) => LocationService();
