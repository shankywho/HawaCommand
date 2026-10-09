/// `SkipReason` (CONTRACTS v1.1 §3), stored in `plan_task.skip_reason`.
enum SkipReason {
  roadBlocked('road_blocked'),
  vehicleIssue('vehicle_issue'),
  waterEmpty('water_empty'),
  unsafe('unsafe'),
  accessDenied('access_denied'),
  other('other'),
  unknown('unknown');

  const SkipReason(this.wire);

  final String wire;

  static SkipReason fromWire(String? w) =>
      values.firstWhere((r) => r.wire == w, orElse: () => unknown);

  /// The six choices on D4, in order.
  static const List<SkipReason> choices = [
    roadBlocked,
    vehicleIssue,
    waterEmpty,
    unsafe,
    accessDenied,
    other,
  ];

  /// `other` requires a note of at least 3 characters (SCREENS D4).
  bool get needsNote => this == other;
}
