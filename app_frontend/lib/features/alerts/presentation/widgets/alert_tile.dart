import 'package:flutter/material.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/utils/ist_time.dart';
import 'package:hawa_app/core/widgets/simulated_badge.dart';
import 'package:hawa_app/core/widgets/status_pill.dart';
import 'package:hawa_app/features/alerts/domain/app_alert.dart';
import 'package:hawa_app/features/alerts/presentation/widgets/alert_kind_label.dart';

/// "6:50 AM" for today, "Thu 12 Nov, 10:00 PM" otherwise (IST).
String alertTimeLabel(DateTime t, DateTime now, String lang) =>
    IstTime.serviceDate(t) == IstTime.serviceDate(now)
    ? IstTime.time(t, lang)
    : '${IstTime.shortDate(t, lang)}, ${IstTime.time(t, lang)}';

/// X1 row: kind icon, title, IST time, unread dot + "New", "Expired" (greyed), ack tick.
class AlertTile extends StatelessWidget {
  const AlertTile({required this.alert, required this.now, required this.onTap, super.key});

  final AppAlert alert;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.hawaColors;
    final text = Theme.of(context).textTheme;
    final expired = alert.isExpiredAt(now);
    final unread = !alert.isRead;
    final fg = expired ? c.mutedForeground : c.foreground;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(alert.kind.icon, color: expired ? c.mutedForeground : c.brandText),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium?.copyWith(
                      color: fg,
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${alert.kind.label(l)} · ${alertTimeLabel(alert.receivedAt, now, context.lang)}',
                    style: text.bodySmall?.copyWith(color: c.mutedForeground),
                  ),
                  if (expired || alert.isAcked || alert.isSimulated) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (expired) StatusPill(icon: Icons.history, label: l.alertsExpired),
                        if (alert.isAcked) _AckedTick(at: alert.ackedAt!),
                        if (alert.isSimulated) const SimulatedBadge(),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (unread) ...[const SizedBox(width: 8), const _NewMarker()],
          ],
        ),
      ),
    );
  }
}

class _NewMarker extends StatelessWidget {
  const _NewMarker();

  @override
  Widget build(BuildContext context) {
    final c = context.hawaColors;
    return Column(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c.info, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.alertsNew,
          style: TextStyle(color: c.infoText, fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ],
    );
  }
}

class _AckedTick extends StatelessWidget {
  const _AckedTick({required this.at});

  final DateTime at;

  @override
  Widget build(BuildContext context) {
    final c = context.hawaColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle, size: 16, color: c.brandText),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            context.l10n.alertAcked(IstTime.time(at, context.lang)),
            style: TextStyle(color: c.brandText, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
