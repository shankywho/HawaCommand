import 'package:flutter/material.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/features/alerts/domain/alert_kind.dart';

/// Label + icon per alert kind (SCREENS §10); the icon never stands alone.
extension AlertKindLabel on AlertKind {
  String label(AppLocalizations l) => switch (this) {
    AlertKind.pollutantWarning => l.alertKindPollutantWarning,
    AlertKind.safeWindow => l.alertKindSafeWindow,
    AlertKind.routeAssignment => l.alertKindRouteAssignment,
    AlertKind.inspectionTarget => l.alertKindInspectionTarget,
    AlertKind.grapOutlook => l.alertKindGrapOutlook,
    AlertKind.reportOutcome => l.alertKindReportOutcome,
    AlertKind.deviceHealth => l.alertKindDeviceHealth,
    AlertKind.routeChanged => l.alertKindRouteChanged,
    AlertKind.taskDoneAuto => l.alertKindTaskDoneAuto,
    AlertKind.unknown => l.commonUnknown,
  };

  IconData get icon => switch (this) {
    AlertKind.pollutantWarning => Icons.warning_amber,
    AlertKind.safeWindow => Icons.wb_sunny_outlined,
    AlertKind.routeAssignment => Icons.route,
    AlertKind.inspectionTarget => Icons.fact_check,
    AlertKind.grapOutlook => Icons.shield,
    AlertKind.reportOutcome => Icons.assignment_turned_in,
    AlertKind.deviceHealth => Icons.sensors_off,
    AlertKind.routeChanged => Icons.alt_route,
    AlertKind.taskDoneAuto => Icons.task_alt,
    AlertKind.unknown => Icons.notifications_outlined,
  };
}
