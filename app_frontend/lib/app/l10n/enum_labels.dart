import 'package:flutter/material.dart';
import 'package:hawa_app/app/l10n/gen/app_localizations.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';

/// Labels and icons for CONTRACTS enums (SCREENS §10), including `unknown`. Icons follow the
/// Material equivalents of DESIGN_SYSTEM §7 (ARCHITECTURE §15); causes are icon + label, no hue.

extension AqiCategoryLabel on AqiCategory {
  String label(AppLocalizations l) => switch (this) {
    AqiCategory.good => l.aqiGood,
    AqiCategory.satisfactory => l.aqiSatisfactory,
    AqiCategory.moderate => l.aqiModerate,
    AqiCategory.poor => l.aqiPoor,
    AqiCategory.veryPoor => l.aqiVeryPoor,
    AqiCategory.severe => l.aqiSevere,
    AqiCategory.unknown => l.commonNoEstimate,
  };
}

extension CauseLabelX on CauseLabel {
  String label(AppLocalizations l) => switch (this) {
    CauseLabel.dust => l.causeDust,
    CauseLabel.traffic => l.causeTraffic,
    CauseLabel.burning => l.causeBurning,
    CauseLabel.regionalSmoke => l.causeRegionalSmoke,
    CauseLabel.mixed => l.causeMixed,
    CauseLabel.unknown => l.causeUnknown,
  };

  IconData get icon => switch (this) {
    CauseLabel.dust => Icons.construction,
    CauseLabel.traffic => Icons.directions_car,
    CauseLabel.burning => Icons.local_fire_department,
    CauseLabel.regionalSmoke => Icons.foggy,
    CauseLabel.mixed => Icons.layers,
    CauseLabel.unknown => Icons.help,
  };
}

extension PollutantLabel on Pollutant {
  /// "PM2.5 (fine particles)" / "PM2.5 (बारीक कण)".
  String label(AppLocalizations l) => switch (this) {
    Pollutant.pm25 => l.pollutantPm25,
    Pollutant.pm10 => l.pollutantPm10,
    Pollutant.no2 => l.pollutantNo2,
    Pollutant.co2 => l.pollutantCo2,
    _ => symbol,
  };
}

extension TaskKindLabel on TaskKind {
  String label(AppLocalizations l) => switch (this) {
    TaskKind.spray => l.kindSpray,
    TaskKind.sweep => l.kindSweep,
    TaskKind.inspect => l.kindInspect,
    TaskKind.protectAlert => l.kindProtectAlert,
    TaskKind.unknown => l.commonUnknown,
  };

  IconData get icon => switch (this) {
    TaskKind.spray => Icons.water_drop,
    TaskKind.sweep => Icons.cleaning_services,
    TaskKind.inspect => Icons.fact_check,
    TaskKind.protectAlert => Icons.shield,
    TaskKind.unknown => Icons.help,
  };
}

extension TaskStatusLabel on TaskStatus {
  String label(AppLocalizations l) => switch (this) {
    TaskStatus.pending => l.taskPending,
    TaskStatus.dispatched => l.taskDispatched,
    TaskStatus.acknowledged => l.taskAcknowledged,
    TaskStatus.enRoute => l.taskEnRoute,
    TaskStatus.inProgress => l.taskInProgress,
    TaskStatus.done => l.taskDone,
    TaskStatus.verifying => l.taskVerifying,
    TaskStatus.verified => l.taskVerified,
    TaskStatus.inconclusive => l.taskInconclusive,
    TaskStatus.skipped => l.taskSkipped,
    TaskStatus.cancelled => l.taskCancelled,
    TaskStatus.missed => l.taskMissed,
    TaskStatus.failed => l.taskFailed,
    TaskStatus.unknown => l.commonUnknown,
  };

  /// Status encodings from ARCHITECTURE §15 (icon + word, never colour alone).
  IconData get icon => switch (this) {
    TaskStatus.pending || TaskStatus.dispatched => Icons.radio_button_unchecked,
    TaskStatus.acknowledged => Icons.visibility,
    TaskStatus.enRoute => Icons.navigation,
    TaskStatus.inProgress => Icons.water_drop,
    TaskStatus.done || TaskStatus.verifying => Icons.check_circle_outline,
    TaskStatus.verified => Icons.check_circle,
    TaskStatus.inconclusive => Icons.remove_circle_outline,
    TaskStatus.skipped => Icons.skip_next,
    TaskStatus.cancelled => Icons.remove_circle,
    TaskStatus.missed => Icons.schedule,
    TaskStatus.failed => Icons.error,
    TaskStatus.unknown => Icons.help_outline,
  };
}

extension InterventionSourceLabel on InterventionSource {
  String label(AppLocalizations l) => switch (this) {
    InterventionSource.hawatag => l.sourceHawatag,
    InterventionSource.manual => l.sourceManual,
    InterventionSource.gpsInferred => l.sourceGps,
    InterventionSource.unknown => l.commonUnknown,
  };
}

extension ImpactVerdictLabel on ImpactVerdict {
  String label(AppLocalizations l) => switch (this) {
    ImpactVerdict.effective => l.verdictEffective,
    ImpactVerdict.noDetectableEffect => l.verdictNoEffect,
    ImpactVerdict.inconclusive => l.verdictInconclusive,
    ImpactVerdict.adverse => l.verdictAdverse,
    ImpactVerdict.unknown => l.commonUnknown,
  };

  IconData get icon => switch (this) {
    ImpactVerdict.effective => Icons.check_circle,
    ImpactVerdict.noDetectableEffect => Icons.circle_outlined,
    ImpactVerdict.inconclusive => Icons.blur_circular,
    ImpactVerdict.adverse => Icons.warning,
    ImpactVerdict.unknown => Icons.help_outline,
  };
}

extension ImpactMethodLabel on ImpactMethod {
  String label(AppLocalizations l) => switch (this) {
    ImpactMethod.syntheticControl => l.methodSynthetic,
    ImpactMethod.diffInDiff => l.methodDiffInDiff,
    ImpactMethod.beforeAfterNaive => l.methodNaive,
    ImpactMethod.unknown => l.commonUnknown,
  };
}

extension InspectionStatusLabel on InspectionStatus {
  String label(AppLocalizations l) => switch (this) {
    InspectionStatus.open => l.inspOpen,
    InspectionStatus.assigned => l.inspAssigned,
    InspectionStatus.onSite => l.inspOnSite,
    InspectionStatus.closedConfirmed => l.inspClosedConfirmed,
    InspectionStatus.closedNotFound => l.inspClosedNotFound,
    InspectionStatus.closedUnreachable => l.inspClosedUnreachable,
    InspectionStatus.unknown => l.commonUnknown,
  };
}

extension ReportStatusLabel on ReportStatus {
  String label(AppLocalizations l) => switch (this) {
    ReportStatus.submitted => l.reportStatusSubmitted,
    ReportStatus.verifying => l.reportStatusVerifying,
    ReportStatus.verified => l.reportStatusVerified,
    ReportStatus.rejected => l.reportStatusRejected,
    ReportStatus.ticketed => l.reportStatusTicketed,
    ReportStatus.closed => l.reportStatusClosed,
    ReportStatus.unknown => l.commonUnknown,
  };

  IconData get icon => switch (this) {
    ReportStatus.submitted => Icons.send,
    ReportStatus.verifying => Icons.hourglass_top,
    ReportStatus.verified => Icons.verified,
    ReportStatus.rejected => Icons.do_not_disturb_on,
    ReportStatus.ticketed => Icons.directions_walk,
    ReportStatus.closed => Icons.check_circle,
    ReportStatus.unknown => Icons.help_outline,
  };
}

extension ConfidenceLabel on ConfidenceLevel {
  String label(AppLocalizations l) => switch (this) {
    ConfidenceLevel.high => l.confHigh,
    ConfidenceLevel.medium => l.confMedium,
    ConfidenceLevel.low => l.confLow,
  };
}

/// "Stage III · Severe" / "चरण III · गंभीर".
String grapLabel(int stage, AppLocalizations l) => switch (stage) {
  1 => l.grap1,
  2 => l.grap2,
  3 => l.grap3,
  4 => l.grap4,
  _ => l.grap0,
};
