/// `UserRole` (CONTRACTS §3). officer/admin/analyst are web-only.
enum UserRole {
  driver('driver'),
  inspector('inspector'),
  school('school'),
  citizen('citizen'),
  siteManager('site_manager'),
  officer('officer'),
  admin('admin'),
  analyst('analyst'),
  unknown('unknown');

  const UserRole(this.wire);

  final String wire;

  static UserRole fromWire(String? w) =>
      values.firstWhere((r) => r.wire == w, orElse: () => unknown);

  bool get isWebOnly => this == officer || this == admin || this == analyst || this == unknown;

  bool get isAppRole => !isWebOnly;

  /// Field shells default to outdoor mode and 64 dp primary buttons.
  bool get isField => this == driver || this == inspector;

  /// Role picker order.
  static const List<UserRole> appOrder = [driver, inspector, school, citizen, siteManager];
}
