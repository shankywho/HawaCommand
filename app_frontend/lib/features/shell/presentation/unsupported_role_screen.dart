import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/widgets/big_action_button.dart';
import 'package:hawa_app/features/auth/application/session_controller.dart';

/// A6: officers, admins and analysts use the web console.
class UnsupportedRoleScreen extends ConsumerWidget {
  const UnsupportedRoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.desktop_windows, size: 72, color: context.hawaColors.mutedForeground),
              const SizedBox(height: 24),
              Text(
                l.unsupportedRoleBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 32),
              BigActionButton(
                icon: Icons.logout,
                label: l.settingsLogout,
                field: false,
                variant: BigActionVariant.secondary,
                onPressed: () => ref.read(sessionControllerProvider.notifier).signOut(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
