import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/sync/conflict_banner_bus.dart';

/// Resolved-conflict messages with dismiss (OFFLINE_AND_SYNC §7). Pass [entityIds] to show only
/// notices about those entities (e.g. one stop).
class ConflictBanner extends ConsumerWidget {
  const ConflictBanner({this.entityIds, super.key});

  final Set<String>? entityIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notices = ref
        .watch(conflictBannerBusProvider)
        .where((n) => entityIds == null || entityIds!.contains(n.entityId))
        .toList();
    if (notices.isEmpty) return const SizedBox.shrink();
    final c = context.hawaColors;
    final l = context.l10n;
    return Column(
      children: [
        for (final n in notices)
          Material(
            color: c.info.withValues(alpha: 0.12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
              child: Row(
                children: [
                  Icon(Icons.info, color: c.infoText),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(switch (n.kind) {
                      ConflictKind.tagAlreadyDone => l.conflictTagAlreadyDone,
                      ConflictKind.skipNotNeeded => l.conflictSkipNotNeeded,
                      ConflictKind.stopRemoved => l.conflictStopRemoved,
                      ConflictKind.caseClosed => l.conflictCaseClosed,
                    }),
                  ),
                  TextButton(
                    onPressed: () => ref.read(conflictBannerBusProvider.notifier).dismiss(n),
                    child: Text(l.conflictDismiss),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
