import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawa_app/app/env.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/maps/tile_cache.dart';

/// Raster basemap through the file cache (ARCHITECTURE §12): MapTiler when a key is set, else the
/// keyless Esri street basemap. Never the OSM Foundation tile servers. If tiles cannot load (offline,
/// nothing cached) the map keeps a plain background, the polylines and the markers.
class HawaTileLayer extends ConsumerWidget {
  const HawaTileLayer({this.desaturate = true, super.key});

  /// DESIGN_SYSTEM §8: a desaturated basemap so AQI and status colours stand out. The citizen air
  /// map keeps the street colours (users read it like Google Maps).
  final bool desaturate;

  static bool get enabled =>
      Env.basemapUrl.isNotEmpty &&
      !Env.basemapUrl.contains(
        'tile.openstreet'
        'map.org',
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enabled) return const SizedBox.shrink();
    final cache = ref.watch(tileCacheProvider).value;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final layer = TileLayer(
      urlTemplate: Env.basemapUrl,
      userAgentPackageName: 'in.hawacommand.field',
      tileProvider: cache?.provider() ?? NetworkTileProvider(),
      retinaMode: Env.basemapUrl.contains('{r}') && RetinaMode.isHighDensity(context),
    );
    if (!desaturate && !dark) return layer;
    return ColorFiltered(
      colorFilter: dark
          // Dark mode: invert lightness, keep hue roughly (a cheap night basemap).
          ? const ColorFilter.matrix([
              -0.6, -0.3, -0.1, 0, 230, //
              -0.3, -0.6, -0.1, 0, 230, //
              -0.3, -0.3, -0.4, 0, 230, //
              0, 0, 0, 1, 0, //
            ])
          : const ColorFilter.matrix([
              0.5, 0.4, 0.1, 0, 20, //
              0.3, 0.6, 0.1, 0, 20, //
              0.3, 0.4, 0.3, 0, 20, //
              0, 0, 0, 1, 0, //
            ]),
      child: layer,
    );
  }
}

/// Attribution is always visible ("© MapTiler © OpenStreetMap contributors" or the Esri line).
class HawaMapAttribution extends StatelessWidget {
  const HawaMapAttribution({this.alignment = Alignment.bottomLeft, super.key});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final c = context.hawaColors;
    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: c.surfaceElevated.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(Env.basemapAttribution, style: TextStyle(fontSize: 11, color: c.foreground)),
      ),
    );
  }
}
