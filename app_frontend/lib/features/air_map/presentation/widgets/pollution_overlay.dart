import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hawa_app/app/theme/aqi_palette.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/utils/aqi.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/features/air_map/domain/pollution_grid.dart';
import 'package:latlong2/latlong.dart';

/// Continuous AQI colour: CPCB category fills, blended between category midpoints so the 500 m
/// grid reads as a smooth field. Category words live in the legend and the tap sheet.
abstract final class AqiGradient {
  static const _stops = <(int, AqiCategory)>[
    (25, AqiCategory.good),
    (75, AqiCategory.satisfactory),
    (150, AqiCategory.moderate),
    (250, AqiCategory.poor),
    (350, AqiCategory.veryPoor),
    (450, AqiCategory.severe),
  ];

  static Color forAqi(num aqi, {bool cvd = false}) {
    final a = aqi.toDouble();
    if (a <= _stops.first.$1) return AqiPalette.of(_stops.first.$2, cvd: cvd).fill;
    for (var i = 0; i < _stops.length - 1; i++) {
      final (lo, cLo) = _stops[i];
      final (hi, cHi) = _stops[i + 1];
      if (a <= hi) {
        final t = (a - lo) / (hi - lo);
        return Color.lerp(AqiPalette.of(cLo, cvd: cvd).fill, AqiPalette.of(cHi, cvd: cvd).fill, t)!;
      }
    }
    return AqiPalette.of(_stops.last.$2, cvd: cvd).fill;
  }

  static Color forPm25(double pm25, {bool cvd = false}) => forAqi(Aqi.fromPm25(pm25), cvd: cvd);

  static List<Color> legend({bool cvd = false}) => [
    for (final s in _stops) AqiPalette.of(s.$2, cvd: cvd).fill,
  ];
}

/// "Compare across the city" scale (ColorBrewer YlOrRd): pale yellow = the cleaner end of the city
/// right now, deep red = the dirtiest. No green, so a relatively clean street is never shown as
/// "good" air; the legend states the real µg/m³ range.
abstract final class RelativeScale {
  static const colors = [
    Color(0xFFFFF3A6),
    Color(0xFFFECC5C),
    Color(0xFFFD8D3C),
    Color(0xFFF03B20),
    Color(0xFFBD0026),
  ];

  static Color at(double t) {
    final x = t.clamp(0.0, 1.0) * (colors.length - 1);
    final i = x.floor().clamp(0, colors.length - 2);
    return Color.lerp(colors[i], colors[i + 1], x - i)!;
  }
}

/// Renders the twin grid as one image (4× upsampled, bilinear) laid over the map. Rebuilt when
/// the grid, the forecast factor or the palette changes; never per frame.
class PollutionOverlayLayer extends StatefulWidget {
  const PollutionOverlayLayer({
    required this.grid,
    this.factor = 1,
    this.opacity = 0.45,
    this.relative = false,
    this.low = 0,
    this.high = 1,
    super.key,
  });

  final PollutionGrid grid;

  /// Forecast scaling for the selected hour (1 = now). AQI scale only.
  final double factor;
  final double opacity;

  /// Relative scale between [low] and [high] PM2.5 (city quantiles) instead of AQI bands.
  final bool relative;
  final double low;
  final double high;

  @override
  State<PollutionOverlayLayer> createState() => _PollutionOverlayLayerState();
}

class _PollutionOverlayLayerState extends State<PollutionOverlayLayer> {
  static const _upsample = 4;
  ImageProvider? _image;
  Object? _key;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rebuildIfNeeded();
  }

  @override
  void didUpdateWidget(PollutionOverlayLayer old) {
    super.didUpdateWidget(old);
    _rebuildIfNeeded();
  }

  void _rebuildIfNeeded() {
    final cvd = context.hawaColors.cvdPalette;
    final key = (
      identityHashCode(widget.grid),
      widget.factor,
      cvd,
      widget.relative,
      widget.low,
      widget.high,
    );
    if (key == _key) return;
    _key = key;
    unawaited(_render(cvd, key));
  }

  Future<void> _render(bool cvd, Object key) async {
    final g = widget.grid;
    final w = g.cols * _upsample;
    final h = g.rows * _upsample;
    final pixels = Uint8List(w * h * 4);
    // Colour lookup by rounded PM2.5 (0–600) keeps the loop cheap.
    final span = widget.high - widget.low;
    final lut = List<Color>.generate(
      601,
      (v) => widget.relative
          ? RelativeScale.at(span <= 0 ? 0.5 : (v - widget.low) / span)
          : AqiGradient.forPm25(v.toDouble(), cvd: cvd),
    );
    final factor = widget.relative ? 1.0 : widget.factor;
    for (var y = 0; y < h; y++) {
      // Image row 0 is the northern edge; grid row 0 is the southern one.
      final fr = ((h - 1 - y) + 0.5) / _upsample - 0.5;
      for (var x = 0; x < w; x++) {
        final fc = (x + 0.5) / _upsample - 0.5;
        final v = _sample(g, fr, fc);
        final o = (y * w + x) * 4;
        if (v == null) continue; // transparent
        final c = lut[(v * factor).round().clamp(0, 600)];
        pixels[o] = (c.r * 255).round();
        pixels[o + 1] = (c.g * 255).round();
        pixels[o + 2] = (c.b * 255).round();
        pixels[o + 3] = 210;
      }
    }
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(pixels, w, h, ui.PixelFormat.rgba8888, completer.complete);
    final image = await completer.future;
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (!mounted || png == null || key != _key) return;
    setState(() => _image = MemoryImage(png.buffer.asUint8List()));
  }

  static double? _sample(PollutionGrid g, double fr, double fc) {
    if (fr < -0.5 || fc < -0.5 || fr > g.rows - 0.5 || fc > g.cols - 0.5) return null;
    final r = fr.clamp(0.0, g.rows - 1.0);
    final c = fc.clamp(0.0, g.cols - 1.0);
    final r0 = r.floor();
    final c0 = c.floor();
    final r1 = r0 + 1 < g.rows ? r0 + 1 : r0;
    final c1 = c0 + 1 < g.cols ? c0 + 1 : c0;
    final tr = r - r0;
    final tc = c - c0;
    var sum = 0.0;
    var wsum = 0.0;
    void add(int rr, int cc, double wt) {
      final v = g.valueAt(rr, cc);
      if (!v.isNaN && wt > 0) {
        sum += v * wt;
        wsum += wt;
      }
    }

    add(r0, c0, (1 - tr) * (1 - tc));
    add(r0, c1, (1 - tr) * tc);
    add(r1, c0, tr * (1 - tc));
    add(r1, c1, tr * tc);
    return wsum < 0.25 ? null : sum / wsum;
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) return const SizedBox.shrink();
    final b = widget.grid.bounds;
    return OverlayImageLayer(
      overlayImages: [
        OverlayImage(
          bounds: LatLngBounds(LatLng(b.minLat, b.minLon), LatLng(b.maxLat, b.maxLon)),
          imageProvider: image,
          opacity: widget.opacity,
          gaplessPlayback: true,
        ),
      ],
    );
  }
}

/// Gradient legend strip; tap to switch between the relative and the AQI scale.
class MapLegend extends StatelessWidget {
  const MapLegend({
    required this.title,
    required this.colors,
    required this.low,
    required this.high,
    this.onTap,
    this.tooltip,
    super.key,
  });

  final String title;
  final List<Color> colors;
  final String low;
  final String high;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = context.hawaColors;
    final style = TextStyle(fontSize: 11, color: c.foreground);
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: c.surfaceElevated.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: style.copyWith(fontWeight: FontWeight.w600)),
                    if (onTap != null) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.swap_horiz, size: 14, color: c.mutedForeground),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  width: 170,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(colors: colors),
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  width: 170,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(low, style: style),
                      Text(high, style: style),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
