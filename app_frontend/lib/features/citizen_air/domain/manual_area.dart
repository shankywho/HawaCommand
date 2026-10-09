import 'package:hawa_app/core/utils/geo.dart';
import 'package:hawa_app/core/utils/localized_text.dart';

/// A place picked by hand when location is off (SCREENS C1: manual area picker instead of a dead
/// end). Stored in prefs via `SettingsStore.setManualArea`.
class ManualArea {
  const ManualArea({required this.id, required this.name, required this.point});

  final String id;
  final LocalizedText name;

  /// The area's centre (public, not the user's position).
  final GeoPoint point;

  Map<String, Object?> toJson() => {
    'id': id,
    'en': name.en,
    'hi': name.hi,
    'lat': point.lat,
    'lon': point.lon,
  };

  static ManualArea? fromJson(Map<String, Object?>? json) {
    if (json == null) return null;
    final lat = json['lat'];
    final lon = json['lon'];
    final en = json['en'];
    if (lat is! num || lon is! num || en is! String) return null;
    final hi = json['hi'];
    return ManualArea(
      id: json['id']?.toString() ?? en,
      name: LocalizedText(en: en, hi: hi is String ? hi : null),
      point: GeoPoint(lat: lat.toDouble(), lon: lon.toDouble()),
    );
  }

  /// Wards around the demo area (Karol Bagh, ward-084) plus Connaught Place.
  static const delhi = <ManualArea>[
    ManualArea(
      id: 'karol_bagh',
      name: LocalizedText(en: 'Karol Bagh', hi: 'करोल बाग़'),
      point: GeoPoint(lat: 28.6440, lon: 77.1900),
    ),
    ManualArea(
      id: 'rajinder_nagar',
      name: LocalizedText(en: 'Rajinder Nagar', hi: 'राजिंदर नगर'),
      point: GeoPoint(lat: 28.6350, lon: 77.1900),
    ),
    ManualArea(
      id: 'patel_nagar',
      name: LocalizedText(en: 'Patel Nagar', hi: 'पटेल नगर'),
      point: GeoPoint(lat: 28.6350, lon: 77.2000),
    ),
    ManualArea(
      id: 'naraina',
      name: LocalizedText(en: 'Naraina', hi: 'नारायणा'),
      point: GeoPoint(lat: 28.6350, lon: 77.1800),
    ),
    ManualArea(
      id: 'anand_parbat',
      name: LocalizedText(en: 'Anand Parbat', hi: 'आनंद पर्वत'),
      point: GeoPoint(lat: 28.6530, lon: 77.1800),
    ),
    ManualArea(
      id: 'connaught_place',
      name: LocalizedText(en: 'Connaught Place', hi: 'कनॉट प्लेस'),
      point: GeoPoint(lat: 28.6315, lon: 77.2167),
    ),
  ];
}
