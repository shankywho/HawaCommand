import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/utils/numbers.dart';
import 'package:hawa_app/features/driver_route/application/auto_done_events.dart';
import 'package:hawa_app/features/driver_route/application/route_change_detector.dart';
import 'package:hawa_app/features/driver_route/domain/auto_done_event.dart';

/// "Route changed: 1 added, 1 removed" with See changes (highlights the affected cards).
class RouteChangedBanner extends ConsumerWidget {
  const RouteChangedBanner({required this.onSeeChanges, super.key});

  final VoidCallback onSeeChanges;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diff = ref.watch(routeChangeNoticeProvider);
    if (diff == null) return const SizedBox.shrink();
    final l = context.l10n;
    final c = context.hawaColors;
    return MaterialBanner(
      backgroundColor: c.info.withValues(alpha: 0.12),
      leading: Icon(Icons.alt_route, color: c.infoText),
      content: Text(l.driverRouteChanged('${diff.added.length}', '${diff.removed.length}')),
      actions: [
        TextButton(onPressed: onSeeChanges, child: Text(l.driverSeeChanges)),
        IconButton(
          tooltip: l.commonClose,
          onPressed: ref.read(routeChangeNoticeProvider.notifier).dismiss,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}

/// HawaTag auto-done: a big tick for 1.5 s with haptics and a click sound (SCREENS D1). Wraps the
/// route screen and listens to the one-shot event stream.
class AutoDoneOverlay extends ConsumerStatefulWidget {
  const AutoDoneOverlay({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AutoDoneOverlay> createState() => _AutoDoneOverlayState();
}

class _AutoDoneOverlayState extends ConsumerState<AutoDoneOverlay> {
  AutoDoneEvent? _event;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _show(AutoDoneEvent e) {
    unawaited(HapticFeedback.heavyImpact());
    unawaited(SystemSound.play(SystemSoundType.alert));
    setState(() => _event = e);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _event = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(autoDoneEventsProvider, (_, next) {
      final e = next.value;
      if (e != null) _show(e);
    });
    final l = context.l10n;
    final c = context.hawaColors;
    final e = _event;
    return Stack(
      children: [
        widget.child,
        if (e != null)
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.35),
                child: Center(
                  child: Semantics(
                    liveRegion: true,
                    label: l.driverAutoDoneTitle('${e.sequence}'),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 96, color: c.brand),
                            const SizedBox(height: 8),
                            Text(
                              l.driverAutoDoneTitle('${e.sequence}'),
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            if (e.litres != null)
                              Text(l.driverAutoDoneBody(Numbers.whole(e.litres!))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
