import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawa_app/app/theme.dart';
import 'package:hawa_app/core/widgets/simulated_screen_chip.dart';

/// Ward Air Scorecard Screen (`/citizen/ward-score`)
class WardScorecardScreen extends ConsumerStatefulWidget {
  const WardScorecardScreen({super.key});

  @override
  ConsumerState<WardScorecardScreen> createState() => _WardScorecardScreenState();
}

class _WardScorecardScreenState extends ConsumerState<WardScorecardScreen> {
  final _wards = [
    {
      'rank': 1,
      'name': 'Hauz Khas (Ward 152)',
      'grade': 'A+',
      'pm25': '118 µg/m³',
      'compliance': '98.4%',
      'sla_pct': '96.0%',
      'badge': 'Green Leader',
      'grade_color': const Color(0xFF16A34A),
    },
    {
      'rank': 2,
      'name': 'Chanakyapuri (Ward 104)',
      'grade': 'A',
      'pm25': '132 µg/m³',
      'compliance': '95.0%',
      'sla_pct': '94.0%',
      'badge': 'High Cleanliness',
      'grade_color': const Color(0xFF16A34A),
    },
    {
      'rank': 3,
      'name': 'Rohini Sector 14 (Ward 52)',
      'grade': 'B+',
      'pm25': '185 µg/m³',
      'compliance': '89.2%',
      'sla_pct': '88.5%',
      'badge': 'Active Mitigation',
      'grade_color': const Color(0xFF0F766E),
    },
    {
      'rank': 4,
      'name': 'Lajpat Nagar (Ward 142)',
      'grade': 'B',
      'pm25': '210 µg/m³',
      'compliance': '84.0%',
      'sla_pct': '82.0%',
      'badge': 'Improving',
      'grade_color': const Color(0xFFD97706),
    },
    {
      'rank': 5,
      'name': 'Punjabi Bagh (Ward 88)',
      'grade': 'C+',
      'pm25': '245 µg/m³',
      'compliance': '78.5%',
      'sla_pct': '74.0%',
      'badge': 'Moderate Action',
      'grade_color': const Color(0xFFD97706),
    },
    {
      'rank': 6,
      'name': 'Okhla Phase-II (Ward 186)',
      'grade': 'D',
      'pm25': '315 µg/m³',
      'compliance': '52.0%',
      'sla_pct': '58.0%',
      'badge': 'Contractor Alert',
      'grade_color': HawaColors.alert,
    },
    {
      'rank': 7,
      'name': 'Anand Vihar (Ward 212)',
      'grade': 'F',
      'pm25': '395 µg/m³',
      'compliance': '41.0%',
      'sla_pct': '39.0%',
      'badge': 'Critical Hotspot',
      'grade_color': HawaColors.alert,
    },
  ];

  void _shareScorecard() {
    final text = '🌿 Delhi Clean Air Ward Scorecard:\n'
        'Rohini Sector 14 scored Grade B+ today on HawaCitizen!\n'
        '• Route Misting Compliance: 89.2%\n'
        '• Citizen Grievances Resolved: 88.5%\n'
        'Track and hold your MCD ward accountable with HawaCommand!';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: HawaColors.teal,
        content: Text('Ward Scorecard copied to clipboard! Ready to share on WhatsApp.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HawaColors.paper,
      appBar: AppBar(
        title: const Text('Ward Air Scorecard'),
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
          // Header Card
          Container(
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
                    Text('MCD CIVIC ACCOUNTABILITY', style: HawaText.sans(11, weight: FontWeight.w700, color: HawaColors.teal)),
                    const Text('Updated Daily 06:00', style: TextStyle(fontSize: 10.5, color: HawaColors.muted)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Public transparency scorecards ranking all 250 municipal wards of Delhi by dust suppression and grievance SLA adherence.',
                  style: HawaText.sans(12, color: HawaColors.muted),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _shareScorecard,
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('SHARE WARD SCORECARD ON WHATSAPP'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HawaColors.teal,
                    side: const BorderSide(color: HawaColors.teal),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text('DELHI WARD RANKINGS LEADERBOARD', style: HawaText.sans(11, weight: FontWeight.w700, color: HawaColors.muted)),
          const SizedBox(height: 8),

          ..._wards.map((w) {
            final gradeColor = w['grade_color'] as Color;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: HawaColors.line),
              ),
              child: Row(
                children: [
                  // Rank Circle
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: HawaColors.paper,
                      shape: BoxShape.circle,
                      border: Border.all(color: HawaColors.line),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '#${w["rank"]}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Ward Name and Stats
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(w['name'] as String, style: HawaText.sans(13.5, weight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          'Avg PM2.5: ${w["pm25"]} · Route Misting: ${w["compliance"]}',
                          style: HawaText.sans(11, color: HawaColors.muted),
                        ),
                        Text(
                          'Citizen SLA: ${w["sla_pct"]} · ${w["badge"]}',
                          style: TextStyle(fontSize: 10.5, color: gradeColor, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                  // Grade Badge
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: gradeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: gradeColor),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      w['grade'] as String,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: gradeColor),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
