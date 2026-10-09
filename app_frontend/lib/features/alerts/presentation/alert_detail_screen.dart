import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/utils/ist_time.dart';
import 'package:hawa_app/core/widgets/big_action_button.dart';
import 'package:hawa_app/core/widgets/empty_state.dart';
import 'package:hawa_app/core/widgets/error_view.dart';
import 'package:hawa_app/core/widgets/loading_skeleton.dart';
import 'package:hawa_app/core/widgets/simulated_badge.dart';
import 'package:hawa_app/core/widgets/simulated_screen_chip.dart';
import 'package:hawa_app/core/widgets/status_pill.dart';
import 'package:hawa_app/features/alerts/application/alert_detail_controller.dart';
import 'package:hawa_app/features/alerts/application/alert_inbox_controller.dart';
import 'package:hawa_app/features/alerts/domain/app_alert.dart';
import 'package:hawa_app/features/alerts/presentation/widgets/alert_kind_label.dart';

/// X2 Alert detail (`/alerts/:alertId`): opening marks it read; school alerts (and GRAP
/// outlooks for site managers) offer "I've read this", queued as one `alert_ack` op.
class AlertDetailScreen extends ConsumerWidget {
  const AlertDetailScreen({required this.alertId, super.key});

  final String alertId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final detail = ref.watch(alertDetailProvider(alertId));
    return Scaffold(
      appBar: AppBar(title: Text(l.alertsTitle)),
      body: detail.when(
        data: (alert) => alert == null
            ? EmptyState(icon: Icons.notifications_none, message: l.alertsEmpty)
            : _AlertBody(alert: alert),
        loading: () => const LoadingSkeleton(blocks: 3),
        error: (e, _) =>
            ErrorView(error: e, onRetry: () => ref.invalidate(alertDetailProvider(alertId))),
      ),
    );
  }
}

class _AlertBody extends ConsumerWidget {
  const _AlertBody({required this.alert});

  final AppAlert alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.hawaColors;
    final text = Theme.of(context).textTheme;
    final lang = context.lang;
    final now = ref.watch(alertsNowProvider);
    final role = ref.watch(alertsActiveRoleProvider);
    final related = ref.watch(alertRelatedRouteProvider(alert.id, alert.deepLink));
    final busy = ref.watch(alertAckControllerProvider(alert.id));
    final received =
        '${IstTime.shortDate(alert.receivedAt, lang)}, '
        '${IstTime.time(alert.receivedAt, lang)}';

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (alert.isSimulated) const SimulatedScreenChip(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(alert.kind.icon, color: c.brandText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      alert.kind.label(l),
                      style: text.labelLarge?.copyWith(color: c.mutedForeground),
                    ),
                  ),
                  if (alert.isSimulated) const SimulatedBadge(),
                ],
              ),
              const SizedBox(height: 12),
              Text(alert.title, style: text.headlineSmall),
              const SizedBox(height: 8),
              Text(alert.body, style: text.bodyLarge),
              const SizedBox(height: 12),
              Text(
                l.alertReceived(received),
                style: text.bodySmall?.copyWith(color: c.mutedForeground),
              ),
              if (alert.isExpiredAt(now)) ...[
                const SizedBox(height: 8),
                StatusPill(icon: Icons.history, label: l.alertsExpired),
              ],
              if (related != null) ...[
                const SizedBox(height: 24),
                BigActionButton(
                  icon: Icons.open_in_new,
                  label: l.alertOpenRelated,
                  variant: BigActionVariant.secondary,
                  field: false,
                  onPressed: () => unawaited(context.push(related)),
                ),
              ],
              if (alert.canAcknowledge(role)) ...[
                const SizedBox(height: 16),
                if (alert.isAcked)
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: c.brandText),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.alertAcked(IstTime.time(alert.ackedAt!, lang)),
                          style: text.titleMedium?.copyWith(color: c.brandText),
                        ),
                      ),
                    ],
                  )
                else
                  BigActionButton(
                    icon: Icons.check,
                    label: l.alertAck,
                    field: false,
                    busy: busy,
                    onPressed: busy
                        ? null
                        : () => unawaited(
                            ref.read(alertAckControllerProvider(alert.id).notifier).acknowledge(),
                          ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
