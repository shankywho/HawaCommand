import 'package:flutter_test/flutter_test.dart';
import 'package:hawa_app/core/utils/geo.dart';
import 'package:hawa_app/features/air_map/domain/pollution_grid.dart';

import '../../helpers/fixtures.dart';

void main() {
  group('PollutionGrid', () {
    test('loads the captured AI-ML twin (106 × 100 cells over Delhi)', () {
      final grid = PollutionGrid.fromCompact(fixtureJson('air_map/twin_grid.json'));
      expect(grid.rows, 106);
      expect(grid.cols, 100);
      expect(grid.contains(const GeoPoint(lat: 28.6315, lon: 77.2167)), isTrue); // Connaught Place
      expect(grid.contains(const GeoPoint(lat: 19.07, lon: 72.87)), isFalse); // Mumbai
      final (lo, hi) = grid.pm25Range;
      expect(lo, greaterThan(50));
      expect(hi, greaterThan(lo));
    });

    test('infers geometry from wire cells and interpolates between centres', () {
      final cells = [
        for (var r = 0; r < 2; r++)
          for (var c = 0; c < 2; c++)
            {
              'row': r,
              'col': c,
              'latitude': 28.0 + r * 0.01,
              'longitude': 77.0 + c * 0.01,
              'pm25_est': 100.0 + 100 * c, // west 100, east 200
              'confidence': 0.7,
              'ward': 'W',
            },
      ];
      final grid = PollutionGrid.fromCells(cells, asOf: DateTime.utc(2026));
      expect(grid.dLat, closeTo(0.01, 1e-9));
      expect(grid.dLon, closeTo(0.01, 1e-9));
      // Halfway between the west and east centres.
      expect(grid.pm25At(const GeoPoint(lat: 28.005, lon: 77.005)), closeTo(150, 1e-6));
      final cell = grid.cellAt(const GeoPoint(lat: 28, lon: 77.0099));
      expect(cell?.cellId, 'G-000-001');
      expect(cell?.ward, 'W');
    });

    test('compact round trip keeps values (0.1 µg/m³) and missing cells', () {
      final grid = PollutionGrid.fromCells(
        [
          {
            'row': 0,
            'col': 0,
            'latitude': 28.0,
            'longitude': 77.0,
            'pm25_est': 123.44,
            'confidence': 0.5,
          },
          {
            'row': 1,
            'col': 1,
            'latitude': 28.01,
            'longitude': 77.01,
            'pm25_est': 99.0,
            'confidence': 0.6,
          },
        ],
        asOf: DateTime.utc(2026),
      );
      final back = PollutionGrid.fromCompact(grid.toCompact());
      expect(back.valueAt(0, 0), closeTo(123.4, 1e-3));
      expect(back.valueAt(0, 1).isNaN, isTrue);
      final (lo, hi) = back.quantiles(0, 1);
      expect(lo, closeTo(99, 1e-3));
      expect(hi, closeTo(123.4, 1e-3));
    });
  });
}
