import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hawacommand_app/app/theme.dart';
import 'package:hawacommand_app/core/air.dart';
import 'package:hawacommand_app/core/geo.dart';
import 'package:hawacommand_app/features/driver/driver_data.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Non-interactive route preview: PM2.5 hex layer, route line, stops, truck.
class RouteMap extends StatelessWidget {
  const RouteMap({
    required this.route,
    required this.hotspots,
    this.vehicle,
    super.key,
  });

  final DriverRoute route;
  final List<Hotspot> hotspots;
  final LatLng? vehicle;

  static const _hexRadiusKm = 0.32;

  /// Greyscale, lifted towards the paper colour so the hex layer reads first.
  static const _paperFilter = ColorFilter.matrix(<double>[
    0.20, 0.55, 0.07, 0, 70, //
    0.20, 0.55, 0.07, 0, 70, //
    0.20, 0.55, 0.07, 0, 66, //
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final points = route.points;
    final center = points.isEmpty ? Gazetteer.delhi : centroid(points);
    final current = route.currentIndex;
    final truckAt =
        vehicle ?? (route.stops.isNotEmpty ? route.stops[current].point : null) ?? center;

    final hexes = hexGrid(center, radiusKm: _hexRadiusKm, cols: 9, rows: 5).map(
      (c) {
        final pm = _pmAt(c);
        final band = PmBand.of(pm);
        return Polygon(
          points: hexagon(c, _hexRadiusKm * 0.96),
          color: band.color.withValues(alpha: 0.22),
          borderColor: band.color.withValues(alpha: 0.35),
          borderStrokeWidth: 0.6,
        );
      },
    ).toList();

    return FlutterMap(
      options: MapOptions(
        initialCameraFit: points.length >= 2
            ? CameraFit.coordinates(
                coordinates: points,
                padding: const EdgeInsets.fromLTRB(36, 30, 36, 30),
                maxZoom: 14.2,
              )
            : null,
        initialCenter: center,
        initialZoom: 12.4,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none,
        ),
        backgroundColor: HawaColors.paper,
      ),
      children: [
        TileLayer(
          // OpenStreetMap raster tiles (no API key). Light use only, with a
          // proper user agent, per the OSM tile usage policy.
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.hawacommand.hawacommand_app',
          tileBuilder: (context, tile, _) => ColorFiltered(colorFilter: _paperFilter, child: tile),
        ),
        PolygonLayer(polygons: hexes),
        if (points.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: points,
                strokeWidth: 3,
                color: HawaColors.ink.withValues(alpha: 0.75),
                pattern: StrokePattern.dashed(segments: const [8, 6]),
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            for (final (i, stop) in route.stops.indexed)
              if (stop.point != null)
                Marker(
                  point: stop.point!,
                  width: 22,
                  height: 22,
                  child: _StopPin(
                    number: stop.number,
                    active: i == current,
                    done: stop.status == StopStatus.done,
                  ),
                ),
            Marker(
              point: truckAt,
              alignment: const Alignment(0.9, -0.9),
              child: const _TruckPin(),
            ),
          ],
        ),
        const Align(
          alignment: Alignment.bottomRight,
          child: _Attribution(),
        ),
      ],
    );
  }

  /// A smooth PM2.5 field from nearby hotspots (Gaussian falloff).
  double _pmAt(LatLng p) {
    var value = 95.0;
    for (final h in hotspots) {
      final d = distanceKm(p, h.point);
      final w = math.exp(-(d * d) / (2 * 1.1 * 1.1));
      value = math.max(value, 95 + (h.pm25 - 95) * w);
    }
    return value;
  }
}

class _StopPin extends StatelessWidget {
  const _StopPin({
    required this.number,
    required this.active,
    required this.done,
  });

  final int number;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: active ? HawaColors.ink : (done ? HawaColors.teal : HawaColors.white),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: active || done ? HawaColors.white : HawaColors.ink,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: HawaText.mono(
          11,
          weight: FontWeight.w600,
          color: active || done ? HawaColors.white : HawaColors.ink,
        ),
      ),
    );
  }
}

class _TruckPin extends StatelessWidget {
  const _TruckPin();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HawaColors.teal,
        shape: BoxShape.circle,
        border: Border.all(color: HawaColors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x330B1215), blurRadius: 6),
        ],
      ),
      alignment: Alignment.center,
      child: const Icon(LucideIcons.truck, size: 15, color: HawaColors.white),
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Text(
        '© OpenStreetMap contributors',
        style: HawaText.sans(8.5, color: HawaColors.muted2),
      ),
    );
  }
}
