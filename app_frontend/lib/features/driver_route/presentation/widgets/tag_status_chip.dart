import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/core/utils/clock.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/core/utils/ist_time.dart';
import 'package:hawa_app/core/widgets/status_pill.dart';
import 'package:hawa_app/features/driver_route/domain/asset_summary.dart';

/// "HawaTag online, seen 1 min ago" / "HawaTag offline since 7:10 AM" (icon + words).
class TagStatusChip extends ConsumerWidget {
  const TagStatusChip({required this.asset, super.key});

  final AssetSummary? asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final a = asset;
    if (a == null || a.tagStatus == DeviceStatus.unknown) {
      return StatusPill(icon: Icons.sensors_off_outlined, label: l.driverTagUnknown);
    }
    final now = ref.watch(appClockProvider).now();
    final seen = a.tagLastSeenAt;
    String ago() {
      if (seen == null) return l.commonJustNow;
      final m = now.difference(seen).inMinutes;
      if (m < 1) return l.commonJustNow;
      if (m < 60) return l.commonMinutesAgo('$m');
      return l.commonHoursAgo('${m ~/ 60}');
    }

    if (a.tagCannotConfirm) {
      return StatusPill(
        icon: Icons.sensors_off,
        tone: StatusTone.warning,
        label: l.driverTagOffline(seen == null ? '—' : IstTime.time(seen, context.lang)),
      );
    }
    return StatusPill(icon: Icons.sensors, tone: StatusTone.brand, label: l.driverTagOnline(ago()));
  }
}
