import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/errors/failure.dart';
import 'package:hawa_app/core/network/connectivity_service.dart';
import 'package:hawa_app/core/network/server_clock.dart';
import 'package:hawa_app/core/utils/ist_time.dart';
import 'package:hawa_app/core/widgets/offline_banner.dart';

/// Amber "Last updated 7:42 AM"; tap retries (OFFLINE_AND_SYNC §9).
class StaleBanner extends StatelessWidget {
  const StaleBanner({required this.lastUpdated, this.onRetry, super.key});

  final DateTime lastUpdated;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.hawaColors;
    return Material(
      color: c.warning,
      child: InkWell(
        onTap: onRetry,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.schedule, color: c.onWarning, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.commonStaleBanner(IstTime.time(lastUpdated, context.lang)),
                  style: TextStyle(color: c.onWarning, fontWeight: FontWeight.w600),
                ),
              ),
              if (onRetry != null) Icon(Icons.refresh, color: c.onWarning),
            ],
          ),
        ),
      ),
    );
  }
}

/// Picks one banner, most important first (OFFLINE_AND_SYNC §9): offline → stale → refresh
/// error over cached data. Renders nothing when the data is fresh.
class FreshnessBanner extends ConsumerWidget {
  const FreshnessBanner({
    required this.lastSuccess,
    required this.staleAfter,
    this.error,
    this.onRetry,
    super.key,
  });

  final DateTime? lastSuccess;
  final Duration staleAfter;
  final Object? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(networkStatusProvider).value?.isOffline ?? false;
    final failure = error == null ? null : (error is Failure ? error! as Failure : null);
    if (offline || failure is NetworkFailure || failure is SimulatedOfflineFailure) {
      return OfflineBanner(savedAt: lastSuccess);
    }
    final now = ref.watch(serverClockProvider).now();
    if (lastSuccess != null && now.difference(lastSuccess!) > staleAfter) {
      return StaleBanner(lastUpdated: lastSuccess!, onRetry: onRetry);
    }
    if (error != null && lastSuccess != null) {
      return _ErrorStrip(onRetry: onRetry);
    }
    return const SizedBox.shrink();
  }
}

class _ErrorStrip extends StatelessWidget {
  const _ErrorStrip({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.hawaColors;
    return Material(
      color: c.muted,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: c.dangerText),
            const SizedBox(width: 10),
            Expanded(child: Text(context.l10n.commonErrorBanner)),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: Text(context.l10n.commonRetry)),
          ],
        ),
      ),
    );
  }
}
