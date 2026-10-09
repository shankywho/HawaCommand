import 'package:flutter/material.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/utils/ist_time.dart';

/// Blue-grey "Offline: showing saved data from 7:42 AM" (SCREENS §0.1). Actions stay enabled
/// and queue into the outbox.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({this.savedAt, super.key});

  final DateTime? savedAt;

  @override
  Widget build(BuildContext context) {
    final c = context.hawaColors;
    final l = context.l10n;
    final text = savedAt == null
        ? l.commonOfflineNoTime
        : l.commonOfflineBanner(IstTime.time(savedAt!, context.lang));
    return Semantics(
      liveRegion: true,
      child: Material(
        color: c.offline,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.wifi_off, color: c.onOffline, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(color: c.onOffline, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
