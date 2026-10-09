import 'package:flutter/material.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/errors/failure.dart';
import 'package:hawa_app/core/errors/failure_messages.dart';

/// Localized message + Retry + a "Details" expander with the request id. The server's raw
/// `detail` is never shown to field users (ARCHITECTURE §6.4).
class ErrorView extends StatelessWidget {
  const ErrorView({required this.error, this.onRetry, super.key});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final failure = asFailure(error);
    final c = context.hawaColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              failure is NetworkFailure || failure is SimulatedOfflineFailure
                  ? Icons.wifi_off
                  : Icons.error_outline,
              size: 56,
              color: c.mutedForeground,
            ),
            const SizedBox(height: 12),
            Text(
              failure.message(l),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(l.commonRetry),
              ),
            ],
            if (failure.requestId != null || failure.code != null)
              ExpansionTile(
                title: Text(l.commonDetails, style: Theme.of(context).textTheme.bodySmall),
                children: [
                  if (failure.requestId != null)
                    SelectableText(l.commonRequestId(failure.requestId!)),
                  if (failure.code != null) SelectableText(failure.code!),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
