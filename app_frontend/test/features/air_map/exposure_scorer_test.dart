import 'package:flutter_test/flutter_test.dart';
import 'package:hawa_app/core/utils/geo.dart';
import 'package:hawa_app/features/air_map/domain/departure_planner.dart';
import 'package:hawa_app/features/air_map/domain/detour_planner.dart';
import 'package:hawa_app/features/air_map/domain/exposure_scorer.dart';
import 'package:hawa_app/features/air_map/domain/route_option.dart';
import 'package:hawa_app/features/air_map/domain/travel_mode.dart';

/// A straight east-west line of [km] kilometres at Delhi's latitude.
List<GeoPoint> line(double km, {double lat = 28.6, int points = 11}) => [
  for (var i = 0; i < points; i++) GeoPoint(lat: lat, lon: 77.0 + km / 97.8 * i / (points - 1)),
];

RouteOption option(String id, {required double minutes, required double dose, double avg = 150}) =>
    RouteOption(
      id: id,
      geometry: line(5),
      distanceM: 5000,
      durationS: minutes * 60,
      exposure: RouteExposure(
        avgPm25: avg,
        maxPm25: avg,
        doseUg: dose,
        doseLowUg: dose,
        doseHighUg: dose,
        redZoneMinutes: 0,
        runs: const [],
        coverage: 1,
      ),
    );

void main() {
  group('ExposureScorer.score', () {
    test('uniform air: dose = PM2.5 × breathing × infiltration × time', () {
      final e = ExposureScorer.score(
        geometry: line(5),
        durationS: 1800, // 30 min
        field: (_, _) => 200,
        mode: TravelMode.walk, // 1.3 m³/h, infiltration 1
      );
      expect(e.avgPm25, closeTo(200, 1e-6));
      expect(e.doseUg, closeTo(200 * 1.3 * 0.5, 1e-6));
      expect(e.redZoneMinutes, closeTo(30, 1e-6)); // 200 > 120
      expect(e.coverage, 1);
    });

    test('a closed car breathes less than a cyclist on the same route', () {
      double field(GeoPoint _, double _) => 150;
      final car = ExposureScorer.score(
        geometry: line(5),
        durationS: 900,
        field: field,
        mode: TravelMode.car,
      );
      final bike = ExposureScorer.score(
        geometry: line(5),
        durationS: 900,
        field: field,
        mode: TravelMode.cycle,
      );
      expect(car.doseUg, lessThan(bike.doseUg));
    });

    test('the field is read at the hour the traveller passes there', () {
      // Air gets twice as bad from 1 h after departure.
      double field(GeoPoint _, double h) => h >= 1 ? 200 : 100;
      final now = ExposureScorer.score(
        geometry: line(5),
        durationS: 3600,
        field: field,
        mode: TravelMode.walk,
      );
      final later = ExposureScorer.score(
        geometry: line(5),
        durationS: 3600,
        field: field,
        mode: TravelMode.walk,
        departureHoursAhead: 1,
      );
      expect(now.avgPm25, closeTo(100, 1));
      expect(later.avgPm25, closeTo(200, 1));
    });

    test('the coloured line is split into runs of at most ~400 m', () {
      final e = ExposureScorer.score(
        geometry: line(4, points: 41), // 100 m segments
        durationS: 600,
        field: (_, _) => 150,
        mode: TravelMode.car,
      );
      expect(e.runs.length, greaterThanOrEqualTo(8));
      expect(e.runs.every((r) => r.avgPm25 == 150), isTrue);
    });

    test('gaps outside the model take the route mean, so they do not flatter a route', () {
      final e = ExposureScorer.score(
        geometry: line(5),
        durationS: 1800,
        field: (p, _) => p.lon < 77.025 ? 200 : null,
        mode: TravelMode.walk,
      );
      expect(e.coverage, lessThan(1));
      expect(e.doseUg, closeTo(200 * 1.3 * 0.5, 1));
    });
  });

  group('ExposureScorer.rank', () {
    test('tags fastest, cleanest air and recommended', () {
      final ranked = ExposureScorer.rank([
        option('fast', minutes: 20, dose: 100, avg: 200),
        option('clean', minutes: 24, dose: 80, avg: 130),
        option('slow', minutes: 45, dose: 85, avg: 120),
      ]);
      final byId = {for (final r in ranked) r.id: r};
      expect(byId['fast']!.tags, contains(RouteTag.fastest));
      expect(byId['slow']!.tags, contains(RouteTag.cleanest)); // lowest average PM2.5
      expect(ranked.first.id, 'clean'); // 20 % less dose for +20 % time wins
      expect(ranked.first.tags, contains(RouteTag.recommended));
    });

    test('a long detour that saves little is not recommended', () {
      final ranked = ExposureScorer.rank([
        option('fast', minutes: 20, dose: 100),
        option('detour', minutes: 40, dose: 95),
      ]);
      expect(ranked.first.id, 'fast');
    });

    test('dedupe drops routes within 2 % on both length and time', () {
      final out = ExposureScorer.dedupe<(double, double)>(
        [(10000, 900), (10100, 905), (12000, 900)],
        (r) => r.$1,
        (r) => r.$2,
      );
      expect(out, [(10000.0, 900.0), (12000.0, 900.0)]);
    });
  });

  group('DetourPlanner', () {
    test('steers sideways around a dirty band crossing the route', () {
      final route = line(10);
      // A north-south band of bad air in the middle; clean everywhere else.
      double field(GeoPoint p, double _) =>
          (p.lon - 77.051).abs() < 0.01 && (p.lat - 28.6).abs() < 0.008 ? 300 : 100;
      final vias = DetourPlanner.viaPoints(route: route, field: field);
      expect(vias, isNotEmpty);
      for (final v in vias) {
        expect((v.lat - 28.6).abs(), greaterThan(0.009)); // left or right of the route, not on it
      }
    });

    test('no detour for a short trip', () {
      expect(DetourPlanner.viaPoints(route: line(0.8), field: (_, _) => 200), isEmpty);
    });
  });

  group('DeparturePlanner', () {
    test('suggests a later start only when it saves at least 10 %', () {
      final route = option('r', minutes: 30, dose: 0);
      double improving(GeoPoint _, double h) => 200 - 20 * h; // cleaner every hour
      final options = DeparturePlanner.options(
        route: route,
        field: improving,
        mode: TravelMode.walk,
        hours: 3,
      );
      expect(options, hasLength(4));
      expect(DeparturePlanner.best(options)?.hoursAhead, 3);
      final flat = DeparturePlanner.options(
        route: route,
        field: (_, _) => 150,
        mode: TravelMode.walk,
        hours: 3,
      );
      expect(DeparturePlanner.best(flat), isNull);
    });
  });
}
