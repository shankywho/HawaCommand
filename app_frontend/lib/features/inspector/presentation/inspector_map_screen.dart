import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/enum_labels.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/core/maps/hawa_tile_layer.dart';
import 'package:hawa_app/core/maps/map_markers.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/features/inspector/application/inspector_controllers.dart';
import 'package:hawa_app/features/shell/presentation/widgets/shell_app_bar.dart';
import 'package:latlong2/latlong.dart';

/// I2 Inspector map (`/inspector/map`): suspect pins for all open targets with cause icon +
/// confidence text; tap → I3. Same tile and attribution rules as D2.
class InspectorMapScreen extends ConsumerWidget {
  const InspectorMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final targets = ref.watch(inspectionTargetsProvider).value ?? const [];
    final pts = [for (final t in targets) LatLng(t.location.lat, t.location.lon)];
    return Scaffold(
      appBar: ShellAppBar(title: l.inspectorMapTitle),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: pts.isEmpty ? const LatLng(28.6440, 77.1900) : pts.first,
              initialCameraFit: pts.length >= 2
                  ? CameraFit.coordinates(coordinates: pts, padding: const EdgeInsets.all(60))
                  : null,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              const HawaTileLayer(),
              MarkerLayer(
                markers: [
                  for (final t in targets)
                    Marker(
                      point: LatLng(t.location.lat, t.location.lon),
                      width: 120,
                      height: 72,
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        onTap: () => context.push(Routes.target(t.id)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SuspectPin(
                              icon: t.cause.icon,
                              confidence: t.causeConf,
                              semanticLabel: l.inspectorLikely(t.cause.label(l)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              color: Colors.white.withValues(alpha: 0.9),
                              child: Text(
                                '${ConfidenceLevel.of(t.causeConf).label(l)} ${(t.causeConf * 100).round()} %',
                                style: const TextStyle(fontSize: 10, color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const HawaMapAttribution(),
        ],
      ),
    );
  }
}
