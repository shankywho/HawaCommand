import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/theme.dart';
import 'package:hawa_app/core/widgets/simulated_screen_chip.dart';

/// Commute mode definition
enum CommuteMode {
  cycling('Cycling', Icons.directions_bike, 30.0, 'Moderate aerobic (30 L/min)'),
  walking('Walking', Icons.directions_walk, 15.0, 'Light aerobic (15 L/min)'),
  twoWheeler('Two-Wheeler', Icons.two_wheeler, 18.0, 'Open exhaust (18 L/min)'),
  car('Car (AC)', Icons.directions_car, 6.0, 'Cabin filter (6 L/min)');

  const CommuteMode(this.label, this.icon, this.ventilationLpm, this.ventilationDesc);
  final String label;
  final IconData icon;
  final double ventilationLpm;
  final String ventilationDesc;
}

/// Delhi quick landmark presets
class LandmarkPreset {
  const LandmarkPreset(this.name, this.lat, this.lon);
  final String name;
  final double lat;
  final double lon;
}

const delhiPresets = [
  LandmarkPreset('Lajpat Nagar', 28.5672, 77.2435),
  LandmarkPreset('Connaught Place', 28.6315, 77.2167),
  LandmarkPreset('Anand Vihar', 28.6476, 77.3158),
  LandmarkPreset('Rohini Sec-14', 28.7125, 77.1235),
  LandmarkPreset('Dwarka Mor', 28.6185, 77.0325),
  LandmarkPreset('Hauz Khas', 28.5494, 77.2001),
];

/// Safe Air Navigator Screen (`/citizen/safe-route`)
class SafeRouteScreen extends ConsumerStatefulWidget {
  const SafeRouteScreen({super.key});

  @override
  ConsumerState<SafeRouteScreen> createState() => _SafeRouteScreenState();
}

class _SafeRouteScreenState extends ConsumerState<SafeRouteScreen> {
  LandmarkPreset _origin = delhiPresets[0]; // Lajpat Nagar
  LandmarkPreset _destination = delhiPresets[1]; // Connaught Place
  CommuteMode _selectedMode = CommuteMode.cycling;
  int _selectedRouteIndex = 1; // 0 = Fastest, 1 = Cleanest, 2 = Balanced

  @override
  Widget build(BuildContext context) {
    // Dynamic calculations based on selected mode and distance
    final double distBase = 11.2;
    final double ve = _selectedMode.ventilationLpm;

    // 1. Fastest
    final int fastTime = 28;
    final double fastPm = 345.0;
    final double fastDose = double.parse((fastPm * (ve * 0.001) * fastTime).toStringAsFixed(1));

    // 2. Cleanest
    final int cleanTime = 34;
    final double cleanPm = 162.0;
    final double cleanDose = double.parse((cleanPm * (ve * 0.001) * cleanTime).toStringAsFixed(1));
    final double cleanSavedPct = double.parse(((1.0 - (cleanDose / fastDose)) * 100).toStringAsFixed(1));

    // 3. Balanced
    final int balTime = 30;
    final double balPm = 210.0;
    final double balDose = double.parse((balPm * (ve * 0.001) * balTime).toStringAsFixed(1));
    final double balSavedPct = double.parse(((1.0 - (balDose / fastDose)) * 100).toStringAsFixed(1));

    return Scaffold(
      backgroundColor: HawaColors.paper,
      appBar: AppBar(
        title: const Text('Safe Air Navigator'),
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
          // Origin / Destination Card
          _buildLocationCard(),
          const SizedBox(height: 14),

          // Commute Mode Selector
          _buildModeSelector(),
          const SizedBox(height: 16),

          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI ROUTE COMPARISON',
                style: HawaText.sans(11, weight: FontWeight.w700, color: HawaColors.muted, letterSpacing: 0.8),
              ),
              Text(
                'Ventilation: ${ve.toInt()} L/min',
                style: HawaText.mono(11, color: HawaColors.teal),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 1. Cleanest Route (Recommended Badge)
          _buildRouteCard(
            index: 1,
            title: 'Cleanest Airway',
            tagline: 'Lodi Gardens & Tree Canopy Buffer',
            badge: 'RECOMMENDED (-$cleanSavedPct% PM)',
            badgeColor: HawaColors.teal,
            durationMin: cleanTime,
            distanceKm: 12.6,
            timeDelta: '+6 min',
            avgPm25: cleanPm,
            doseUg: cleanDose,
            doseSavedPct: cleanSavedPct,
            highlights: [
              'Shaded greenway corridors absorb PM',
              'Avoids Mathura Road diesel exhaust',
              'Misted sector near CGO Complex',
            ],
            isSelected: _selectedRouteIndex == 1,
          ),
          const SizedBox(height: 10),

          // 2. Balanced Route
          _buildRouteCard(
            index: 2,
            title: 'Optimal Balance',
            tagline: 'Inner ring with selective bypass',
            badge: 'BALANCED (-$balSavedPct% PM)',
            badgeColor: const Color(0xFF134074),
            durationMin: balTime,
            distanceKm: 11.8,
            timeDelta: '+2 min',
            avgPm25: balPm,
            doseUg: balDose,
            doseSavedPct: balSavedPct,
            highlights: [
              'Bypasses congested flyovers',
              '+2 min commute trade-off',
              'Consistent moderate air band',
            ],
            isSelected: _selectedRouteIndex == 2,
          ),
          const SizedBox(height: 10),

          // 3. Fastest Route (Warning)
          _buildRouteCard(
            index: 0,
            title: 'Fastest Route',
            tagline: 'Direct Ring Road / Mathura Rd',
            badge: 'HIGH EXPOSURE',
            badgeColor: HawaColors.alert,
            durationMin: fastTime,
            distanceKm: distBase,
            timeDelta: 'Fastest',
            avgPm25: fastPm,
            doseUg: fastDose,
            doseSavedPct: 0.0,
            highlights: [
              'Heavy truck diesel particulate',
              'Resuspended road dust corridor',
              'Peak lung inflammation risk',
            ],
            isSelected: _selectedRouteIndex == 0,
          ),
          const SizedBox(height: 18),

          // Inhaled Dose Comparison Summary Card
          _buildDoseSummary(cleanDose, fastDose, cleanSavedPct),
          const SizedBox(height: 20),

          // Start Navigation Action Button
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: HawaColors.teal,
                  content: Text(
                    'Starting Clean Air Navigation via ${_selectedRouteIndex == 1 ? "Canopy Airway" : (_selectedRouteIndex == 2 ? "Balanced Route" : "Direct Highway")}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.navigation_outlined),
            label: Text(
              'START CLEAN NAVIGATION (${_selectedRouteIndex == 1 ? cleanTime : (_selectedRouteIndex == 2 ? balTime : fastTime)} MIN)',
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: HawaColors.teal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: HawaColors.line),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // Origin Selector
          Row(
            children: [
              const Icon(Icons.my_location, color: HawaColors.teal, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<LandmarkPreset>(
                    value: _origin,
                    isDense: true,
                    isExpanded: true,
                    style: HawaText.sans(14, weight: FontWeight.w600),
                    items: delhiPresets.map((p) => DropdownMenuItem(value: p, child: Text('From: ${p.name}'))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _origin = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: HawaColors.line, height: 1),
          ),
          // Destination Selector
          Row(
            children: [
              const Icon(Icons.location_on, color: HawaColors.alert, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<LandmarkPreset>(
                    value: _destination,
                    isDense: true,
                    isExpanded: true,
                    style: HawaText.sans(14, weight: FontWeight.w600),
                    items: delhiPresets.map((p) => DropdownMenuItem(value: p, child: Text('To: ${p.name}'))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _destination = val);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: CommuteMode.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final mode = CommuteMode.values[i];
          final isSelected = mode == _selectedMode;
          return ChoiceChip(
            selected: isSelected,
            showCheckmark: false,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(mode.icon, size: 16, color: isSelected ? Colors.white : HawaColors.muted),
                const SizedBox(width: 6),
                Text(
                  mode.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : HawaColors.ink,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.white,
            selectedColor: HawaColors.teal,
            side: BorderSide(color: isSelected ? HawaColors.teal : HawaColors.line),
            onSelected: (_) => setState(() => _selectedMode = mode),
          );
        },
      ),
    );
  }

  Widget _buildRouteCard({
    required int index,
    required String title,
    required String tagline,
    required String badge,
    required Color badgeColor,
    required int durationMin,
    required double distanceKm,
    required String timeDelta,
    required double avgPm25,
    required double doseUg,
    required double doseSavedPct,
    required List<String> highlights,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => setState(() => _selectedRouteIndex = index),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? HawaColors.teal : HawaColors.line,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: HawaColors.teal.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Title + Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? HawaColors.teal : HawaColors.muted,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(title, style: HawaText.sans(15, weight: FontWeight.w700)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: badgeColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(color: badgeColor, fontSize: 10.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(tagline, style: HawaText.sans(12, color: HawaColors.muted)),
            const SizedBox(height: 12),

            // Metrics Row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: HawaColors.paper,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _metricItem('TRAVEL TIME', '$durationMin min', timeDelta, HawaColors.ink),
                  _dividerVertical(),
                  _metricItem('DISTANCE', '$distanceKm km', 'Total path', HawaColors.ink),
                  _dividerVertical(),
                  _metricItem('AVG PM2.5', '${avgPm25.toInt()}', 'µg/m³', avgPm25 > 250 ? HawaColors.alert : HawaColors.teal),
                  _dividerVertical(),
                  _metricItem('INHALED DOSE', '$doseUg', 'µg toxic mass', isSelected ? HawaColors.teal : HawaColors.ink),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Highlights
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: highlights.map((h) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('• $h', style: const TextStyle(fontSize: 11, color: Color(0xFF334155))),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricItem(String label, String value, String sub, Color valColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: valColor)),
        Text(sub, style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _dividerVertical() {
    return Container(width: 1, height: 26, color: HawaColors.line);
  }

  Widget _buildDoseSummary(double cleanDose, double fastDose, double savedPct) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE6FFFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: HawaColors.teal.withOpacity(0.4)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.health_and_safety, color: HawaColors.teal, size: 22),
              const SizedBox(width: 8),
              Text(
                'RESPIRATORY HEALTH IMPACT',
                style: HawaText.sans(12, weight: FontWeight.w800, color: HawaColors.teal, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'By taking the Cleanest Airway, your lungs absorb ${(fastDose - cleanDose).toStringAsFixed(1)} µg less particulate matter ($savedPct% dose reduction), preventing acute bronchial irritation.',
            style: HawaText.sans(12.5, color: const Color(0xFF0F766E), height: 1.4),
          ),
        ],
      ),
    );
  }
}
