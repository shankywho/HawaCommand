/// `AlertKind` (CONTRACTS §3) plus the proposed `route_changed` and `task_done_auto`
/// (ARCHITECTURE §7.3) and `unknown` for values this build does not know yet.
enum AlertKind {
  pollutantWarning('pollutant_warning'),
  safeWindow('safe_window'),
  routeAssignment('route_assignment'),
  inspectionTarget('inspection_target'),
  grapOutlook('grap_outlook'),
  reportOutcome('report_outcome'),
  deviceHealth('device_health'),

  /// Proposed addition.
  routeChanged('route_changed'),

  /// Proposed addition.
  taskDoneAuto('task_done_auto'),
  unknown('unknown');

  const AlertKind(this.wire);

  final String wire;

  static AlertKind fromWire(String? wire) {
    for (final k in values) {
      if (k.wire == wire) return k;
    }
    return unknown;
  }
}
