import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/location/location_service.dart';
import 'package:hawa_app/core/utils/geo.dart';
import 'package:hawa_app/features/citizen_air/application/air_near_me_controller.dart';
import 'package:hawa_app/features/citizen_air/domain/alert_subscription.dart';
import 'package:hawa_app/features/citizen_air/domain/manual_area.dart';

/// C2 Alerts for my area (`/citizen/subscription`): area (rounded to 0.005°), kinds, quiet hours.
/// Saved locally at once and sent through the outbox.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  AlertSubscriptionPrefs? _draft;
  bool _locating = false;

  Future<void> _save(AlertSubscriptionPrefs p) async {
    setState(() => _draft = p);
    await ref.read(subscriptionEditorProvider.notifier).save(p);
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(context.l10n.subSaved)));
    }
  }

  Future<void> _useCurrent(AlertSubscriptionPrefs p) async {
    setState(() => _locating = true);
    final loc = ref.read(locationServiceProvider);
    var status = await loc.status();
    if (status != LocationPermissionState.granted) status = await loc.request();
    final fix = status == LocationPermissionState.granted
        ? await loc.currentFix(precise: false, timeout: const Duration(seconds: 10))
        : null;
    if (!mounted) return;
    setState(() => _locating = false);
    if (fix == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.airLocationDenied)));
      return;
    }
    final home = Geo.coarse(fix.point);
    final place = await ref.read(subscriptionEditorProvider.notifier).placeFor(home);
    await _save(p.copyWith(home: home, placeName: place));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.hawaColors;
    final text = Theme.of(context).textTheme;
    final remote = ref.watch(alertSubscriptionProvider);
    final p = _draft ?? remote.value ?? const AlertSubscriptionPrefs();
    final place =
        p.placeName?.of(context.lang) ??
        (p.home == null
            ? null
            : '${p.home!.lat.toStringAsFixed(3)}, ${p.home!.lon.toStringAsFixed(3)}');
    return Scaffold(
      appBar: AppBar(title: Text(l.subTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ListTile(
            leading: const Icon(Icons.place_outlined),
            title: Text(place == null ? l.subNoArea : l.subArea(place)),
          ),
          ListTile(
            leading: _locating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            title: Text(l.subUseCurrent),
            onTap: _locating ? null : () => _useCurrent(p),
          ),
          ExpansionTile(
            leading: const Icon(Icons.map_outlined),
            title: Text(l.airPickArea),
            children: [
              for (final a in ManualArea.delhi)
                ListTile(
                  title: Text(a.name.of(context.lang)),
                  onTap: () => _save(p.copyWith(home: Geo.coarse(a.point), placeName: a.name)),
                ),
            ],
          ),
          const Divider(),
          SwitchListTile(
            title: Text(l.subKindWarn),
            value: p.warnings,
            onChanged: (v) => _save(p.copyWith(warnings: v)),
          ),
          SwitchListTile(
            title: Text(l.subKindGrap),
            value: p.grapOutlook,
            onChanged: (v) => _save(p.copyWith(grapOutlook: v)),
          ),
          ListTile(
            leading: const Icon(Icons.bedtime_outlined),
            title: Text(l.subQuiet),
            subtitle: Text(
              '${p.quietStart} – ${p.quietEnd}',
              style: text.bodySmall?.copyWith(color: c.mutedForeground),
            ),
          ),
        ],
      ),
    );
  }
}
