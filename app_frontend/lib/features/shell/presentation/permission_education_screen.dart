import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/widgets/big_action_button.dart';
import 'package:hawa_app/features/auth/application/session_controller.dart';
import 'package:hawa_app/features/shell/application/permission_controller.dart';
import 'package:hawa_app/features/shell/domain/app_permission.dart';

/// Shows the education screen first when needed, then the system dialog. Returns true when the
/// permission is granted. "Not now" only blocks the dependent action (SCREENS §2).
Future<bool> ensurePermission(BuildContext context, WidgetRef ref, AppPermission permission) async {
  final repo = ref.read(permissionRepositoryProvider);
  if (await repo.status(permission) == PermissionState.granted) return true;
  if (!context.mounted) return false;
  final granted = await context.push<bool>(Routes.permission(permission.name));
  return granted ?? false;
}

/// `/onboarding/permissions/:kind`: rationale before the system dialog; Open Settings when the
/// permission is permanently denied. No background-location dialog ever appears.
class PermissionEducationScreen extends ConsumerWidget {
  const PermissionEducationScreen({required this.kind, super.key});

  final AppPermission kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.hawaColors;
    final text = Theme.of(context).textTheme;
    final role = ref.watch(activeRoleWireProvider);
    final state = ref.watch(permissionControllerProvider(kind));
    final deniedForever = state.value == PermissionState.deniedForever;
    final (IconData icon, String title, String body, String? tip) = switch (kind) {
      AppPermission.notifications => (
        Icons.notifications_active,
        l.permNotifTitle,
        switch (role) {
          'driver' => l.permNotifBodyDriver,
          'inspector' => l.permNotifBodyInspector,
          'school' => l.permNotifBodySchool,
          'site_manager' => l.permNotifBodySite,
          _ => l.permNotifBodyCitizen,
        },
        role == 'driver' ? l.permNotifFallback : null,
      ),
      AppPermission.location =>
        role == 'citizen'
            ? (Icons.my_location, l.permLocTitleCitizen, l.permLocBodyCitizen, l.permLocTip)
            : (Icons.my_location, l.permLocTitle, l.permLocBodyField, l.permLocTip),
      AppPermission.camera => (Icons.photo_camera, l.permCamTitle, l.permCamBody, null),
    };

    Future<void> onContinue() async {
      final notifier = ref.read(permissionControllerProvider(kind).notifier);
      if (deniedForever) {
        await notifier.openSettings();
        await notifier.recheck();
        if (context.mounted &&
            ref.read(permissionControllerProvider(kind)).value == PermissionState.granted) {
          context.pop(true);
        }
        return;
      }
      final result = await notifier.request();
      if (context.mounted && result != PermissionState.deniedForever) {
        context.pop(result == PermissionState.granted);
      }
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: c.brand.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 60, color: c.brandText),
              ),
            ),
            const SizedBox(height: 32),
            Text(title, style: text.headlineSmall),
            const SizedBox(height: 12),
            Text(body, style: text.bodyLarge),
            if (tip != null) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, color: c.mutedForeground),
                  const SizedBox(width: 8),
                  Expanded(child: Text(tip, style: text.bodyMedium)),
                ],
              ),
            ],
            if (deniedForever) ...[
              const SizedBox(height: 16),
              Text(l.permDeniedForever, style: text.bodyMedium?.copyWith(color: c.warningText)),
            ],
            const SizedBox(height: 32),
            BigActionButton(
              icon: deniedForever ? Icons.settings : Icons.arrow_forward,
              label: deniedForever ? l.permOpenSettings : l.commonContinue,
              field: false,
              onPressed: onContinue,
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () async {
                  await ref.read(permissionRepositoryProvider).markEducationShown(kind);
                  if (context.mounted) context.pop(false);
                },
                child: Text(l.commonNotNow),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
