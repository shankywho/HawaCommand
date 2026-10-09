import 'package:flutter_test/flutter_test.dart';
import 'package:hawacommand_app/core/air.dart';
import 'package:hawacommand_app/core/geo.dart';
import 'package:hawacommand_app/features/driver/driver_data.dart';
import 'package:hawacommand_app/features/school/school_data.dart';

/// Shapes copied from the backend fixtures (`backend/src/hawa_backend/api`).
void main() {
  group('DriverRoute from GET /v1/driver/route', () {
    final route = DriverRoute.fromJson({
      'asset': 'T-12',
      'assetLabelHi': 'वॉटर स्प्रिंकलर १२',
      'planId': 'plan-master-20261112',
      'dateLabel': 'Thursday, 12 Nov 2026',
      'window': '06:00 – 10:00 IST',
      'stops': [
        {
          'n': 1,
          'placeHi': 'मुंडका मुख्य मार्ग, मेट्रो पिलर ३४०-३६०',
          'placeEn': 'Mundka Main Road, Metro Pillars 340-360',
          'actionEn': 'Continuous median misting',
          'from': '06:10',
          'to': '07:20',
          'status': 'done',
        },
        {
          'n': 2,
          'placeHi': 'रोहतक रोड जंक्शन, उद्योग नगर',
          'placeEn': 'Rohtak Road Junction, Udyog Nagar',
          'actionEn': 'Shoulder dust suppression',
          'from': '07:35',
          'to': '08:45',
          'status': 'active',
        },
        {
          'n': 3,
          'placeHi': 'नांगलोई डिपो वाटर फिलिंग स्टेशन',
          'placeEn': 'Nangloi Depot Water Refill Station',
          'actionEn': 'Water refill (5,000 L)',
          'from': '09:00',
          'to': '09:30',
          'status': 'todo',
        },
      ],
      'lastSpray': {
        'placeHi': 'मुंडका मुख्य मार्ग',
        'litres': 1420.0,
        'pumpMin': 22.0,
        'pumpOn': true,
      },
    });

    test('formats the header like the design', () {
      expect(route.shortDate, 'Thu 12 Nov');
      expect(route.shortWindow, '06:00–10:00');
    });

    test('current stop is the active one', () {
      expect(route.currentIndex, 1);
    });

    test('matches the sprayed stop by Hindi name and finds the next stop', () {
      expect(route.sprayedIndex, 0);
      expect(route.nextAfter(route.sprayedIndex)?.number, 2);
      expect(route.lastSpray?.litres, 1420);
    });

    test('resolves stop coordinates from the gazetteer', () {
      expect(route.points, hasLength(3));
    });
  });

  test('demo route mirrors design screen 01/02', () {
    final route = demoRoute('T-12');
    expect(route.currentIndex, 0);
    final next = route.nextAfter(0)!;
    expect(next.placeHi, 'पटपड़गंज डिपो · पानी भरें');
    expect(
      formatKm(distanceKm(route.stops[0].point!, next.point!)),
      '2.4 km',
    );
  });

  test('school alert chip is built from the message text', () {
    expect(
      SchoolAlert.chipFor(
        'High PM2.5 (380 ug/m3) expected at 08:00. Safe window: 12:30 to 14:00.',
      ),
      'PM2.5 ~380 · 8 AM',
    );
    expect(SchoolAlert.chipFor('No numbers here'), 'AIR ALERT');
  });

  test('hotspot parses [lon, lat] into LatLng', () {
    final h = Hotspot.fromJson({
      'cellId': 'ghazipur',
      'place': 'Ghazipur',
      'at': [77.329, 28.625],
      'pm25': 388,
      'cause': 'Burning',
      'causeConf': 0.79,
      'suspectPin': {'label': 'Landfill edge, open burning'},
      'assets': ['I-3', 'T-12'],
    });
    expect(h.point.latitude, 28.625);
    expect(h.point.longitude, 77.329);
    expect(PmBand.of(h.pm25), PmBand.severe);
  });
}
