import 'package:dio/dio.dart';
import 'package:hawa_app/app/env.dart';
import 'package:hawa_app/core/errors/failure.dart';
import 'package:hawa_app/core/network/command_center_api.dart';
import 'package:hawa_app/core/network/interceptors/problem_json_interceptor.dart';
import 'package:hawa_app/core/utils/geo.dart';
import 'package:hawa_app/features/air_map/domain/travel_mode.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'routing_remote_source.g.dart';

/// A road route from the router, before exposure scoring.
class RawRoute {
  const RawRoute({
    required this.geometry,
    required this.distanceM,
    required this.durationS,
    this.segmentDurationsS,
  });

  final List<GeoPoint> geometry;
  final double distanceM;
  final double durationS;

  /// Per-segment seconds when the router's annotations line up with the geometry.
  final List<double>? segmentDurationsS;
}

// Interface so tests and fake mode can swap the router.
// ignore: one_member_abstracts
abstract interface class RoutingRemoteSource {
  /// Routes through [waypoints] (start, optional vias, end). [alternatives] only applies to two
  /// waypoints.
  Future<List<RawRoute>> route(
    List<GeoPoint> waypoints,
    TravelMode mode, {
    bool alternatives = false,
  });
}

/// OSRM (`/route/v1`). Only the start, via and end coordinates leave the phone, and only to the
/// router; nothing about the user goes to HawaCommand.
class OsrmRoutingSource implements RoutingRemoteSource {
  OsrmRoutingSource(this._dio, {String? baseUrl}) : _baseUrl = baseUrl ?? Env.routingUrl;

  final Dio _dio;
  final String _baseUrl;

  @override
  Future<List<RawRoute>> route(
    List<GeoPoint> waypoints,
    TravelMode mode, {
    bool alternatives = false,
  }) async {
    final coords = waypoints
        .map((p) => '${p.lon.toStringAsFixed(6)},${p.lat.toStringAsFixed(6)}')
        .join(';');
    final url = '${_baseUrl.replaceAll('{profile}', mode.profile)}/$coords';
    try {
      final res = await _dio.get<Map<String, Object?>>(
        url,
        queryParameters: {
          'alternatives': alternatives && waypoints.length == 2 ? '2' : 'false',
          'overview': 'full',
          'geometries': 'geojson',
          'annotations': 'duration',
          'steps': 'false',
        },
      );
      final body = res.data ?? const {};
      if (body['code'] != 'Ok') throw NotFoundFailure(code: 'no_route_${body['code']}');
      return [
        for (final r in (body['routes'] as List<Object?>?) ?? const [])
          if (r is Map<String, Object?>) _parse(r),
      ];
    } on DioException catch (e) {
      // The router's 400 "NoRoute" is a normal answer, not a crash.
      if (e.response?.statusCode == 400) return const [];
      throw ProblemJsonInterceptor.toFailure(e);
    }
  }

  static RawRoute _parse(Map<String, Object?> r) {
    final coords =
        ((r['geometry'] as Map<String, Object?>?)?['coordinates'] as List<Object?>?) ?? const [];
    final geometry = [
      for (final c in coords)
        if (c is List && c.length >= 2)
          GeoPoint(lat: (c[1] as num).toDouble(), lon: (c[0] as num).toDouble()),
    ];
    final segs = <double>[];
    for (final leg in (r['legs'] as List<Object?>?) ?? const []) {
      final ann = (leg as Map<String, Object?>?)?['annotation'] as Map<String, Object?>?;
      for (final d in (ann?['duration'] as List<Object?>?) ?? const []) {
        segs.add((d as num?)?.toDouble() ?? 0);
      }
    }
    return RawRoute(
      geometry: geometry,
      distanceM: (r['distance'] as num?)?.toDouble() ?? 0,
      durationS: (r['duration'] as num?)?.toDouble() ?? 0,
      segmentDurationsS: segs.length == geometry.length - 1 ? segs : null,
    );
  }
}

@riverpod
RoutingRemoteSource routingRemoteSource(Ref ref) =>
    OsrmRoutingSource(ref.watch(externalDioProvider));
