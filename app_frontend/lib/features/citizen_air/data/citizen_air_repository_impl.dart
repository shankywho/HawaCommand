import 'dart:convert';

import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/sync/outbox_op.dart';
import 'package:hawa_app/core/sync/outbox_repository.dart';
import 'package:hawa_app/core/utils/clock.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/core/utils/geo.dart';
import 'package:hawa_app/core/utils/localized_text.dart';
import 'package:hawa_app/features/citizen_air/data/open_air_remote_source.dart';
import 'package:hawa_app/features/citizen_air/data/subscription_remote_source.dart';
import 'package:hawa_app/features/citizen_air/domain/air_snapshot.dart';
import 'package:hawa_app/features/citizen_air/domain/alert_subscription.dart';
import 'package:hawa_app/features/citizen_air/domain/citizen_air_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'citizen_air_repository_impl.g.dart';

/// Cache-first air near me (`cached_payloads`, key per snapped box) and the alert subscription
/// (cached copy + outbox `profile_update`, field `alert_subscription`).
class CitizenAirRepositoryImpl implements CitizenAirRepository {
  CitizenAirRepositoryImpl({
    required this.db,
    required this.openAir,
    required this.subscriptions,
    required this.outbox,
    required this.now,
  });

  final AppDatabase db;
  final OpenAirRemoteSource openAir;
  final SubscriptionRemoteSource subscriptions;
  final OutboxRepository outbox;
  final DateTime Function() now;

  static String airKey(GeoBox box) => 'open_air:${box.toQuery()}';
  static const subscriptionKey = 'alert_subscription';

  @override
  Stream<CachedAir?> watchAir(GeoBox box) => db.cacheDao
      .watchJson(airKey(box))
      .map(
        (c) => c == null
            ? null
            : CachedAir(snapshot: snapshotFromJson(c.json), fetchedAt: c.fetchedAt),
      );

  @override
  Future<void> refreshAir(GeoBox box) async {
    final out = await openAir.air(box.toQuery());
    final json = jsonDecode(jsonEncode(out.toJson())) as Map<String, Object?>;
    final snapshot = snapshotFromJson(json);
    await db.cacheDao.putJson(
      airKey(box),
      json,
      fetchedAt: now().toUtc(),
      expiresAt: now().toUtc().add(const Duration(days: 1)),
      isSimulated: snapshot.anySimulated,
    );
  }

  @override
  Stream<AlertSubscriptionPrefs?> watchSubscription() => db.cacheDao
      .watchJson(subscriptionKey)
      .map((c) => c == null ? null : subscriptionFromJson(c.json));

  @override
  Future<void> refreshSubscription() async {
    final key = OrderingKeys.profile('alert_subscription');
    if (await db.outboxDao.hasLiveOp(OpKind.profileUpdate.wire, key)) return;
    final sub = await subscriptions.get();
    final json = jsonDecode(jsonEncode(sub.toJson())) as Map<String, Object?>;
    await db.cacheDao.putJson(subscriptionKey, json, fetchedAt: now().toUtc());
  }

  @override
  Future<void> saveSubscription(AlertSubscriptionPrefs prefs) async {
    final body = subscriptionToJson(prefs);
    await db.transaction(() async {
      await db.cacheDao.putJson(subscriptionKey, body, fetchedAt: now().toUtc());
      await outbox.enqueue(
        kind: OpKind.profileUpdate,
        orderingKey: OrderingKeys.profile('alert_subscription'),
        coalesceKey: OrderingKeys.profile('alert_subscription'),
        payload: {'field': 'alert_subscription', 'body': body},
      );
    });
  }

  @override
  Future<LocalizedText?> placeFor(GeoPoint point) async {
    final cached = await db.cacheDao.getJson(airKey(Geo.snappedBox(point)));
    if (cached == null) return null;
    return AirPick.of(snapshotFromJson(cached.json), point).cell?.placeName;
  }

  // ---- mapping (pure, unit tested) --------------------------------------------------------

  static AirSnapshot snapshotFromJson(Map<String, Object?> json) {
    final cells = <AirCell>[];
    for (final f in (json['features'] as List<Object?>?) ?? const []) {
      if (f is! Map<String, Object?>) continue;
      final props = (f['properties'] as Map<String, Object?>?) ?? const {};
      final coords =
          ((f['geometry'] as Map<String, Object?>?)?['coordinates'] as List<Object?>?) ?? const [];
      final ring = <List<double>>[
        if (coords.isNotEmpty)
          for (final p in coords.first! as List<Object?>)
            if (p is List && p.length >= 2) [(p[0] as num).toDouble(), (p[1] as num).toDouble()],
      ];
      final name = props['place_name'];
      cells.add(
        AirCell(
          cellId: props['cell_id'] as String? ?? f['id'] as String? ?? '',
          ring: ring,
          aqi: (props['aqi'] as num?)?.toInt() ?? 0,
          category: AqiCategory.fromWire(props['aqi_category'] as String?),
          confidence: (props['confidence'] as num?)?.toDouble() ?? 0,
          isSimulated: props['is_simulated'] as bool? ?? false,
          dominant: Pollutant.fromWire(props['dominant_pollutant'] as String?),
          cause: CauseLabel.fromWire(props['cause_label'] as String?),
          causeConf: (props['cause_conf'] as num?)?.toDouble(),
          pm25: (props['pm25'] as num?)?.toDouble(),
          pm10: (props['pm10'] as num?)?.toDouble(),
          no2Ppb: (props['no2_ppb'] as num?)?.toDouble(),
          placeName: name is Map<String, Object?> && name['en'] is String
              ? LocalizedText.fromJson(name)
              : null,
        ),
      );
    }
    final alt = (json['advice'] as Map<String, Object?>?)?['alt_route'];
    return AirSnapshot(
      asOf: DateTime.tryParse(json['as_of'] as String? ?? '')?.toUtc() ?? DateTime.now().toUtc(),
      cells: cells,
      altRoute: alt is Map<String, Object?> && alt['en'] is String
          ? LocalizedText.fromJson(alt)
          : null,
      attribution: (json['licence'] as Map<String, Object?>?)?['attribution'] as String?,
    );
  }

  static AlertSubscriptionPrefs subscriptionFromJson(Map<String, Object?> json) {
    final home = json['home'] as Map<String, Object?>?;
    final quiet = json['quiet_hours'] as Map<String, Object?>?;
    final kinds = [for (final k in (json['kinds'] as List<Object?>?) ?? const []) k.toString()];
    final name = json['place_name'];
    return AlertSubscriptionPrefs(
      home: home == null || home['lat'] is! num
          ? null
          : GeoPoint(lat: (home['lat']! as num).toDouble(), lon: (home['lon']! as num).toDouble()),
      placeName: name is Map<String, Object?> && name['en'] is String
          ? LocalizedText.fromJson(name)
          : null,
      radiusM: (json['radius_m'] as num?)?.toInt() ?? 1000,
      warnings: kinds.isEmpty || kinds.contains(AlertSubscriptionPrefs.kindWarning),
      grapOutlook: kinds.isEmpty || kinds.contains(AlertSubscriptionPrefs.kindGrap),
      quietStart: quiet?['start'] as String? ?? '22:00',
      quietEnd: quiet?['end'] as String? ?? '06:00',
    );
  }

  /// The home is rounded to 0.005° before it leaves the phone (SCREENS C2).
  static Map<String, Object?> subscriptionToJson(AlertSubscriptionPrefs p) {
    final home = p.home == null ? null : Geo.coarse(p.home!);
    return {
      if (home != null) 'home': {'lat': home.lat, 'lon': home.lon},
      if (p.placeName != null) 'place_name': p.placeName!.toJson(),
      'radius_m': p.radiusM,
      'kinds': p.kinds,
      'quiet_hours': {'start': p.quietStart, 'end': p.quietEnd},
    };
  }
}

@riverpod
CitizenAirRepository citizenAirRepository(Ref ref) => CitizenAirRepositoryImpl(
  db: ref.watch(appDatabaseProvider),
  openAir: ref.watch(openAirRemoteSourceProvider),
  subscriptions: ref.watch(subscriptionRemoteSourceProvider),
  outbox: ref.watch(outboxRepositoryProvider),
  now: ref.watch(appClockProvider).now,
);
