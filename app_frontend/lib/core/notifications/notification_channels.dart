import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hawa_app/app/l10n/gen/app_localizations.dart';

/// Android channels (ARCHITECTURE §10.2). Names are localized and re-registered on language
/// change (Android updates the name of an existing id).
abstract final class NotificationChannels {
  static const routeUpdates = 'route_updates';
  static const airAlerts = 'air_alerts';
  static const reports = 'reports';
  static const deviceStatus = 'device_status';
  static const shiftTracking = 'shift_tracking';

  /// Push `type` → channel id.
  static String forType(String type) => switch (type) {
    'route_assignment' ||
    'route_changed' ||
    'task_done_auto' ||
    'inspection_target' => routeUpdates,
    'pollutant_warning' || 'safe_window' || 'grap_outlook' => airAlerts,
    'report_outcome' => reports,
    'device_health' => deviceStatus,
    _ => airAlerts,
  };

  static List<AndroidNotificationChannel> all(AppLocalizations l10n) => [
    AndroidNotificationChannel(
      routeUpdates,
      l10n.channelRouteUpdates,
      importance: Importance.high,
      sound: const RawResourceAndroidNotificationSound('stop_done'),
    ),
    AndroidNotificationChannel(airAlerts, l10n.channelAirAlerts, importance: Importance.high),
    AndroidNotificationChannel(reports, l10n.channelReports),
    AndroidNotificationChannel(deviceStatus, l10n.channelDeviceStatus),
    AndroidNotificationChannel(
      shiftTracking,
      l10n.channelShiftTracking,
      importance: Importance.low,
    ),
  ];
}
