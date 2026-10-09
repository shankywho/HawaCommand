import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawa_app/app/theme.dart';
import 'package:hawa_app/core/widgets/simulated_screen_chip.dart';

/// "No-Ghost-Worker" / Flag Missed Machine Screen (`/citizen/report/missed-machine`)
class MissedMachineScreen extends ConsumerStatefulWidget {
  const MissedMachineScreen({super.key});

  @override
  ConsumerState<MissedMachineScreen> createState() => _MissedMachineScreenState();
}

class _MissedMachineScreenState extends ConsumerState<MissedMachineScreen> {
  final _scheduledRoutes = [
    {
      'asset_id': 'SWP-07',
      'type': 'Mechanical Sweeper',
      'ward': 'Okhla Phase-II Industrial Outskirts',
      'cell': 'G-038-044',
      'scheduled_time': '08:00 AM - 09:30 AM',
      'is_breach': true, // Simulated ghost worker
    },
    {
      'asset_id': 'SPR-04',
      'type': 'Water Sprinkler',
      'ward': 'Anand Vihar / Preet Vihar Cluster',
      'cell': 'G-052-054',
      'scheduled_time': '07:45 AM - 09:15 AM',
      'is_breach': false, // Actually active
    },
    {
      'asset_id': 'SMG-12',
      'type': 'Anti-Smog Gun',
      'ward': 'Punjabi Bagh Ring Road Corridor',
      'cell': 'G-048-032',
      'scheduled_time': '08:30 AM - 10:00 AM',
      'is_breach': false, // Actually active
    },
  ];

  late Map<String, dynamic> _selectedMachine;
  bool _isAuditing = false;
  Map<String, dynamic>? _auditResult;

  @override
  void initState() {
    super.initState();
    _selectedMachine = _scheduledRoutes[0]; // SWP-07 default
  }

  Future<void> _runIoTAudit() async {
    setState(() {
      _isAuditing = true;
      _auditResult = null;
    });

    // Simulate real-time hardware telemetry fetch from HawaTag IoT stream
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final isBreach = _selectedMachine['is_breach'] as bool;
    final assetId = _selectedMachine['asset_id'] as String;

    setState(() {
      _isAuditing = false;
      if (isBreach) {
        _auditResult = {
          'sla_breach': true,
          'verdict': 'SLA BREACH CONFIRMED (GHOST WORKER)',
          'fine_inr': '₹25,000',
          'details': 'HawaTag IoT telemetry proves $assetId remained stationary at the depot during its scheduled window. Water pump flow sensor registered 0.0 L/min.',
          'action': 'Automated non-compliance penalty ticket logged to MCD Command Dashboard and contractor invoice docked.',
        };
      } else {
        _auditResult = {
          'sla_breach': false,
          'verdict': 'INTERVENTION ACTIVE & ON SITE',
          'fine_inr': '₹0 (Compliant)',
          'details': 'HawaTag IoT telemetry confirms $assetId entered the geofenced sector on time. Water pump is operating at 48.2 L/min.',
          'action': 'Machine is compliant. Route telemetry displayed on Live Govt Radar.',
        };
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HawaColors.paper,
      appBar: AppBar(
        title: const Text('Contractor Accountability Audit'),
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
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.gavel, color: HawaColors.alert, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NO-GHOST-WORKER WATCHDOG', style: HawaText.sans(11, weight: FontWeight.w700, color: HawaColors.alert)),
                      const SizedBox(height: 2),
                      Text(
                        'Report missed or idle municipal misting machinery. Our AI immediately cross-checks hardware telemetry.',
                        style: HawaText.sans(12, color: const Color(0xFF7F1D1D)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Select Scheduled Route
          Text('SELECT ASSIGNED MUNICIPAL MACHINE IN YOUR WARD:', style: HawaText.sans(11, weight: FontWeight.w700, color: HawaColors.muted)),
          const SizedBox(height: 8),

          ..._scheduledRoutes.map((m) {
            final isSelected = m['asset_id'] == _selectedMachine['asset_id'];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? HawaColors.teal : HawaColors.line,
                  width: isSelected ? 2.0 : 1.0,
                ),
              ),
              child: ListTile(
                onTap: () => setState(() {
                  _selectedMachine = m;
                  _auditResult = null;
                }),
                leading: Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? HawaColors.teal : HawaColors.muted,
                ),
                title: Text('${m["asset_id"]} · ${m["type"]}', style: HawaText.sans(14, weight: FontWeight.w700)),
                subtitle: Text('${m["ward"]}\nScheduled: ${m["scheduled_time"]}', style: HawaText.sans(11.5, color: HawaColors.muted)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                  child: Text(m['cell'] as String, style: HawaText.mono(10.5, color: HawaColors.muted2)),
                ),
                isThreeLine: true,
              ),
            );
          }),
          const SizedBox(height: 14),

          // Action Button: Audit
          FilledButton.icon(
            onPressed: _isAuditing ? null : _runIoTAudit,
            icon: _isAuditing
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.fingerprint),
            label: Text(
              _isAuditing ? 'QUERYING HAWATAG IoT TELEMETRY...' : 'AUDIT TELEMETRY & FLAG MISSED MACHINE',
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: HawaColors.alert,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 18),

          // Audit Result Card
          if (_auditResult != null) _buildAuditResultCard(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildAuditResultCard() {
    final isBreach = _auditResult!['sla_breach'] as bool;
    final color = isBreach ? HawaColors.alert : HawaColors.teal;
    final bgColor = isBreach ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isBreach ? Icons.warning_amber_rounded : Icons.check_circle_outline, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _auditResult!['verdict'] as String,
                  style: HawaText.sans(13, weight: FontWeight.w800, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(_auditResult!['details'] as String, style: HawaText.sans(12.5, color: HawaColors.ink, height: 1.4)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('PENALTY LOGGED:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: HawaColors.muted)),
                Text(
                  _auditResult!['fine_inr'] as String,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(_auditResult!['action'] as String, style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: color)),
        ],
      ),
    );
  }
}
