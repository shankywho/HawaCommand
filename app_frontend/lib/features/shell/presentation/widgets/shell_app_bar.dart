import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/storage/settings_store.dart';
import 'package:hawa_app/core/widgets/sync_status_chip.dart';
import 'package:hawa_app/features/auth/application/session_controller.dart';

/// Unread alert count for the bell badge.
final StreamProvider<int> unreadAlertsProvider = StreamProvider.autoDispose<int>(
  (ref) => ref
      .watch(appDatabaseProvider)
      .alertDao
      .watchUnreadCount(role: ref.watch(activeRoleWireProvider)),
);

/// App bar for role screens (SCREENS §0.3): title, then per role
/// driver/inspector: outdoor toggle, sync chip, alerts bell · school: language toggle, sync chip ·
/// citizen: sync chip, alerts bell · site: none.
class ShellAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ShellAppBar({
    required this.title,
    this.subtitle,
    this.leading,
    this.extraActions = const [],
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> extraActions;

  @override
  Size get preferredSize =>
      Size.fromHeight(subtitle == null ? kToolbarHeight : kToolbarHeight + 16);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(activeRoleWireProvider);
    final field = role == 'driver' || role == 'inspector';
    return AppBar(
      leading: leading,
      toolbarHeight: preferredSize.height,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, overflow: TextOverflow.ellipsis),
          if (subtitle != null)
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      actions: [
        ...extraActions,
        if (field) const OutdoorToggle(),
        if (role == 'school') const LanguageToggle(),
        if (role != 'site_manager') const SyncStatusChip(),
        if (role != 'school' && role != 'site_manager') const AlertsBell(),
        const SizedBox(width: 4),
      ],
    );
  }
}

/// Sun icon: outdoor (high contrast) ↔ standard (ARCHITECTURE §20).
class OutdoorToggle extends ConsumerWidget {
  const OutdoorToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outdoor = context.hawaColors.outdoor;
    return IconButton(
      tooltip: context.l10n.commonOutdoorMode,
      isSelected: outdoor,
      icon: Icon(outdoor ? Icons.wb_sunny : Icons.wb_sunny_outlined),
      onPressed: () => ref
          .read(appPreferencesControllerProvider.notifier)
          .setDisplayMode(outdoor ? DisplayMode.standard : DisplayMode.outdoor),
    );
  }
}

/// हिन्दी | English segmented toggle (school home, F19); switches instantly and persists.
class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = context.lang;
    Future<void> set(String l) async {
      await ref.read(appPreferencesControllerProvider.notifier).setLanguage(l);
      await ref.read(sessionControllerProvider.notifier).enqueueLanguage(l);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SegmentedButton<String>(
        showSelectedIcon: false,
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
        segments: const [
          ButtonSegment(value: 'hi', label: Text('हिन्दी')),
          ButtonSegment(value: 'en', label: Text('EN')),
        ],
        selected: {lang},
        onSelectionChanged: (s) => set(s.first),
      ),
    );
  }
}

class AlertsBell extends ConsumerWidget {
  const AlertsBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadAlertsProvider).value ?? 0;
    return IconButton(
      tooltip: context.l10n.commonAlerts,
      onPressed: () => context.push(Routes.alerts),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text('$unread'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
