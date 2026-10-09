import 'package:dio/dio.dart';
import 'package:hawa_app/app/env.dart';
import 'package:hawa_app/core/network/command_center_api.dart';
import 'package:hawa_app/core/utils/geo.dart';
import 'package:hawa_app/features/air_map/domain/place.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'geocoding_remote_source.g.dart';

// Interface so tests can swap the place search.
// ignore: one_member_abstracts
abstract interface class GeocodingRemoteSource {
  Future<List<Place>> search(String query, {GeoPoint? near, String lang = 'en'});
}

/// Photon place search biased to Delhi-NCR. Falls back to the built-in landmark list offline.
class PhotonGeocodingSource implements GeocodingRemoteSource {
  PhotonGeocodingSource(this._dio);

  final Dio _dio;

  /// Delhi-NCR: minLon, minLat, maxLon, maxLat.
  static const _bbox = '76.80,28.38,77.40,28.90';

  @override
  Future<List<Place>> search(String query, {GeoPoint? near, String lang = 'en'}) async {
    final q = query.trim();
    if (q.length < 2) return DelhiPlaces.search(q);
    try {
      final res = await _dio.get<Map<String, Object?>>(
        Env.geocodingUrl,
        queryParameters: {
          'q': q,
          'limit': 8,
          'bbox': _bbox,
          // Photon supports en/de/fr/it; Hindi queries still match local names.
          'lang': 'en',
          'lat': (near?.lat ?? 28.6139).toStringAsFixed(3),
          'lon': (near?.lon ?? 77.2090).toStringAsFixed(3),
        },
      );
      final out = <Place>[];
      for (final f in (res.data?['features'] as List<Object?>?) ?? const []) {
        if (f is! Map<String, Object?>) continue;
        final props = (f['properties'] as Map<String, Object?>?) ?? const {};
        final coords = (f['geometry'] as Map<String, Object?>?)?['coordinates'] as List<Object?>?;
        final name = props['name'] as String?;
        if (name == null || coords == null || coords.length < 2) continue;
        final sub = [
          props['street'],
          props['district'],
          props['city'] ?? props['county'],
          props['state'],
        ].whereType<String>().where((s) => s != name).toSet().join(', ');
        out.add(
          Place(
            name: name,
            subtitle: sub.isEmpty ? null : sub,
            point: GeoPoint(
              lat: (coords[1]! as num).toDouble(),
              lon: (coords[0]! as num).toDouble(),
            ),
          ),
        );
      }
      return out.isEmpty ? DelhiPlaces.search(q) : out;
    } on DioException {
      return DelhiPlaces.search(q);
    }
  }
}

@riverpod
GeocodingRemoteSource geocodingRemoteSource(Ref ref) =>
    PhotonGeocodingSource(ref.watch(externalDioProvider));
