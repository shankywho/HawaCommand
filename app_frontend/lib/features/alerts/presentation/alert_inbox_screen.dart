import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/core/widgets/empty_state.dart';
import 'package:hawa_app/core/widgets/error_view.dart';
import 'package:hawa_app/core/widgets/loading_skeleton.dart';
import 'package:hawa_app/core/widgets/simulated_screen_chip.dart';
import 'package:hawa_app/core/widgets/stale_banner.dart';
import 'package:hawa_app/features/alerts/application/alert_inbox_controller.dart';
import 'package:hawa_app/features/alerts/domain/app_alert.dart';
import 'package:hawa_app/features/alerts/presentation/widgets/alert_tile.dart';

/// X1 Alert inbox (`/alerts`): newest first from drift (works offline), refreshed on open, on
/// sync triggers and on pull-to-refresh.
class AlertInboxScreen extends ConsumerWidget {
  const AlertInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final inbox = ref.watch(alertInboxProvider);
    final status = ref.watch(alertInboxControllerProvider);
    final lastSuccess = ref.watch(alertsLastSuccessProvider).value;
    final now = ref.watch(alertsNowProvider);
    Future<void> refresh() => ref.read(alertInboxControllerProvider.notifier).refresh();

    final alerts = inbox.value;
    final Widget body;
    if (alerts == null) {
      body = inbox.hasError
          ? ErrorView(error: inbox.error!, onRetry: refresh)
          : const LoadingSkeleton();
    } else if (alerts.isEmpty && lastSuccess == null && status.busy) {
      body = const LoadingSkeleton();
    } else if (alerts.isEmpty && lastSuccess == null && status.error != null) {
      body = ErrorView(error: status.error!, onRetry: refresh);
    } else {
      body = RefreshIndicator(
        onRefresh: refresh,
        child: alerts.isEmpty
            ? _EmptyInbox(message: l.alertsEmpty)
            : _AlertList(alerts: alerts, now: now),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.alertsTitle)),
      body: Column(
        children: [
          if (status.busy && (alerts?.isNotEmpty ?? false))
            const LinearProgressIndicator(minHeight: 2),
          FreshnessBanner(
            lastSuccess: lastSuccess,
            staleAfter: alertsStaleAfter,
            error: status.error,
            onRetry: refresh,
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _AlertList extends StatelessWidget {
  const _AlertList({required this.alerts, required this.now});

  final List<AppAlert> alerts;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final simulated = alerts.any((a) => a.isSimulated);
    final offset = simulated ? 1 : 0;
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: alerts.length + offset,
      separatorBuilder: (_, i) => i < offset ? const SizedBox(height: 8) : const Divider(height: 1),
      itemBuilder: (context, i) {
        if (i < offset) return const SimulatedScreenChip();
        final alert = alerts[i - offset];
        return AlertTile(
          key: ValueKey(alert.id),
          alert: alert,
          now: now,
          onTap: () => context.push(Routes.alert(alert.id)),
        );
      },
    );
  }
}

/// Empty state that still supports pull-to-refresh.
class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: EmptyState(icon: Icons.notifications_none, message: message),
      ),
    ),
  );
}
