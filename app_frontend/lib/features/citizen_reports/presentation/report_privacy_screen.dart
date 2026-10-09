import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/widgets/big_action_button.dart';
import 'package:hawa_app/features/citizen_reports/application/reports_controllers.dart';

/// C3 Report privacy notice (`/citizen/report/privacy`): shown before the first capture and from
/// the "i" icon; acceptance is stored on the phone.
class ReportPrivacyScreen extends ConsumerWidget {
  const ReportPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.hawaColors;
    final text = Theme.of(context).textTheme;
    final items = [
      (Icons.local_fire_department_outlined, l.privacyB1),
      (Icons.lock_outline, l.privacyB2),
      (Icons.visibility_off_outlined, l.privacyB3),
      (Icons.health_and_safety_outlined, l.privacyB4),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.privacyTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final (icon, line) in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: c.brandText),
                    const SizedBox(width: 12),
                    Expanded(child: Text(line, style: text.bodyLarge)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            BigActionButton(
              icon: Icons.check,
              label: l.privacyOk,
              onPressed: () async {
                await ref.read(reportPrivacyAcceptedProvider.notifier).accept();
                if (!context.mounted) return;
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(Routes.reportCapture);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
