import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/aqi_palette.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/core/utils/geo.dart';
import 'package:hawa_app/features/air_map/domain/air_data.dart';
import 'package:hawa_app/features/air_map/domain/route_option.dart';
import 'package:hawa_app/features/air_map/presentation/widgets/pollution_overlay.dart';
import 'package:latlong2/latlong.dart';

LatLng ll(GeoPoint p) => LatLng(p.lat, p.lon);

/// Red zones: a translucent disc per ranked hotspot (700 m) plus tappable numbered pins. Pins
/// closer than ~40 px at the current zoom merge into one ("#1 +6"); tapping a group zooms in.
class HotspotLayers extends StatelessWidget {
  const HotspotLayers({
    required this.hotspots,
    required this.onTap,
    this.hoursAhead = 0,
    super.key,
  });

  final List<Hotspot> hotspots;
  final ValueChanged<Hotspot> onTap;
  final double hoursAhead;

  static List<List<Hotspot>> cluster(List<Hotspot> hotspots, double radiusM) {
    final groups = <List<Hotspot>>[];
    for (final h in [...hotspots]..sort((a, b) => a.rank.compareTo(b.rank))) {
      final g = groups
          .where((g) => Geo.distanceM(g.first.location, h.location) <= radiusM)
          .firstOrNull;
      if (g == null) {
        groups.add([h]);
      } else {
        g.add(h);
      }
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.hawaColors;
    final severe = AqiPalette.of(AqiCategory.severe, cvd: c.cvdPalette);
    final camera = MapCamera.of(context);
    final metresPerPx =
        156543.03 * math.cos(camera.center.latitude * math.pi / 180) / math.pow(2, camera.zoom);
    final groups = cluster(hotspots, 40 * metresPerPx);
    return Stack(
      children: [
        CircleLayer(
          circles: [
            for (final h in hotspots)
              CircleMarker(
                point: ll(h.location),
                radius: AirMapData.hotspotRadiusM,
                useRadiusInMeter: true,
                color: severe.fill.withValues(alpha: 0.22),
                borderColor: severe.fill.withValues(alpha: 0.8),
                borderStrokeWidth: 1.5,
              ),
          ],
        ),
        MarkerLayer(
          markers: [
            for (final g in groups)
              Marker(
                point: ll(g.first.location),
                width: g.length > 1 ? 58 : 34,
                height: 34,
                child: Semantics(
                  button: true,
                  label: g.length > 1 ? l.airMapHotspotCluster('${g.length}') : g.first.place,
                  child: GestureDetector(
                    onTap: () {
                      if (g.length == 1) {
                        onTap(g.first);
                        return;
                      }
                      MapController.of(context).fitCamera(
                        CameraFit.coordinates(
                          coordinates: [for (final h in g) ll(h.location)],
                          padding: const EdgeInsets.fromLTRB(60, 240, 60, 320),
                          maxZoom: 16,
                        ),
                      );
                    },
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: severe.fill,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [BoxShadow(blurRadius: 4, color: Color(0x55000000))],
                      ),
                      child: Center(
                        child: Text(
                          g.length > 1 ? '${g.first.rank} +${g.length - 1}' : '${g.first.rank}',
                          style: TextStyle(
                            color: severe.onFill,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Candidate routes: the others in grey under the selected one, which is drawn with a white
/// casing and coloured by the AQI band it passes through (like traffic colours).
class RouteLayers extends StatelessWidget {
  const RouteLayers({
    required this.routes,
    required this.selected,
    this.relative = false,
    this.low = 0,
    this.high = 1,
    super.key,
  });

  final List<RouteOption> routes;
  final int selected;

  /// Colour runs on the map's relative scale ([low]–[high] PM2.5) instead of AQI bands.
  final bool relative;
  final double low;
  final double high;

  @override
  Widget build(BuildContext context) {
    final c = context.hawaColors;
    final sel = routes.isEmpty ? null : routes[selected.clamp(0, routes.length - 1)];
    return PolylineLayer(
      polylines: [
        for (final r in routes)
          if (!identical(r, sel))
            Polyline(
              points: [for (final p in r.geometry) ll(p)],
              strokeWidth: 6,
              color: const Color(0xFF9AA5B1),
              borderColor: Colors.white,
              borderStrokeWidth: 1.5,
            ),
        if (sel != null) ...[
          Polyline(
            points: [for (final p in sel.geometry) ll(p)],
            strokeWidth: 11,
            color: const Color(0xFF1A73E8),
          ),
          for (final run in sel.exposure.runs)
            Polyline(
              points: [for (final p in run.points) ll(p)],
              strokeWidth: 6,
              color: relative
                  ? RelativeScale.at(high <= low ? 0.5 : (run.avgPm25 - low) / (high - low))
                  : AqiPalette.of(run.category, cvd: c.cvdPalette).fill,
            ),
        ],
      ],
    );
  }
}

/// Start (blue ring), destination (red pin) and the user's position (blue dot).
class EndpointMarkers extends StatelessWidget {
  const EndpointMarkers({this.origin, this.destination, this.me, super.key});

  final GeoPoint? origin;
  final GeoPoint? destination;
  final GeoPoint? me;

  @override
  Widget build(BuildContext context) => MarkerLayer(
    markers: [
      if (me != null)
        Marker(
          point: ll(me!),
          width: 26,
          height: 26,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0x331A73E8),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x551A73E8)),
            ),
            child: Center(
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A73E8),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ),
        ),
      if (origin != null)
        Marker(
          point: ll(origin!),
          width: 22,
          height: 22,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1A73E8), width: 5),
            ),
          ),
        ),
      if (destination != null)
        Marker(
          point: ll(destination!),
          width: 40,
          height: 40,
          alignment: Alignment.topCenter,
          child: const Icon(Icons.location_on, color: Color(0xFFD93025), size: 40),
        ),
    ],
  );
}
