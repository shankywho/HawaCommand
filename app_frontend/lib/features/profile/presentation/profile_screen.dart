import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/core/widgets/error_view.dart';
import 'package:hawa_app/core/widgets/loading_skeleton.dart';
import 'package:hawa_app/core/widgets/simulated_badge.dart';
import 'package:hawa_app/features/auth/domain/user_role.dart';
import 'package:hawa_app/features/profile/application/profile_controller.dart';
import 'package:hawa_app/features/shell/presentation/widgets/role_tile.dart';

/// X5 Profile (`/profile`): name, own phone masked, roles, wards, app version and install id.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final profile = ref.watch(profileControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.profileTitle)),
      body: profile.when(
        loading: () => const LoadingSkeleton(),
        error: (e, _) =>
            ErrorView(error: e, onRetry: () => ref.invalidate(profileControllerProvider)),
        data: (p) {
          if (p == null) return const SizedBox.shrink();
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(l.profileName),
                subtitle: Text(p.name),
                trailing: p.isSimulated ? const SimulatedBadge() : null,
              ),
              if (p.maskedPhone != null)
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: Text(l.profilePhone),
                  subtitle: Text(p.maskedPhone!),
                ),
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: Text(l.profileRoles),
                subtitle: Text(p.roles.map((r) => UserRole.fromWire(r).label(l)).join(', ')),
              ),
              if (p.wards.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.map_outlined),
                  title: Text(l.profileWard),
                  subtitle: Text(p.wards.join(', ')),
                ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l.profileVersion),
                subtitle: Text(p.appVersion),
              ),
              ListTile(
                leading: const Icon(Icons.fingerprint),
                title: Text(l.profileInstallId),
                subtitle: Text(p.installId),
                trailing: IconButton(
                  tooltip: l.profileCopy,
                  icon: const Icon(Icons.copy),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: p.installId));
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(l.profileCopied)));
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
