import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawa_app/app/theme.dart';
import 'package:hawa_app/core/widgets/simulated_screen_chip.dart';

/// Govt in Action Radar Screen (`/citizen/live-ops`)
class LiveOperationsScreen extends ConsumerStatefulWidget {
  const LiveOperationsScreen({super.key});

  @override
  ConsumerState<LiveOperationsScreen> createState() => _LiveOperationsScreenState();
}

class _LiveOperationsScreenState extends ConsumerState<LiveOperationsScreen> {
  int _activeTab = 0; // 0 = Active Fleet, 1 = Verified Impact

  final _activeFleet = [
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

  final _verifiedImpacts = [
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HawaColors.paper,
      appBar: AppBar(
        title: const Text('Govt in Action Radar'),
        backgroundColor: HawaColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: const [
          Padding(
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
