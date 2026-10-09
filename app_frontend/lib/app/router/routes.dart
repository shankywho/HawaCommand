/// Path constants and builders. No path string literals anywhere else (ARCHITECTURE §5.1).
abstract final class Routes {
  static const splash = '/splash';
  static const language = '/onboarding/language';
  static const permissionPattern = '/onboarding/permissions/:kind';
  static const phone = '/auth/phone';
  static const otp = '/auth/otp';
  static const rolePicker = '/auth/role';
  static const unsupportedRole = '/unsupported-role';

  // Driver (Route · Map · More).
  static const driver = '/driver';
  static const driverMap = '/driver/map';
  static const shiftSummary = '/driver/shift/summary';
  static String stop(String taskId) => '/driver/stops/$taskId';
  static String stopSkip(String taskId) => '/driver/stops/$taskId/skip';
  static String stopManualDone(String taskId) => '/driver/stops/$taskId/manual-done';

  // Inspector (Targets · Map · More).
  static const inspector = '/inspector';
  static const inspectorMap = '/inspector/map';
  static String target(String targetId) => '/inspector/targets/$targetId';
  static String targetOutcome(String targetId) => '/inspector/targets/$targetId/outcome';
  static String targetPhoto(String targetId, int index) =>
      '/inspector/targets/$targetId/photos/$index';

  // School (Today · Air · Alerts · More).
  static const school = '/school';
  static const schoolAir = '/school/air';
  static const schoolForecast = '/school/forecast';
  static String schoolOn(String date) => '/school?date=$date';

  // Citizen (Air · Report · My reports · More).
  static const citizen = '/citizen';

  /// Citizen home: the AI air map with clean-air routing (first tab).
  static const citizenMap = '/citizen/map';
  static const citizenSubscription = '/citizen/subscription';
  static const citizenRouteTip = '/citizen/route-tip';
  static const citizenSafeRoute = '/citizen/safe-route';
  static const citizenLiveOps = '/citizen/live-ops';
  static const citizenWardScore = '/citizen/ward-score';
  static const reportPrivacy = '/citizen/report/privacy';
  static const reportCapture = '/citizen/report/new';
  static const reportMissedMachine = '/citizen/report/missed-machine';
  static const reportReview = '/citizen/report/review';
  static String reportReviewOf(String clientReportId) =>
      '/citizen/report/review?draft=$clientReportId';
  static const myReports = '/citizen/reports';
  static String report(String reportId) => '/citizen/reports/$reportId';

  // Site manager.
  static const site = '/site';

  // Shared, pushed on top of the shells.
  static const alerts = '/alerts';
  static String alert(String alertId) => '/alerts/$alertId';
  static const settings = '/settings';
  static const syncQueue = '/settings/sync';
  static const notificationSettings = '/settings/notifications';
  static const devTools = '/settings/dev';
  static const profile = '/profile';

  /// The air map for any role (pushed from More) and its place search.
  static const map = '/map';
  static const mapSearch = '/map/search';
  static String mapSearchFor({required bool origin}) =>
      '$mapSearch?field=${origin ? 'from' : 'to'}';

  static String permission(String kind) => '/onboarding/permissions/$kind';

  /// Reachable while signed out.
  static const Set<String> publicAuth = {phone, otp};

  /// Role home by `UserRole` wire value.
  static String homeFor(String role) => switch (role) {
    'driver' => driver,
    'inspector' => inspector,
    'school' => school,
    'citizen' => citizenMap,
    'site_manager' => site,
    _ => unsupportedRole,
  };

  /// The role a path belongs to (derived from the route table), or null for shared paths.
  static String? requiredRoleFor(String path) {
    if (path == driver || path.startsWith('$driver/')) return 'driver';
    if (path == inspector || path.startsWith('$inspector/')) return 'inspector';
    if (path == school || path.startsWith('$school/')) return 'school';
    if (path == citizen || path.startsWith('$citizen/')) return 'citizen';
    if (path == site || path.startsWith('$site/')) return 'site_manager';
    return null;
  }
}
