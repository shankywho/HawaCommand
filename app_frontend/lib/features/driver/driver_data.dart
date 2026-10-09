import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawacommand_app/core/api_client.dart';
import 'package:hawacommand_app/core/geo.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

enum StopStatus {
  todo,
  active,
  done;

  static StopStatus parse(String? value) => switch (value) {
    'done' => StopStatus.done,
    'active' => StopStatus.active,
    _ => StopStatus.todo,
  };
}

class RouteStop {
  const RouteStop({
    required this.number,
    required this.placeHi,
    required this.placeEn,
    required this.action,
    required this.from,
    required this.to,
    required this.status,
    this.point,
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    final placeEn = json['placeEn'] as String? ?? '';
    return RouteStop(
      number: (json['n'] as num).toInt(),
      placeHi: json['placeHi'] as String? ?? placeEn,
      placeEn: placeEn,
      action: json['actionEn'] as String? ?? '',
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      status: StopStatus.parse(json['status'] as String?),
      point: Gazetteer.lookup(placeEn),
    );
  }

  final int number;
  final String placeHi;
  final String placeEn;
  final String action;
  final String from;
  final String to;
  final StopStatus status;
  final LatLng? point;

  String get window => '$from–$to';
  String get subtitle => action.isEmpty ? placeEn : '$placeEn · $action';

  /// The action in Hindi (keyword match; falls back to the English text).
  String get actionHi {
    final a = action.toLowerCase();
    final String base;
    if (a.contains('refill')) {
      base = 'पानी भरें';
    } else if (a.contains('mist') || a.contains('spray')) {
      base = 'छिड़काव';
    } else if (a.contains('dust')) {
      base = 'धूल दबाना';
    } else if (a.contains('sweep')) {
      base = 'सड़क सफ़ाई';
    } else {
      return action;
    }
    final extra = RegExp(r'\(([^)]*)\)').firstMatch(action)?.group(1);
    return extra == null ? base : '$base ($extra)';
  }

  /// English action with a capital first letter (`spray` → `Spray`).
  String get actionEn => action.isEmpty ? action : action[0].toUpperCase() + action.substring(1);
}

class LastSpray {
  const LastSpray({
    required this.placeHi,
    required this.litres,
    required this.pumpMinutes,
    required this.pumpOn,
  });

  factory LastSpray.fromJson(Map<String, dynamic> json) => LastSpray(
    placeHi: json['placeHi'] as String? ?? '',
    litres: (json['litres'] as num?)?.toDouble() ?? 0,
    pumpMinutes: (json['pumpMin'] as num?)?.toDouble() ?? 0,
    pumpOn: json['pumpOn'] as bool? ?? false,
  );

  final String placeHi;
  final double litres;
  final double pumpMinutes;
  final bool pumpOn;
}

class DriverRoute {
  const DriverRoute({
    required this.asset,
    required this.assetLabelHi,
    required this.planId,
    required this.dateLabel,
    required this.window,
    required this.stops,
    this.lastSpray,
  });

  factory DriverRoute.fromJson(Map<String, dynamic> json) => DriverRoute(
    asset: json['asset'] as String? ?? '',
    assetLabelHi: json['assetLabelHi'] as String? ?? '',
    planId: json['planId'] as String? ?? '',
    dateLabel: json['dateLabel'] as String? ?? '',
    window: json['window'] as String? ?? '',
    stops: ((json['stops'] as List<dynamic>?) ?? const [])
        .map((e) => RouteStop.fromJson(e as Map<String, dynamic>))
        .toList(),
    lastSpray: json['lastSpray'] == null
        ? null
        : LastSpray.fromJson(json['lastSpray'] as Map<String, dynamic>),
  );

  final String asset;
  final String assetLabelHi;

  /// The backend only sends a Hindi vehicle label; this is its English form.
  String get assetLabelEn => 'Water sprinkler';
  final String planId;
  final String dateLabel;
  final String window;
  final List<RouteStop> stops;
  final LastSpray? lastSpray;

  /// The plan date parsed from `dateLabel` (`Thursday, 12 Nov 2026`).
  DateTime? get date {
    try {
      return DateFormat('EEEE, d MMM y', 'en').parseLoose(dateLabel);
    } on FormatException {
      return null;
    }
  }

  /// `Thursday, 12 Nov 2026` → `Thu 12 Nov`.
  String get shortDate {
    final m = RegExp(r'^(\w{3})\w*,?\s+(\d{1,2})\s+(\w{3})').firstMatch(
      dateLabel,
    );
    if (m == null) return dateLabel;
    return '${m.group(1)} ${m.group(2)} ${m.group(3)}';
  }

  /// `06:00 – 10:00 IST` → `06:00–10:00`.
  String get shortWindow =>
      window.replaceAll(RegExp(r'\s*[–-]\s*'), '–').replaceAll(RegExp(r'\s*IST$'), '').trim();

  /// The stop the driver should do now: first active, else first not done.
  int get currentIndex {
    final active = stops.indexWhere((s) => s.status == StopStatus.active);
    if (active >= 0) return active;
    final todo = stops.indexWhere((s) => s.status != StopStatus.done);
    return todo >= 0 ? todo : stops.length - 1;
  }

  /// The stop HawaTag last logged a spray at.
  int get sprayedIndex {
    final spray = lastSpray;
    if (spray != null && spray.placeHi.isNotEmpty) {
      final byName = stops.indexWhere(
        (s) => s.placeHi.startsWith(spray.placeHi) || spray.placeHi.startsWith(s.placeHi),
      );
      if (byName >= 0) return byName;
    }
    final lastDone = stops.lastIndexWhere((s) => s.status == StopStatus.done);
    return lastDone >= 0 ? lastDone : 0;
  }

  RouteStop? nextAfter(int index) {
    for (var i = index + 1; i < stops.length; i++) {
      if (stops[i].status != StopStatus.done) return stops[i];
    }
    return null;
  }

  List<LatLng> get points => [
    for (final s in stops)
      if (s.point != null) s.point!,
  ];
}

/// Bundled route that mirrors the design (T-12, Anand Vihar, 12 Nov).
DriverRoute demoRoute(String asset) => DriverRoute(
  asset: asset,
  assetLabelHi: 'पानी छिड़काव गाड़ी',
  planId: 'plan-master-20261112',
  dateLabel: 'Thursday, 12 Nov 2026',
  window: '06:00 – 10:00 IST',
  stops: const [
    RouteStop(
      number: 1,
      placeHi: 'आनंद विहार ISBT रोड',
      placeEn: 'Anand Vihar ISBT road',
      action: 'spray',
      from: '06:10',
      to: '06:50',
      status: StopStatus.todo,
      point: LatLng(28.6469, 77.3159),
    ),
    RouteStop(
      number: 2,
      placeHi: 'पटपड़गंज डिपो · पानी भरें',
      placeEn: 'Patparganj depot',
      action: 'refill',
      from: '07:00',
      to: '07:20',
      status: StopStatus.todo,
      point: LatLng(28.6275, 77.3050),
    ),
    RouteStop(
      number: 3,
      placeHi: 'आनंद विहार · दूसरा चक्कर',
      placeEn: 'Anand Vihar · 2nd pass',
      action: 'spray',
      from: '07:30',
      to: '08:10',
      status: StopStatus.todo,
      point: LatLng(28.6440, 77.3095),
    ),
  ],
);

/// What HawaTag reports for stop 1 in the demo (design screen 02).
const demoSpray = LastSpray(
  placeHi: 'आनंद विहार ISBT रोड',
  litres: 1210,
  pumpMinutes: 32,
  pumpOn: false,
);

final driverRouteProvider = FutureProvider.autoDispose.family<Sourced<DriverRoute>, String>(
  (ref, asset) => ref
      .watch(hawaApiProvider)
      .fetchOrDemo(
        '/v1/driver/route',
        query: {'asset': asset},
        parse: DriverRoute.fromJson,
        demo: () => demoRoute(asset),
      ),
  retry: (retryCount, error) => null,
);

/// Position of the driver's vehicle from `GET /v1/devices`, if the backend
/// knows it.
final vehiclePositionProvider = FutureProvider.autoDispose.family<LatLng?, String>((
  ref,
  asset,
) async {
  final result = await ref
      .watch(hawaApiProvider)
      .fetchOrDemo<LatLng?>(
        '/v1/devices',
        parse: (json) {
          for (final item in (json['items'] as List<dynamic>)) {
            final map = item as Map<String, dynamic>;
            if (map['id'] == asset && map['at'] is List) {
              final at = (map['at'] as List<dynamic>).cast<num>();
              return LatLng(at[1].toDouble(), at[0].toDouble());
            }
          }
          return null;
        },
        demo: () => null,
      );
  return result.data;
}, retry: (retryCount, error) => null);

/// Whether the driver has tapped "Start route" this session.
class RouteRunController extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void start() => state = DateTime.now();

  void stop() => state = null;
}

final routeRunProvider = NotifierProvider<RouteRunController, DateTime?>(
  RouteRunController.new,
);
