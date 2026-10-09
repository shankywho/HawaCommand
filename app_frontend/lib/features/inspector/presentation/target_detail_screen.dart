import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/enum_labels.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/maps/hawa_tile_layer.dart';
import 'package:hawa_app/core/maps/map_markers.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/core/utils/ist_time.dart';
import 'package:hawa_app/core/utils/numbers.dart';
import 'package:hawa_app/core/widgets/big_action_button.dart';
import 'package:hawa_app/core/widgets/confidence_chip.dart';
import 'package:hawa_app/core/widgets/loading_skeleton.dart';
import 'package:hawa_app/core/widgets/simulated_badge.dart';
import 'package:hawa_app/features/inspector/application/inspector_controllers.dart';
import 'package:hawa_app/features/inspector/domain/inspection_target.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';

/// I3 Target detail (`/inspector/targets/:targetId`): the evidence bundle (suspect pin + wind path,
/// sensor spike, citizen photo). "Likely cause, not proof." Never shows the reporter's identity.
class TargetDetailScreen extends ConsumerWidget {
  const TargetDetailScreen({required this.targetId, super.key});

  final String targetId;

  Future<void> _navigate(WidgetRef ref, InspectionTarget t) async {
    await ref.read(inspectorActionsProvider.notifier).enRoute(t);
    final lat = t.location.lat.toStringAsFixed(6);
    final lon = t.location.lon.toStringAsFixed(6);
    try {
      if (await launchUrl(Uri.parse('google.navigation:q=$lat,$lon&mode=d'))) return;
    } on Object {
      // fall back to the web URL
    }
    unawaited(
      launchUrl(
        Uri.https('www.google.com', '/maps/dir/', {'api': '1', 'destination': '$lat,$lon'}),
        mode: LaunchMode.externalApplication,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.hawaColors;
    final text = Theme.of(context).textTheme;
    final ev = ref.watch(targetEvidenceProvider(targetId)).value;
    if (ev == null) return Scaffold(appBar: AppBar(), body: const LoadingSkeleton());
    final t = ev.target;
    final pin = LatLng(t.location.lat, t.location.lon);
    final traj = [for (final p in ev.backTrajectory) LatLng(p.lat, p.lon)];
    final onSite = t.onSiteLocal || t.status == InspectionStatus.onSite;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.inspectorLikely(t.cause.label(l).toLowerCase())),
        actions: [
          if (t.isSimulated)
            const Padding(padding: EdgeInsets.only(right: 12), child: SimulatedBadge()),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(t.placeName.of(context.lang), style: text.titleMedium),
          const SizedBox(height: 8),
          ConfidenceChip(value: t.causeConf),
          const SizedBox(height: 6),
          Text(l.inspectorNotProof, style: text.bodyMedium?.copyWith(color: c.warningText)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 200,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: pin,
                  initialZoom: 15.5,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                  ),
                ),
                children: [
                  const HawaTileLayer(),
                  if (ev.suspectRadiusM != null)
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: pin,
                          radius: ev.suspectRadiusM!,
                          useRadiusInMeter: true,
                          color: c.warning.withValues(alpha: 0.18),
                          borderColor: c.warning,
                          borderStrokeWidth: 1.5,
                        ),
                      ],
                    ),
                  if (traj.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: traj,
                          strokeWidth: 3,
                          color: c.info,
                          pattern: const StrokePattern.dotted(),
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: pin,
                        width: 48,
                        height: 56,
                        alignment: Alignment.topCenter,
                        child: SuspectPin(
                          icon: t.cause.icon,
                          confidence: t.causeConf,
                          semanticLabel: l.inspectorSuspect,
                        ),
                      ),
                    ],
                  ),
                  const HawaMapAttribution(),
                ],
              ),
            ),
          ),
          if (traj.length >= 2) ...[
            const SizedBox(height: 4),
            Text('··· ${l.inspectorTrajectory}', style: text.bodySmall),
          ],
          if (ev.suspectRadiusM != null)
            Text(l.inspectorArea('${(ev.suspectRadiusM! * 2).round()}'), style: text.bodySmall),
          const Divider(height: 28),
          if (ev.spikePeak != null) ...[
            Text(
              l.inspectorSpike(
                (ev.spikePollutant ?? 'pm25').toUpperCase().replaceAll('PM25', 'PM2.5'),
                Numbers.whole(ev.spikePeak!),
                Numbers.whole(ev.spikeBaseline ?? 0),
              ),
              style: text.titleSmall,
            ),
            if (ev.spikeSeries.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  height: 60,
                  child: CustomPaint(painter: _SparkPainter(ev.spikeSeries, c.dangerText)),
                ),
              ),
            if (ev.spikeSeconds != null)
              Text(
                l.inspectorSpikeMeta('${ev.spikeSeconds}', ev.spikeSource ?? '—'),
                style: text.bodySmall,
              ),
            const Divider(height: 28),
          ],
          if (ev.photos.isNotEmpty) ...[
            Text(
              l.inspectorPhoto(ev.photoAt == null ? '—' : IstTime.time(ev.photoAt!, context.lang)),
              style: text.titleSmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 96,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final (i, url) in ev.photos.indexed)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => context.push(Routes.targetPhoto(targetId, i)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: EvidenceImage(url: url, size: 96),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(l.inspectorReporter, style: text.bodySmall?.copyWith(color: c.mutedForeground)),
            const Divider(height: 28),
          ],
          if (!ev.hasEvidence) Text(l.inspectorNoEvidence, style: text.bodyMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: BigActionButton(
                  icon: Icons.navigation,
                  label: l.commonNavigate,
                  onPressed: () => _navigate(ref, t),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BigActionButton(
                  icon: onSite ? Icons.where_to_vote : Icons.where_to_vote_outlined,
                  label: onSite ? l.inspectorOnSite : l.inspectorArrived,
                  variant: BigActionVariant.secondary,
                  onPressed: onSite
                      ? null
                      : () => ref.read(inspectorActionsProvider.notifier).arrived(t),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          BigActionButton(
            icon: Icons.fact_check_outlined,
            label: l.inspectorRecord,
            onPressed: () => context.push(Routes.targetOutcome(targetId)),
          ),
        ],
      ),
    );
  }
}

/// Evidence photo from a fixture asset, the network (5-min signed URL) or a local file.
class EvidenceImage extends StatelessWidget {
  const EvidenceImage({required this.url, this.size, this.fit = BoxFit.cover, super.key});

  final String url;
  final double? size;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('asset://')) {
      return Image.asset(url.substring('asset://'.length), width: size, height: size, fit: fit);
    }
    return Image.network(
      url,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (_, _, _) => SizedBox(
        width: size,
        height: size,
        child: Center(child: Text(context.l10n.inspectorPhotosLater, textAlign: TextAlign.center)),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.points, this.color);

  final List<SpikePoint> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final values = points.map((p) => p.value).toList();
    final lo = values.reduce(math.min);
    final hi = values.reduce(math.max);
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = i / (points.length - 1) * size.width;
      final y = hi == lo
          ? size.height / 2
          : size.height - (points[i].value - lo) / (hi - lo) * size.height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.points != points;
}
