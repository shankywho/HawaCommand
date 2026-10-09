import 'package:hawa_app/core/utils/geo.dart';

/// A route end: a searched place, a map pick or the user's position.
class Place {
  const Place({required this.name, required this.point, this.subtitle, this.isMyLocation = false});

  final String name;
  final String? subtitle;
  final GeoPoint point;
  final bool isMyLocation;
}

/// Well-known Delhi places: quick picks, and the offline fallback when place search is unreachable.
abstract final class DelhiPlaces {
  static const List<Place> landmarks = [
    Place(
      name: 'Connaught Place',
      subtitle: 'New Delhi',
      point: GeoPoint(lat: 28.6315, lon: 77.2167),
    ),
    Place(name: 'India Gate', subtitle: 'New Delhi', point: GeoPoint(lat: 28.6129, lon: 77.2295)),
    Place(
      name: 'Karol Bagh',
      subtitle: 'Central Delhi',
      point: GeoPoint(lat: 28.6519, lon: 77.1909),
    ),
    Place(
      name: 'Chandni Chowk',
      subtitle: 'Old Delhi',
      point: GeoPoint(lat: 28.6506, lon: 77.2303),
    ),
    Place(
      name: 'Anand Vihar ISBT',
      subtitle: 'East Delhi',
      point: GeoPoint(lat: 28.6469, lon: 77.3159),
    ),
    Place(name: 'Mundka', subtitle: 'West Delhi', point: GeoPoint(lat: 28.6826, lon: 77.0313)),
    Place(
      name: 'Punjabi Bagh',
      subtitle: 'West Delhi',
      point: GeoPoint(lat: 28.6740, lon: 77.1310),
    ),
    Place(
      name: 'Rohini Sector 3',
      subtitle: 'North West Delhi',
      point: GeoPoint(lat: 28.7041, lon: 77.1025),
    ),
    Place(
      name: 'Bawana Industrial Area',
      subtitle: 'North West Delhi',
      point: GeoPoint(lat: 28.7983, lon: 77.0435),
    ),
    Place(
      name: 'Dwarka Sector 21',
      subtitle: 'South West Delhi',
      point: GeoPoint(lat: 28.5523, lon: 77.0583),
    ),
    Place(
      name: 'IGI Airport T3',
      subtitle: 'New Delhi',
      point: GeoPoint(lat: 28.5562, lon: 77.0999),
    ),
    Place(name: 'Hauz Khas', subtitle: 'South Delhi', point: GeoPoint(lat: 28.5494, lon: 77.2001)),
    Place(name: 'Saket', subtitle: 'South Delhi', point: GeoPoint(lat: 28.5245, lon: 77.2066)),
    Place(
      name: 'Nehru Place',
      subtitle: 'South East Delhi',
      point: GeoPoint(lat: 28.5494, lon: 77.2517),
    ),
    Place(
      name: 'Lajpat Nagar',
      subtitle: 'South East Delhi',
      point: GeoPoint(lat: 28.5677, lon: 77.2433),
    ),
    Place(
      name: 'RK Puram',
      subtitle: 'South West Delhi',
      point: GeoPoint(lat: 28.5672, lon: 77.1756),
    ),
    Place(name: 'ITO', subtitle: 'Central Delhi', point: GeoPoint(lat: 28.6289, lon: 77.2411)),
    Place(
      name: 'Kashmere Gate ISBT',
      subtitle: 'North Delhi',
      point: GeoPoint(lat: 28.6675, lon: 77.2282),
    ),
    Place(
      name: 'Delhi University North Campus',
      subtitle: 'North Delhi',
      point: GeoPoint(lat: 28.6880, lon: 77.2100),
    ),
    Place(
      name: 'Mayur Vihar Phase 1',
      subtitle: 'East Delhi',
      point: GeoPoint(lat: 28.6045, lon: 77.2940),
    ),
    Place(
      name: 'Okhla Phase 2',
      subtitle: 'South East Delhi',
      point: GeoPoint(lat: 28.5355, lon: 77.2730),
    ),
    Place(name: 'Janakpuri', subtitle: 'West Delhi', point: GeoPoint(lat: 28.6219, lon: 77.0878)),
    Place(name: 'Narela', subtitle: 'North Delhi', point: GeoPoint(lat: 28.8526, lon: 77.0929)),
    Place(
      name: 'Wazirpur',
      subtitle: 'North West Delhi',
      point: GeoPoint(lat: 28.6996, lon: 77.1654),
    ),
  ];

  static List<Place> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return landmarks;
    return [
      for (final p in landmarks)
        if (p.name.toLowerCase().contains(q) || (p.subtitle?.toLowerCase().contains(q) ?? false)) p,
    ];
  }
}
