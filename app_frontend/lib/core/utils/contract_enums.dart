/// Enums from docs/CONTRACTS.md §3 that more than one feature (or a core widget) uses.
///
/// Every enum keeps the exact `snake_case` wire value and an `unknown` member, so a value the
/// app does not know yet renders neutrally instead of crashing (CONTRACTS §12.5).
library;

T _fromWire<T extends Enum>(List<T> values, String? wire, String Function(T) wireOf, T unknown) {
  if (wire == null) return unknown;
  for (final v in values) {
    if (wireOf(v) == wire) return v;
  }
  return unknown;
}

enum AqiCategory {
  good('good'),
  satisfactory('satisfactory'),
  moderate('moderate'),
  poor('poor'),
  veryPoor('very_poor'),
  severe('severe'),
  unknown('unknown');

  const AqiCategory(this.wire);
  final String wire;

  static AqiCategory fromWire(String? w) => _fromWire(values, w, (e) => e.wire, unknown);

  /// `good` and `satisfactory` count as fine for advice rules (SCREENS C1).
  bool get isAtMostSatisfactory => this == good || this == satisfactory;
}

enum CauseLabel {
  dust('dust'),
  traffic('traffic'),
  burning('burning'),
  regionalSmoke('regional_smoke'),
  mixed('mixed'),
  unknown('unknown');

  const CauseLabel(this.wire);
  final String wire;

  static CauseLabel fromWire(String? w) => _fromWire(values, w, (e) => e.wire, unknown);
}

enum Pollutant {
  pm1('pm1'),
  pm25('pm25'),
  pm10('pm10'),
  no2('no2'),
  co('co'),
  nh3('nh3'),
  voc('voc'),
  co2('co2'),
  unknown('unknown');

  const Pollutant(this.wire);
  final String wire;

  static Pollutant fromWire(String? w) => _fromWire(values, w, (e) => e.wire, unknown);

  /// Technical token kept in Latin script in both languages (ARCHITECTURE §14).
  String get symbol => switch (this) {
    pm1 => 'PM1',
    pm25 => 'PM2.5',
    pm10 => 'PM10',
    no2 => 'NO₂',
    co => 'CO',
    nh3 => 'NH₃',
    voc => 'VOC',
    co2 => 'CO₂',
    unknown => '—',
  };
}

enum TaskKind {
  spray('spray'),
  sweep('sweep'),
  inspect('inspect'),
  protectAlert('protect_alert'),
  unknown('unknown');

  const TaskKind(this.wire);
  final String wire;

  static TaskKind fromWire(String? w) => _fromWire(values, w, (e) => e.wire, unknown);
}

enum TaskStatus {
  pending('pending'),
  dispatched('dispatched'),
  acknowledged('acknowledged'),
  enRoute('en_route'),
  inProgress('in_progress'),
  done('done'),
  verifying('verifying'),
  verified('verified'),
  inconclusive('inconclusive'),
  skipped('skipped'),
  cancelled('cancelled'),
  missed('missed'),
  failed('failed'),
  unknown('unknown');

  const TaskStatus(this.wire);
  final String wire;

  static TaskStatus fromWire(String? w) => _fromWire(values, w, (e) => e.wire, unknown);

  /// Terminal per the backend state machine (API.md §7): no further app transitions.
  bool get isTerminal => const {
    done,
    verifying,
    verified,
    inconclusive,
    skipped,
    cancelled,
    missed,
    failed,
  }.contains(this);

  /// Work finished on the ground (done or later in the verification chain).
  bool get isCompleted => const {done, verifying, verified, inconclusive}.contains(this);

  /// Still to do: the driver can act on it.
  bool get isOpen => const {pending, dispatched, acknowledged, enRoute, inProgress}.contains(this);

  /// Skip is offered only before spraying starts (SCREENS D4).
  bool get canSkip => const {dispatched, acknowledged, enRoute}.contains(this);

  /// Manual done is accepted only from these states (backend ARCHITECTURE §5.2).
  bool get allowsManualDone => this == acknowledged || this == enRoute;
}

/// Completion-source precedence, server and app agree: hawatag > gps_inferred > manual.
enum InterventionSource {
  hawatag('hawatag', 3),
  gpsInferred('gps_inferred', 2),
  manual('manual', 1),
  unknown('unknown', 0);

  const InterventionSource(this.wire, this.rank);
  final String wire;
  final int rank;

  static InterventionSource fromWire(String? w) => _fromWire(values, w, (e) => e.wire, unknown);
}

enum ImpactMethod {
  syntheticControl('synthetic_control'),
  diffInDiff('diff_in_diff'),
  beforeAfterNaive('before_after_naive'),
  unknown('unknown');

  const ImpactMethod(this.wire);
  final String wire;

  static ImpactMethod fromWire(String? w) => _fromWire(values, w, (e) => e.wire, unknown);

  /// Naive before/after is flagged "low evidence" (CONTRACTS §3).
  bool get isLowerEvidence => this == beforeAfterNaive;
}

enum ImpactVerdict {
  effective('effective'),
  noDetectableEffect('no_detectable_effect'),
  inconclusive('inconclusive'),
  adverse('adverse'),
  unknown('unknown');

  const ImpactVerdict(this.wire);
  final String wire;

  static ImpactVerdict fromWire(String? w) => _fromWire(values, w, (e) => e.wire, unknown);
}

enum InspectionStatus {
  open('open'),
  assigned('assigned'),
  onSite('on_site'),
  closedConfirmed('closed_confirmed'),
  closedNotFound('closed_not_found'),
  closedUnreachable('closed_unreachable'),
  unknown('unknown');

  const InspectionStatus(this.wire);
  final String wire;

  static InspectionStatus fromWire(String? w) => _fromWire(values, w, (e) => e.wire, unknown);

  bool get isClosed => const {closedConfirmed, closedNotFound, closedUnreachable}.contains(this);
}

enum InspectionOrigin {
  report('report'),
  spike('spike'),
  hotspot('hotspot'),
  plan('plan'),
  manual('manual'),
  unknown('unknown');

  const InspectionOrigin(this.wire);
  final String wire;

  static InspectionOrigin fromWire(String? w) => _fromWire(values, w, (e) => e.wire, unknown);
}

enum DeviceStatus {
  provisioned('provisioned'),
  active('active'),
  degraded('degraded'),
  offline('offline'),
  retired('retired'),
  unknown('unknown');

  const DeviceStatus(this.wire);
  final String wire;

  static DeviceStatus fromWire(String? w) => _fromWire(values, w, (e) => e.wire, unknown);

  /// Manual done is offered only when the HawaTag cannot confirm (SCREENS D3).
  bool get cannotConfirm => this == offline || this == degraded;
}

enum ShiftStatus {
  scheduled('scheduled'),
  active('active'),
  ended('ended'),
  unknown('unknown');

  const ShiftStatus(this.wire);
  final String wire;

  static ShiftStatus fromWire(String? w) => _fromWire(values, w, (e) => e.wire, unknown);
}

enum ReportStatus {
  submitted('submitted'),
  verifying('verifying'),
  verified('verified'),
  rejected('rejected'),
  ticketed('ticketed'),
  closed('closed'),
  unknown('unknown');

  const ReportStatus(this.wire);
  final String wire;

  static ReportStatus fromWire(String? w) => _fromWire(values, w, (e) => e.wire, unknown);
}

/// High ≥ 0.7, Medium 0.4–0.7, Low < 0.4 (DESIGN_SYSTEM §2.5, shared with the console).
enum ConfidenceLevel {
  high,
  medium,
  low;

  static ConfidenceLevel of(double value) => value >= 0.7
      ? high
      : value >= 0.4
      ? medium
      : low;
}
