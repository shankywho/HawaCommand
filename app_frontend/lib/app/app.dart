import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/providers.dart';
import 'package:hawa_app/app/router/router.dart';
import 'package:hawa_app/app/theme/app_theme.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/notifications/in_app_messages.dart';
import 'package:hawa_app/core/notifications/local_notifications.dart';
import 'package:hawa_app/core/notifications/push_payload.dart';
import 'package:hawa_app/core/storage/settings_store.dart';
import 'package:hawa_app/features/auth/application/session_controller.dart';

/// MaterialApp.router with the three theme modes (light, dark, outdoor), locale and an overlay
/// for in-app alert banners (ARCHITECTURE §2, §15).
class HawaApp extends ConsumerWidget {
  const HawaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref
      ..watch(appWiringProvider)
      ..listen(appPreferencesControllerProvider.select((p) => p.lang), (_, lang) {
        // Channel names follow the UI language (Android renames an existing id).
        unawaited(
          ref
              .read(localNotificationsProvider)
              .registerChannels(lookupAppLocalizations(Locale(lang))),
        );
      });
    final prefs = ref.watch(appPreferencesControllerProvider);
    final role = ref.watch(activeRoleWireProvider);
    final hindi = prefs.lang == 'hi';
    final field = role == 'driver' || role == 'inspector';
    final outdoor =
        prefs.displayMode == DisplayMode.outdoor ||
        (prefs.displayMode == DisplayMode.auto && field);
    final light = outdoor
        ? AppTheme.outdoor(hindi: hindi, cvd: prefs.cvdPalette)
        : AppTheme.light(hindi: hindi, cvd: prefs.cvdPalette);
    final mode = switch (prefs.displayMode) {
      DisplayMode.dark => ThemeMode.dark,
      DisplayMode.auto when !field => ThemeMode.system,
      _ => ThemeMode.light,
    };
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: light,
      darkTheme: AppTheme.dark(hindi: hindi, cvd: prefs.cvdPalette),
      themeMode: mode,
      highContrastTheme: AppTheme.outdoor(hindi: hindi, cvd: prefs.cvdPalette),
      locale: Locale(prefs.lang),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => _InAppBannerHost(child: child ?? const SizedBox.shrink()),
    );
  }
}

/// Foreground pushes appear as a banner over the current screen (ARCHITECTURE §10.2).
class _InAppBannerHost extends ConsumerWidget {
  const _InAppBannerHost({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(inAppMessagesProvider);
    final top = messages.isEmpty ? null : messages.first;
    return Stack(
      children: [
        child,
        if (top != null)
          Positioned(
            left: 8,
            right: 8,
            top: MediaQuery.paddingOf(context).top + 8,
            child: _Banner(key: ValueKey(top), payload: top),
          ),
      ],
    );
  }
}

class _Banner extends ConsumerStatefulWidget {
  const _Banner({required this.payload, super.key});

  final PushPayload payload;

  @override
  ConsumerState<_Banner> createState() => _BannerState();
}

class _BannerState extends ConsumerState<_Banner> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 6), _dismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _dismiss() {
    if (mounted) ref.read(inAppMessagesProvider.notifier).dismiss(widget.payload);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.hawaColors;
    final p = widget.payload;
    return Material(
      elevation: 6,
      color: c.ink,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _dismiss();
          unawaited(ref.read(appWiringProvider).open(p));
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
          child: Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (p.title != null)
                      Text(
                        p.title!,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    if (p.body != null)
                      Text(
                        '${p.body!}${p.isSimulated ? context.l10n.pushSimulatedSuffix : ''}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: context.l10n.commonClose,
                onPressed: _dismiss,
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
