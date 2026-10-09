import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/core/storage/settings_store.dart';
import 'package:hawa_app/features/auth/application/session_controller.dart';
import 'package:hawa_app/features/auth/domain/session_state.dart';
import 'package:hawa_app/features/auth/domain/user_role.dart';
import 'package:hawa_app/features/shell/presentation/widgets/role_tile.dart';

/// A5: shown to users holding more than one app role; the last-used role is preselected.
class RolePickerScreen extends ConsumerWidget {
  const RolePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final session = ref.watch(sessionControllerProvider);
    final roles = session is SessionSignedIn ? session.appRoles : const <UserRole>[];
    final last = UserRole.fromWire(ref.watch(settingsStoreProvider).activeRole);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 16),
            Text(l.roleTitle, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            for (final role in roles) ...[
              RoleTile(
                role: role,
                selected: role == last,
                onTap: () async {
                  await ref.read(sessionControllerProvider.notifier).chooseRole(role);
                  if (context.mounted) context.go(Routes.homeFor(role.wire));
                },
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            Text(l.roleHint, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
