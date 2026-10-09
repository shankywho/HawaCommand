/// Per-scope "stale after" thresholds (OFFLINE_AND_SYNC §2, §9).
abstract final class StalePolicy {
  /// Today's route: 10 min during a shift, 60 min otherwise.
  static Duration tasks({required bool shiftActive}) =>
      shiftActive ? const Duration(minutes: 10) : const Duration(minutes: 60);

  static const inspectionTargets = Duration(minutes: 10);
  static const evidenceBundle = Duration(minutes: 30);
  static const indoorOutdoor = Duration(minutes: 15);
  static const forecast = Duration(minutes: 75);
  static const alerts = Duration(minutes: 30);
  static const openAir = Duration(minutes: 30);
  static const reports = Duration(minutes: 15);
  static const site = Duration(hours: 24);

  /// Safe windows go stale once the next issuance (19:00 or 22:00 IST) has passed.
  static bool safeWindowStale({required DateTime fetchedAt, required DateTime now}) {
    final istFetched = fetchedAt.toUtc().add(const Duration(hours: 5, minutes: 30));
    final istNow = now.toUtc().add(const Duration(hours: 5, minutes: 30));
    for (final hour in const [19, 22]) {
      final issue = DateTime.utc(istFetched.year, istFetched.month, istFetched.day, hour);
      if (istFetched.isBefore(issue) && !istNow.isBefore(issue)) return true;
    }
    return istNow.difference(istFetched) > const Duration(hours: 24);
  }

  static bool isStale(DateTime? lastSuccess, Duration threshold, DateTime now) =>
      lastSuccess == null || now.difference(lastSuccess) > threshold;
}
