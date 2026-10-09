import 'package:flutter/material.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/core/widgets/big_action_button.dart';

/// Two-large-button confirmation sheet. Returns true when confirmed. Destructive and primary
/// actions are ≥ 8 dp apart (ARCHITECTURE §20).
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String? body,
  IconData icon = Icons.check,
  bool danger = false,
  String? cancelLabel,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(body, style: Theme.of(context).textTheme.bodyLarge),
            ],
            const SizedBox(height: 20),
            BigActionButton(
              icon: icon,
              label: confirmLabel,
              variant: danger ? BigActionVariant.danger : BigActionVariant.primary,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 12),
            BigActionButton(
              icon: Icons.close,
              label: cancelLabel ?? context.l10n.commonCancel,
              variant: BigActionVariant.secondary,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}
