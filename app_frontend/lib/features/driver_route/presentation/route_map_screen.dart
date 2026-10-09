import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/enum_labels.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/location/shift_location_tracker.dart';
import 'package:hawa_app/core/maps/hawa_tile_layer.dart';
import 'package:hawa_app/core/maps/map_markers.dart';
import 'package:hawa_app/core/widgets/empty_state.dart';
import 'package:hawa_app/core/widgets/loading_skeleton.dart';
import 'package:hawa_app/features/driver_route/application/shift_controller.dart';
import 'package:hawa_app/features/driver_route/application/today_route_controller.dart';
import 'package:hawa_app/features/driver_route/domain/stop.dart';
import 'package:hawa_app/features/driver_route/domain/today_route.dart';
import 'package:hawa_app/features/driver_route/presentation/widgets/driver_text.dart';
import 'package:hawa_app/features/driver_route/presentation/widgets/next_stop_hero.dart';
import 'package:hawa_app/features/shell/presentation/widgets/shell_app_bar.dart';
import 'package:latlong2/latlong.dart';

/// D2 Route map (`/driver/map`): overview, not turn-by-turn. Numbered markers with a status icon,
/// the route polyline, the driver's position during a shift only, Recenter, and a NEXT bar.
class RouteMapScreen extends ConsumerStatefulWidget {
  const RouteMapScreen({super.key});

  @override
  ConsumerState<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends ConsumerState<RouteMapScreen> {
  final _map = MapController();
  String? _selected;

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  List<LatLng> _line(TodayRoute r) => r.geometry.length >= 2
      ? [for (final p in r.geometry) LatLng(p.lat, p.lon)]
      : [for (final s in r.activeStops) LatLng(s.location.lat, s.location.lon)];

  void _recenter(TodayRoute r) {
    final pts = [..._line(r), for (final s in r.stops) LatLng(s.location.lat, s.location.lon)];
    if (pts.isEmpty) return;
    _map.fitCamera(
      CameraFit.coordinates(coordinates: pts, padding: const EdgeInsets.fromLTRB(40, 40, 40, 140)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.hawaColors;
    final route = ref.watch(todayRouteControllerProvider).value;
    final shiftOn = ref.watch(shiftControllerProvider).active;
    final me = shiftOn ? ref.watch(shiftPositionProvider).value : null;

    if (route == null) {
      return Scaffold(
        appBar: ShellAppBar(title: l.driverMapTitle),
        body: ref.watch(todayRouteControllerProvider).isLoading
            ? const LoadingSkeleton()
            : EmptyState(icon: Icons.map_outlined, message: l.driverNoRouteYet),
      );
    }
    final focus = (_selected == null ? null : route.stop(_selected!)) ?? route.nextStop;
    final pts = _line(route);
    final initial = pts.isEmpty ? const LatLng(28.6440, 77.1900) : pts.first;

    return Scaffold(
      appBar: ShellAppBar(title: l.driverMapTitle),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: initial,
              initialZoom: 13.5,
              initialCameraFit: pts.length >= 2
                  ? CameraFit.coordinates(
                      coordinates: pts,
                      padding: const EdgeInsets.fromLTRB(40, 40, 40, 140),
                    )
                  : null,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onTap: (_, _) => setState(() => _selected = null),
            ),
            children: [
              const HawaTileLayer(),
              if (pts.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(points: pts, strokeWidth: 9, color: Colors.white),
                    Polyline(points: pts, strokeWidth: 5, color: c.ink),
                  ],
                ),
              MarkerLayer(
                markers: [
                  for (final s in route.stops)
                    Marker(
                      point: LatLng(s.location.lat, s.location.lon),
                      width: 48,
                      height: 48,
                      child: GestureDetector(
                        onTap: () => setState(() => _selected = s.taskId),
                        child: StopMarker(
                          number: route.positionOf(s.taskId) == 0
                              ? s.sequence
                              : route.positionOf(s.taskId),
                          statusIcon: s.shownStatus.icon,
                          highlighted: identical(s, focus),
                          simulated: s.isSimulated,
                          semanticLabel:
                              '${s.placeName.of(context.lang)}, ${s.shownStatus.label(l)}',
                        ),
                      ),
                    ),
                  if (me != null)
                    Marker(
                      point: LatLng(me.point.lat, me.point.lon),
                      width: 22,
                      height: 22,
                      child: const PositionMarker(),
                    ),
                ],
              ),
            ],
          ),
          const HawaMapAttribution(alignment: Alignment.topLeft),
          Positioned(
            right: 12,
            top: 12,
            child: FloatingActionButton.small(
              heroTag: 'driver_map_recenter',
              tooltip: l.commonRecenter,
              onPressed: () => _recenter(route),
              child: const Icon(Icons.center_focus_strong),
            ),
          ),
          if (focus != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: _NextBar(route: route, stop: focus),
            ),
        ],
      ),
    );
  }
}

class _NextBar extends ConsumerWidget {
  const _NextBar({required this.route, required this.stop});

  final TodayRoute route;
  final Stop stop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Card(
        margin: const EdgeInsets.all(12),
        child: InkWell(
          onTap: () => context.push(Routes.stop(stop.taskId)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.driverMapNext(
                          '${route.positionOf(stop.taskId)}',
                          stop.placeName.of(context.lang),
                        ),
                        style: text.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(DriverText.window(stop, l, context.lang), style: text.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => NextStopHero.navigate(ref, stop),
                  icon: const Icon(Icons.navigation),
                  label: Text(l.driverGo),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
