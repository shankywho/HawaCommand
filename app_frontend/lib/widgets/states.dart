import 'package:flutter/material.dart';
import 'package:hawacommand_app/app/theme.dart';
import 'package:hawacommand_app/core/i18n.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: HawaColors.teal,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            tr.primary('लोड हो रहा है…', 'Loading…'),
            style: tr.style(14, color: HawaColors.muted2),
          ),
          if (tr.isBoth) Text('Loading', style: HawaText.sans(12, color: HawaColors.muted)),
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.wifiOff, size: 32, color: HawaColors.muted),
            const SizedBox(height: 12),
            Text(
              tr.primary('कुछ गड़बड़ हुई', 'Something went wrong'),
              style: tr.style(18, weight: FontWeight.w600),
            ),
            Text(
              message,
              textAlign: TextAlign.center,
              style: HawaText.sans(13, color: HawaColors.muted),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: Text(tr('फिर कोशिश करें', 'Retry')),
              style: OutlinedButton.styleFrom(
                foregroundColor: HawaColors.ink,
                side: const BorderSide(color: HawaColors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
