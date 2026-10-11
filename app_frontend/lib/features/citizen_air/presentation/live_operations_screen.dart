import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawa_app/app/env.dart';
import 'package:hawa_app/app/theme.dart';
import 'package:hawa_app/core/network/command_center_api.dart';
import 'package:hawa_app/core/widgets/simulated_screen_chip.dart';
import 'package:logging/logging.dart';
import 'package:web_socket_channel/io.dart';

/// Govt in Action Radar Screen (`/citizen/live-ops`).
///
/// Loads `GET /v1/citizen/live-operations` (live HawaTag vehicles first, then the simulated demo
/// fleet), refreshes it every 15 s, and applies each ping from the `/v1/ws/fleet` WebSocket as it
/// arrives. Without a reachable backend (or with `citizen_air` on the fake backend) it shows the
/// built-in demo list below.
class LiveOperationsScreen extends ConsumerStatefulWidget {
  const LiveOperationsScreen({super.key});

  @override
  ConsumerState<LiveOperationsScreen> createState() => _LiveOperationsScreenState();
}

class _LiveOperationsScreenState extends ConsumerState<LiveOperationsScreen> {
  static final _log = Logger('live-ops');

  int _activeTab = 0; // 0 = Active Fleet, 1 = Verified Impact

  List<Map<String, Object>> _activeFleet = List.of(_demoFleet);
  List<Map<String, Object>> _verifiedImpacts = List.of(_demoImpacts);
  bool _live = false;
  Timer? _poll;
  Timer? _reconnect;
  IOWebSocketChannel? _socket;
  StreamSubscription<Object?>? _socketSub;

  static const _demoFleet = <Map<String, Object>>[
    {
      'id': 'SPR-04',
      'name': 'MCD Heavy Sprinkler #04',
      'type': 'Water Sprinkler',
      'ward': 'Preet Vihar / Anand Vihar',
      'status': 'ACTIVE SPRAYING',
      'speed': '14.5 km/h',
      'pump_flow': '48.2 L/min',
      'water_disbursed': '1,420 L',
      'contractor': 'MCD East Zone Depot',
      'is_active': true,
    },
    {
      'id': 'SMG-12',
      'name': 'High-Reach Anti-Smog Gun #12',
      'type': 'Anti-Smog Gun',
      'ward': 'Punjabi Bagh Ring Corridor',
      'status': 'ACTIVE MISTING',
      'speed': '8.0 km/h',
      'pump_flow': '62.0 L/min',
      'water_disbursed': '2,100 L',
      'contractor': 'MCD West Zone Fleet',
      'is_active': true,
    },
    {
      'id': 'SWP-07',
      'name': 'Vacuum Mechanical Sweeper #07',
      'type': 'Mechanical Sweeper',
      'ward': 'Okhla Phase-II Industrial Outskirts',
      'status': 'DEPOT STANDBY',
      'speed': '0.0 km/h',
      'pump_flow': '0.0 L/min',
      'water_disbursed': '0 L',
      'contractor': 'Delhi Clean Consortium',
      'is_active': false,
    },
  ];

  static const _demoImpacts = <Map<String, Object>>[
    {
      'id': 'INT-202610060601',
      'sector': 'Anand Vihar / Preet Vihar Cluster',
      'cell': 'G-052-054',
      'action': 'Water Sprinkler (SPR-04)',
      'treated_at': 'Today, 08:15 AM (45m ago)',
      'pm10_drop': '-18.5%',
      'pm25_drop': '-6.2%',
      'duration': '90 Minutes',
      'water': '1,420 Liters',
      'verified_by': 'Causal Synthetic Control vs Untreated Donor Cells',
    },
    {
      'id': 'INT-202609291046',
      'sector': 'Punjabi Bagh Ring Road Flyover',
      'cell': 'G-048-032',
      'action': 'Anti-Smog Gun (SMG-12)',
      'treated_at': 'Today, 07:30 AM (1h 30m ago)',
      'pm10_drop': '-14.0%',
      'pm25_drop': '-5.0%',
      'duration': '75 Minutes',
      'water': '2,100 Liters',
      'verified_by': 'Causal Synthetic Control vs Untreated Donor Cells',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (Env.isFake('citizen_air')) return;
    unawaited(_refresh());
    _poll = Timer.periodic(const Duration(seconds: 15), (_) => unawaited(_refresh()));
    unawaited(_connect());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _reconnect?.cancel();
    unawaited(_socketSub?.cancel());
    unawaited(_socket?.sink.close());
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final data = await ref.read(commandCenterApiProvider).liveOperations();
      final fleet = [
        for (final v in (data['active_fleet'] as List<Object?>? ?? const []))
          if (v is Map<String, Object?>) _fromLiveOps(v),
      ];
      final impacts = [
        for (final v in (data['verified_interventions'] as List<Object?>? ?? const []))
          if (v is Map<String, Object?>) _fromImpact(v),
      ];
      if (!mounted) return;
      setState(() {
        if (fleet.isNotEmpty) _activeFleet = fleet;
        if (impacts.isNotEmpty) _verifiedImpacts = impacts;
        _live = ((data['live_fleet_count'] as num?) ?? 0) > 0;
      });
    } on Object catch (e) {
      _log.fine('live operations refresh failed', e);
    }
  }

  Future<void> _connect() async {
    try {
      final socket = await WebSocket.connect(
        '${Env.wsUrl}/fleet',
      ).timeout(const Duration(seconds: 10));
      if (!mounted) {
        unawaited(socket.close());
        return;
      }
      final channel = IOWebSocketChannel(socket);
      _socket = channel;
      _socketSub = channel.stream.listen(
        _onSocketMessage,
        onError: (Object e) => _log.fine('fleet socket error', e),
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
    } on Object catch (e) {
      _log.fine('fleet socket connect failed', e);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (!mounted) return;
    _reconnect?.cancel();
    _reconnect = Timer(const Duration(seconds: 10), () => unawaited(_connect()));
  }

  void _onSocketMessage(Object? raw) {
    if (raw is! String || !mounted) return;
    final Object? msg;
    try {
      msg = jsonDecode(raw);
    } on FormatException {
      return;
    }
    if (msg is! Map<String, Object?> || msg['type'] != 'ping') return;
    final item = msg['item'];
    if (item is! Map<String, Object?>) return;
    final row = _fromPing(item);
    setState(() {
      final i = _activeFleet.indexWhere((f) => f['id'] == row['id']);
      _activeFleet = List.of(_activeFleet);
      if (i >= 0) {
        _activeFleet[i] = row;
      } else {
        _activeFleet.insert(0, row);
      }
      _live = true;
    });
  }

  static const _typeLabels = {
    'water_sprinkler': 'Water Sprinkler',
    'sprinkler': 'Water Sprinkler',
    'anti_smog_gun': 'Anti-Smog Gun',
    'smog_gun': 'Anti-Smog Gun',
    'mechanical_sweeper': 'Mechanical Sweeper',
    'sweeper': 'Mechanical Sweeper',
  };

  static const _pingStatus = {
    'Spraying': 'ACTIVE_SPRAYING',
    'En route': 'EN_ROUTE',
    'Idle': 'IDLE',
    'Offline': 'OFFLINE',
  };

  static num _num(Object? v) => v is num ? v : 0;

  static Map<String, Object> _row({
    required String id,
    required String typeKey,
    required String ward,
    required String status,
    required num speed,
    required num flow,
    required num litres,
    required bool live,
    String? contractor,
  }) {
    final type = _typeLabels[typeKey] ?? 'Water Sprinkler';
    return {
      'id': id,
      'name': '$type $id',
      'type': type,
      'ward': ward,
      'status': status.replaceAll('_', ' '),
      'speed': '${speed.toStringAsFixed(1)} km/h',
      'pump_flow': '${flow.toStringAsFixed(1)} L/min',
      'water_disbursed': '${litres.round()} L',
      'contractor': contractor ?? (live ? 'Live HawaTag telemetry' : 'Simulated'),
      'is_active': status.startsWith('ACTIVE') || status == 'EN_ROUTE',
    };
  }

  /// One `active_fleet` entry of `GET /v1/citizen/live-operations`.
  static Map<String, Object> _fromLiveOps(Map<String, Object?> v) => _row(
    id: v['asset_id']?.toString() ?? '?',
    typeKey: v['type']?.toString() ?? '',
    ward: v['ward']?.toString() ?? 'Delhi',
    status: v['status']?.toString() ?? 'IDLE',
    speed: _num(v['speed_kmh']),
    flow: _num(v['water_pump_flow_lpm']),
    litres: _num(v['water_disbursed_liters']),
    live: v['live'] == true,
    contractor: v['contractor_id']?.toString(),
  );

  /// One `ping` item from the `/v1/ws/fleet` WebSocket.
  static Map<String, Object> _fromPing(Map<String, Object?> v) => _row(
    id: v['asset_id']?.toString() ?? '?',
    typeKey: v['kind']?.toString() ?? '',
    ward: v['area']?.toString() ?? 'Delhi',
    status: _pingStatus[v['status']?.toString()] ?? 'IDLE',
    speed: _num(v['speed_kmh']),
    flow: _num(v['pump_flow_lpm']),
    litres: _num(v['litres_cum']),
    live: true,
  );

  static Map<String, Object> _fromImpact(Map<String, Object?> v) {
    String pct(Object? x) => x is num ? '-${x.abs().toStringAsFixed(1)}%' : '-';
    return {
      'id': v['intervention_id']?.toString() ?? '',
      'sector': v['location_name']?.toString() ?? '',
      'cell': v['intervention_id']?.toString() ?? '',
      'action': '${v['action_type'] ?? ''} (${v['asset_id'] ?? ''})',
      'treated_at': v['treated_time']?.toString() ?? '',
      'pm10_drop': pct(v['pm10_reduction_pct']),
      'pm25_drop': pct(v['pm25_reduction_pct']),
      'duration': '${v['duration_minutes'] ?? '-'} Minutes',
      'water': '${v['water_disbursed_liters'] ?? '-'} Liters',
      'verified_by': v['verified_by']?.toString() ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HawaColors.paper,
      appBar: AppBar(
        title: const Text('Govt in Action Radar'),
        backgroundColor: HawaColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_live)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SimulatedScreenChip(),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: HawaColors.line),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified, color: HawaColors.teal, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RADICAL CIVIC TRANSPARENCY', style: HawaText.sans(11, weight: FontWeight.w700, color: HawaColors.teal)),
                      const SizedBox(height: 2),
                      Text(
                        'Live tracking of MCD dust-suppression machinery backed by mathematical causal verification.',
                        style: HawaText.sans(12, color: HawaColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Tab Switcher
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                Expanded(
                  child: _tabButton('ACTIVE FLEET (${_activeFleet.where((f) => f['is_active'] as bool).length})', 0),
                ),
                Expanded(
                  child: _tabButton('VERIFIED IMPACT (${_verifiedImpacts.length})', 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_activeTab == 0) ..._buildActiveFleetList() else ..._buildVerifiedImpactList(),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final isSelected = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? HawaColors.ink : HawaColors.muted,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActiveFleetList() {
    return _activeFleet.map((truck) {
      final isActive = truck['is_active'] as bool;
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? HawaColors.teal.withOpacity(0.5) : HawaColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFFE6FFFA) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        truck['type'] == 'Water Sprinkler'
                            ? Icons.water_drop
                            : (truck['type'] == 'Anti-Smog Gun' ? Icons.air : Icons.cleaning_services),
                        color: isActive ? HawaColors.teal : HawaColors.muted,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(truck['name'] as String, style: HawaText.sans(14, weight: FontWeight.w700)),
                        Text(truck['ward'] as String, style: HawaText.sans(11.5, color: HawaColors.muted)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFE6FFFA) : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: isActive ? HawaColors.teal : HawaColors.alert),
                  ),
                  child: Text(
                    truck['status'] as String,
                    style: TextStyle(
                      color: isActive ? HawaColors.teal : HawaColors.alert,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: HawaColors.paper,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statCol('VEHICLE SPEED', truck['speed'] as String),
                  _dividerVertical(),
                  _statCol('PUMP FLOW', truck['pump_flow'] as String),
                  _dividerVertical(),
                  _statCol('WATER DISBURSED', truck['water_disbursed'] as String),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Managed by: ${truck["contractor"]}',
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildVerifiedImpactList() {
    return _verifiedImpacts.map((impact) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: HawaColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(impact['sector'] as String, style: HawaText.sans(14, weight: FontWeight.w700)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(impact['cell'] as String, style: HawaText.mono(10.5, color: const Color(0xFF0369A1))),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(impact['treated_at'] as String, style: HawaText.sans(11.5, color: HawaColors.muted)),
            const SizedBox(height: 10),

            // Reduction Metrics Box
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _metricBox('PM10 REDUCTION', impact['pm10_drop'] as String, const Color(0xFF16A34A)),
                  _metricBox('PM2.5 REDUCTION', impact['pm25_drop'] as String, const Color(0xFF16A34A)),
                  _metricBox('EFFECT DURATION', impact['duration'] as String, HawaColors.ink),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Scientific Verification Seal
            Row(
              children: [
                const Icon(Icons.science_outlined, size: 14, color: HawaColors.teal),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    impact['verified_by'] as String,
                    style: const TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: HawaColors.teal),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _statCol(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: HawaColors.ink)),
      ],
    );
  }

  Widget _metricBox(String label, String val, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF166534))),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  Widget _dividerVertical() {
    return Container(width: 1, height: 26, color: HawaColors.line);
  }
}
