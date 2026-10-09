import 'package:flutter_test/flutter_test.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/core/utils/geo.dart';
import 'package:hawa_app/features/air_map/data/air_map_mapper.dart';
import 'package:hawa_app/features/air_map/domain/air_data.dart';
import 'package:hawa_app/features/air_map/domain/pollution_grid.dart';
import 'package:hawa_app/features/alerts/data/command_center_alerts_source.dart';
import 'package:hawa_app/features/citizen_air/data/citizen_air_repository_impl.dart';
import 'package:hawa_app/features/citizen_air/data/command_center_open_air_source.dart';
import 'package:hawa_app/features/school/data/school_remote_source.dart';
import 'package:hawa_app/features/school/domain/school_models.dart';

import '../../helpers/fixtures.dart';

/// The adapters that turn the live backend's payloads (captured into fixtures) into app models.
void main() {
  group('AirMapMapper (live /v1/hotspots, /v1/forecast)', () {
    test('hotspots: [lon, lat], band word and cause word map to enums', () {
      final spots = AirMapMapper.hotspots(fixtureJson('air_map/hotspots.json'));
      expect(spots, hasLength(10));
      expect(spots.first.rank, 1);
      expect(spots.first.category, AqiCategory.severe);
      expect(spots.first.cause, CauseLabel.dust);
      expect(spots.first.location.lat, closeTo(28.679, 1e-6));
      expect(spots.first.schools, isNotEmpty);
    });

    test('forecast: GRAP stage from roman numerals and ordered quantiles', () {
      final fc = AirMapMapper.forecast({
        'issuedAt': '2026-10-03T14:00:00Z',
        'grap': {'stage': 'II', 'probability': 0.85},
        'series': [
          {'h': 0, 'p10': 160, 'p50': 200, 'p90': 250},
          {'h': 1, 'p10': 252, 'p50': 197, 'p90': 161}, // swapped upstream
        ],
      });
      expect(fc.grapStage, 2);
      expect(fc.series[1].p10, 161);
      expect(fc.series[1].p90, 252);
      expect(fc.factorAt(1), closeTo(197 / 200, 1e-9));
    });

    test('pm25At blends a nearby hotspot over the 500 m twin', () {
      final grid = PollutionGrid.fromCompact(fixtureJson('air_map/twin_grid.json'));
      final hot = AirMapMapper.hotspots(fixtureJson('air_map/hotspots.json')).first;
      final data = AirMapData(
        grid: grid,
        hotspots: [hot],
        forecast: null,
        fetchedAt: DateTime.utc(2026),
      );
      final atHotspot = data.pm25At(hot.location)!;
      expect(atHotspot, closeTo(hot.pm25, 1));
      final far = data.pm25At(const GeoPoint(lat: 28.55, lon: 77.25))!;
      expect(far, lessThan(atHotspot));
    });
  });

  group('Air near me from the twin (CommandCenterOpenAirSource)', () {
    test('twin cells become open-air features with AQI, category and nearest-hotspot cause', () {
      final twin = fixtureJson('air_map/twin_sample.json');
      final first = (twin['cells']! as List).first as Map;
      final fc = CommandCenterOpenAirSource.featureCollection(twin, {
        'simulated': true,
        'items': [
          {
            'at': [first['longitude'], first['latitude']],
            'cause': 'Dust',
            'causeConf': 0.4,
          },
        ],
      });
      final snapshot = CitizenAirRepositoryImpl.snapshotFromJson(fc);
      expect(snapshot.cells, hasLength(3));
      final cell = snapshot.cells.first;
      expect(cell.aqi, greaterThan(0));
      expect(cell.category, isNot(AqiCategory.unknown));
      expect(cell.cause, CauseLabel.dust);
      expect(cell.ring, hasLength(5));
      expect(cell.isSimulated, isTrue);
    });
  });

  group('Alerts from the command-center broadcast log', () {
    final json = {
      'simulated': true,
      'items': [
        {
          'id': 'alt-01',
          'sentAt': '2026-10-03T14:00:00Z',
          'audience': 'School',
          'target': '3 schools in Mundka',
          'message': 'High PM2.5 expected at 08:00.',
          'messageHi': 'सुबह 8:00 बजे उच्च PM2.5 की आशंका।',
        },
        {
          'id': 'alt-02',
          'sentAt': '2026-10-03T14:00:00Z',
          'audience': 'Citizens',
          'message': 'Peak 07:00–09:30.',
        },
      ],
    };

    test('maps audience, kind, prefixes ids and picks the UI language', () {
      final hi = CommandCenterAlertsSource.items(json, lang: 'hi');
      expect(hi.first['id'], 'cc:alt-01');
      expect(hi.first['audience'], 'school');
      expect(hi.first['kind'], 'safe_window');
      expect(hi.first['lang'], 'hi');
      expect(hi.last['audience'], 'citizen');
      expect(hi.last['lang'], 'en'); // no Hindi text: English, flagged by lang
      final en = CommandCenterAlertsSource.items(json, lang: 'en');
      expect(en.first['body'], 'High PM2.5 expected at 08:00.');
    });
  });

  group('School forecast from /v1/forecast/{cell}', () {
    test('reshapes h-offsets to valid_at and keeps P10 ≤ P50 ≤ P90', () {
      final out = CommandCenterForecastSource.reshape({
        'issuedAt': '2026-10-03T14:00:00Z',
        'series': [
          {'h': 0, 'p10': 150, 'p50': 190, 'p90': 240},
          {'h': 3, 'p10': 255, 'p50': 177, 'p90': 112},
        ],
      });
      final fc = CellForecast.fromJson(out);
      expect(fc.series, hasLength(2));
      expect(fc.series[1].at, DateTime.utc(2026, 10, 3, 17));
      expect(fc.series[1].p10, 112);
      expect(fc.series[1].p90, 255);
    });
  });
}
