import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/sync/outbox_repository.dart';

/// Outbox depth in the app bar (e.g. "2"), hidden when empty; opens `/settings/sync`.
class SyncStatusChip extends ConsumerWidget {
  const SyncStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depth = ref.watch(outboxDepthProvider).value ?? 0;
    if (depth == 0) return const SizedBox.shrink();
    final c = context.hawaColors;
    return Semantics(
      button: true,
      label: context.l10n.commonPendingCount('$depth'),
      excludeSemantics: true,
      child: InkWell(
        onTap: () => context.push(Routes.syncQueue),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: c.warning,
              borderRadius: BorderRadius.circular(999),
              border: c.outdoor ? Border.all(color: c.ink, width: 2) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_upload, size: 16, color: c.onWarning),
                const SizedBox(width: 4),
                Text(
                  '$depth',
                  style: TextStyle(color: c.onWarning, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
