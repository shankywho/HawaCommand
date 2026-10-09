import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/maps/hawa_tile_layer.dart';
import 'package:hawa_app/core/utils/geo.dart';
import 'package:hawa_app/core/utils/ist_time.dart';
import 'package:hawa_app/core/widgets/error_view.dart';
import 'package:hawa_app/features/air_map/application/air_map_controller.dart';
import 'package:hawa_app/features/air_map/application/route_planner.dart';
import 'package:hawa_app/features/air_map/domain/air_data.dart';
import 'package:hawa_app/features/air_map/domain/place.dart';
import 'package:hawa_app/features/air_map/presentation/place_search_screen.dart';
import 'package:hawa_app/features/air_map/presentation/widgets/air_map_layers.dart';
import 'package:hawa_app/features/air_map/presentation/widgets/air_sheets.dart';
import 'package:hawa_app/features/air_map/presentation/widgets/air_summary_panel.dart';
import 'package:hawa_app/features/air_map/presentation/widgets/pollution_overlay.dart';
import 'package:hawa_app/features/air_map/presentation/widgets/route_panel.dart';
import 'package:hawa_app/features/shell/domain/app_permission.dart';
import 'package:hawa_app/features/shell/presentation/permission_education_screen.dart';
import 'package:latlong2/latlong.dart';

/// Citizen air map (`/citizen/map`, also `/map` for every role): the AI-ML pollution field from
/// the backend twin, ranked red-zone hotspots, a forecast time slider, and clean-air routing that
/// scores road routes by the PM2.5 a traveller would breathe.
class AirMapScreen extends ConsumerStatefulWidget {
  const AirMapScreen({this.standalone = false, super.key});

  /// Pushed from the More sheet (shows a back button) rather than a shell tab.
  final bool standalone;

  @override
  ConsumerState<AirMapScreen> createState() => _AirMapScreenState();
}

class _AirMapScreenState extends ConsumerState<AirMapScreen> {
  static const _delhi = LatLng(28.6328, 77.1500);
  final _map = MapController();
  final _sheet = DraggableScrollableController();

  /// Non-null while the user places a route end by moving the map: true = start.
  bool? _pickingOrigin;
  bool _refreshing = false;

  @override
  void dispose() {
    _sheet.dispose();
    _map.dispose();
    super.dispose();
  }

  // ---- actions -------------------------------------------------------------------------------

  Future<void> _openSearch({required bool origin}) async {
    final pick = await context.push<PlacePick>(Routes.mapSearchFor(origin: origin));
    if (!mounted || pick == null) return;
    if (pick.pickOnMap) {
      setState(() => _pickingOrigin = origin);
      return;
    }
    await _setEnd(pick.place!, origin: origin);
  }

  Future<void> _setEnd(Place place, {required bool origin}) async {
    final planner = ref.read(routePlannerProvider.notifier);
    if (origin) {
      await planner.setOrigin(place);
    } else {
      await planner.setDestination(place);
      // A destination without a start: start from here if we may, else ask.
      if (ref.read(routePlannerProvider).origin == null && mounted) {
        final me = ref.read(myLocationProvider);
        if (me != null) {
          await planner.setOrigin(
            Place(name: context.l10n.airMapYourLocation, point: me, isMyLocation: true),
          );
        } else {
          await _openSearch(origin: true);
        }
      }
    }
  }

  Future<void> _directionsTo(GeoPoint point, String name) async {
    Navigator.of(context).pop();
    await _setEnd(Place(name: name, point: point), origin: false);
  }

  Future<void> _locateMe() async {
    final l = context.l10n;
    if (!await ensurePermission(context, ref, AppPermission.location)) return;
    final p = await ref.read(myLocationProvider.notifier).locate();
    if (!mounted) return;
    if (p == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.airMapLocationUnavailable)));
      return;
    }
    _map.move(ll(p), math.max(_map.camera.zoom, 14));
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await ref.read(airMapControllerProvider.notifier).refresh();
    if (mounted) setState(() => _refreshing = false);
  }

  void _showHotspot(Hotspot h, AirMapData data) {
    _map.move(ll(h.location), math.max(_map.camera.zoom, 13.5));
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => FractionallySizedBox(
          heightFactor: 0.75,
          child: HotspotSheet(
            hotspot: h,
            issuedAt: data.forecast?.issuedAt ?? data.fetchedAt,
            onDirections: () => _directionsTo(h.location, h.place),
          ),
        ),
      ),
    );
  }

  void _showCell(LatLng at, AirMapData data) {
    final layers = ref.read(airLayersProvider);
    final point = GeoPoint(lat: at.latitude, lon: at.longitude);
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => CellSheet(
          cell: data.grid.cellAt(point),
          factor: data.forecast?.factorAt(layers.hoursAhead.toDouble()) ?? 1,
          hoursAhead: layers.hoursAhead,
          asOf: data.grid.asOf,
          onDirections: () => _directionsTo(point, context.l10n.airMapDroppedPin),
        ),
      ),
    );
  }

  void _fitRoutes(RoutePlanState plan) {
    final routes = plan.routes.value;
    if (routes == null || routes.isEmpty) return;
    final pts = [
      for (final r in routes)
        for (final p in r.geometry) ll(p),
    ];
    final h = MediaQuery.sizeOf(context).height;
    _map.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(pts),
        padding: EdgeInsets.fromLTRB(40, 210, 40, h * 0.45),
      ),
    );
    if (_sheet.isAttached) {
      unawaited(
        _sheet.animateTo(0.42, duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
      );
    }
  }

  // ---- build ---------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.hawaColors;
    final air = ref.watch(airMapControllerProvider);
    final data = air.value;
    final layers = ref.watch(airLayersProvider);
    final plan = ref.watch(routePlannerProvider);
    final me = ref.watch(myLocationProvider);
    final factor = data?.forecast?.factorAt(layers.hoursAhead.toDouble()) ?? 1;
    final range = data?.grid.quantiles(0.1, 0.9) ?? (0.0, 1.0);

    ref.listen(routePlannerProvider.select((s) => s.routes.value), (prev, next) {
      if (next != null && next.isNotEmpty && !identical(prev, next)) {
        _fitRoutes(ref.read(routePlannerProvider));
      }
    });

    final picking = _pickingOrigin != null;
    final routes = plan.routes.value ?? const [];

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _delhi,
              initialZoom: 10.6,
              minZoom: 8,
              maxZoom: 18,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onTap: (_, at) {
                if (!picking && data != null) _showCell(at, data);
              },
              onLongPress: (_, at) {
                if (picking) return;
                unawaited(
                  _setEnd(
                    Place(
                      name: l.airMapDroppedPin,
                      point: GeoPoint(lat: at.latitude, lon: at.longitude),
                    ),
                    origin: false,
                  ),
                );
              },
            ),
            children: [
              const HawaTileLayer(desaturate: false),
              if (data != null && layers.heatmap)
                PollutionOverlayLayer(
                  grid: data.grid,
                  factor: factor,
                  relative: layers.relative,
                  low: range.$1,
                  high: range.$2,
                ),
              if (data != null && layers.hotspots)
                HotspotLayers(
                  hotspots: data.hotspots,
                  hoursAhead: layers.hoursAhead.toDouble(),
                  onTap: (h) => _showHotspot(h, data),
                ),
              if (routes.isNotEmpty)
                RouteLayers(
                  routes: routes,
                  selected: plan.selected,
                  relative: layers.relative,
                  low: range.$1,
                  high: range.$2,
                ),
              EndpointMarkers(
                origin: plan.origin?.point,
                destination: plan.destination?.point,
                me: me,
              ),
            ],
          ),

          // Top: search or the from/to card, layer and time chips, banners.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (plan.isActive)
                    _FromToCard(
                      plan: plan,
                      onBack: ref.read(routePlannerProvider.notifier).clear,
                      onFrom: () => _openSearch(origin: true),
                      onTo: () => _openSearch(origin: false),
                      onSwap: ref.read(routePlannerProvider.notifier).swap,
                    )
                  else
                    _SearchBar(
                      showBack: widget.standalone,
                      onTap: () => _openSearch(origin: false),
                    ),
                  const SizedBox(height: 8),
                  _LayerChips(layers: layers),
                  if (data != null && data.fromCache) ...[
                    const SizedBox(height: 6),
                    _Pill(
                      icon: Icons.cloud_off,
                      color: c.offline,
                      text: l.airMapCached(IstTime.time(data.fetchedAt, context.lang)),
                      onAction: _refresh,
                      actionLabel: l.commonRetry,
                    ),
                  ],
                  if (layers.hoursAhead > 0 && data != null) ...[
                    const SizedBox(height: 6),
                    _Pill(
                      icon: Icons.schedule,
                      color: c.info,
                      text: l.airMapForecastAt(
                        IstTime.time(
                          DateTime.now().add(Duration(hours: layers.hoursAhead)),
                          context.lang,
                        ),
                      ),
                    ),
                  ],
                  if (air.isLoading && data == null) ...[
                    const SizedBox(height: 6),
                    _Pill(icon: Icons.hourglass_top, color: c.info, text: l.airMapLoading),
                  ],
                  if (air.hasError && data == null) ...[
                    const SizedBox(height: 6),
                    _Pill(
                      icon: Icons.error_outline,
                      color: c.danger,
                      text: l.airMapLoadFailed,
                      onAction: _refresh,
                      actionLabel: l.commonRetry,
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (data != null && layers.heatmap && !picking)
                    layers.relative
                        ? MapLegend(
                            title: l.airMapScaleRelative,
                            colors: RelativeScale.colors,
                            low: l.airMapCleaner('${range.$1.round()}'),
                            high: l.airMapDirtier('${range.$2.round()} µg/m³'),
                            tooltip: l.airMapScaleSwitch,
                            onTap: ref.read(airLayersProvider.notifier).toggleScale,
                          )
                        : MapLegend(
                            title: l.airMapLegend,
                            colors: AqiGradient.legend(cvd: c.cvdPalette),
                            low: l.aqiGood,
                            high: l.aqiSevere,
                            tooltip: l.airMapScaleSwitch,
                            onTap: ref.read(airLayersProvider.notifier).toggleScale,
                          ),
                ],
              ),
            ),
          ),

          // Map picking: a fixed centre pin and a confirm bar.
          if (picking) ...[
            const IgnorePointer(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.location_on, size: 48, color: Color(0xFFD93025)),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Card(
                  margin: const EdgeInsets.all(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l.airMapPickHint, textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setState(() => _pickingOrigin = null),
                                child: Text(l.commonCancel),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  final center = _map.camera.center;
                                  final origin = _pickingOrigin!;
                                  setState(() => _pickingOrigin = null);
                                  unawaited(
                                    _setEnd(
                                      Place(
                                        name: l.airMapDroppedPin,
                                        subtitle:
                                            '${center.latitude.toStringAsFixed(4)}, ${center.longitude.toStringAsFixed(4)}',
                                        point: GeoPoint(
                                          lat: center.latitude,
                                          lon: center.longitude,
                                        ),
                                      ),
                                      origin: origin,
                                    ),
                                  );
                                },
                                child: Text(l.airMapPickConfirm),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],

          if (!picking) ...[
            // My location, above the sheet.
            AnimatedBuilder(
              animation: _sheet,
              builder: (context, _) {
                final h = MediaQuery.sizeOf(context).height;
                final size = _sheet.isAttached ? _sheet.size : 0.3;
                return Positioned(
                  right: 12,
                  bottom: h * size + 12,
                  child: FloatingActionButton.small(
                    heroTag: 'air_map_me',
                    tooltip: l.airMapMyLocation,
                    backgroundColor: c.surfaceElevated,
                    foregroundColor: const Color(0xFF1A73E8),
                    onPressed: _locateMe,
                    child: const Icon(Icons.my_location),
                  ),
                );
              },
            ),
            DraggableScrollableSheet(
              controller: _sheet,
              initialChildSize: 0.3,
              minChildSize: 0.12,
              maxChildSize: 0.9,
              snap: true,
              snapSizes: const [0.3, 0.55],
              builder: (context, scroll) => Material(
                color: c.surfaceElevated,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                elevation: 12,
                shadowColor: const Color(0x33000000),
                clipBehavior: Clip.antiAlias,
                child: plan.isActive

                    ? RoutePanel(scrollController: scroll)
                    : data != null
                    ? AirSummaryPanel(
                        data: data,
                        scrollController: scroll,
                        refreshing: _refreshing,
                        onRefresh: _refresh,
                        onHotspot: (h) => _showHotspot(h, data),
                      )
                    : ListView(
                        controller: scroll,
                        children: [
                          const SheetHandle(),
                          if (air.hasError)
                            ErrorView(error: air.error!, onRetry: _refresh)
                          else
                            const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                        ],
                      ),
              ),
            ),
          ],
          AnimatedBuilder(
            animation: _sheet,
            builder: (context, _) {
              final h = MediaQuery.sizeOf(context).height;
              final size = picking ? 0.0 : (_sheet.isAttached ? _sheet.size : 0.3);
              return Positioned(left: 0, bottom: h * size, child: const HawaMapAttribution());
            },
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap, required this.showBack});

  final VoidCallback onTap;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.hawaColors;
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(28),
      color: c.surfaceElevated,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              if (showBack)
                IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop())
              else
                const Padding(
                  padding: EdgeInsets.only(left: 16, right: 8),
                  child: Icon(Icons.search),
                ),
              Expanded(
                child: Text(
                  l.airMapSearchHint,
                  style: TextStyle(color: c.mutedForeground, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: c.brand,
                  child: Icon(Icons.air, size: 18, color: c.onBrand),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FromToCard extends StatelessWidget {
  const _FromToCard({
    required this.plan,
    required this.onBack,
    required this.onFrom,
    required this.onTo,
    required this.onSwap,
  });

  final RoutePlanState plan;
  final VoidCallback onBack;
  final VoidCallback onFrom;
  final VoidCallback onTo;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.hawaColors;
    Widget field(String? value, String hint, IconData icon, Color color, VoidCallback onTap) =>
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value ?? hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: value == null ? c.mutedForeground : c.foreground),
                  ),
                ),
              ],
            ),
          ),
        );
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(16),
      color: c.surfaceElevated,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Row(
          children: [
            IconButton(
              tooltip: l.airMapClearRoute,
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack,
            ),
            Expanded(
              child: Column(
                children: [
                  field(
                    plan.origin?.name,
                    l.airMapFromHint,
                    Icons.trip_origin,
                    const Color(0xFF1A73E8),
                    onFrom,
                  ),
                  const SizedBox(height: 6),
                  field(
                    plan.destination?.name,
                    l.airMapToHint,
                    Icons.location_on,
                    const Color(0xFFD93025),
                    onTo,
                  ),
                ],
              ),
            ),
            IconButton(tooltip: l.airMapSwap, icon: const Icon(Icons.swap_vert), onPressed: onSwap),
          ],
        ),
      ),
    );
  }
}

class _LayerChips extends ConsumerWidget {
  const _LayerChips({required this.layers});

  final AirLayersState layers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.hawaColors;
    final ctl = ref.read(airLayersProvider.notifier);
    Widget chip(Widget child) => Padding(padding: const EdgeInsets.only(right: 6), child: child);
    final shape = StadiumBorder(side: BorderSide(color: c.border));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(
            FilterChip(
              shape: shape,
              backgroundColor: c.surfaceElevated,
              avatar: const Icon(Icons.blur_on, size: 18),
              label: Text(l.airMapLayerPollution),
              selected: layers.heatmap,
              onSelected: (_) => ctl.toggleHeatmap(),
            ),
          ),
          chip(
            FilterChip(
              shape: shape,
              backgroundColor: c.surfaceElevated,
              avatar: const Icon(Icons.warning_amber, size: 18),
              label: Text(l.airMapLayerHotspots),
              selected: layers.hotspots,
              onSelected: (_) => ctl.toggleHotspots(),
            ),
          ),
          for (final h in AirLayers.hourSteps)
            chip(
              ChoiceChip(
                shape: shape,
                backgroundColor: c.surfaceElevated,
                label: Text(h == 0 ? l.airMapNow : l.airMapInHours('$h')),
                selected: layers.hoursAhead == h,
                onSelected: (_) => ctl.setHours(h),
              ),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.color,
    required this.text,
    this.onAction,
    this.actionLabel,
  });

  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback? onAction;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) => Material(
    color: color,
    borderRadius: BorderRadius.circular(12),
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Flexible(
            child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
          if (onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: Text(actionLabel ?? ''),
            )
          else
            const SizedBox(width: 6),
        ],
      ),
    ),
  );
}
