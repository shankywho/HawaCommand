import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/core/notifications/push_router.dart';
import 'package:hawa_app/core/utils/ids.dart';

/// `hawa://{entity}/{id}` → app route for the role that may open it (ARCHITECTURE §5.3).
/// Allow-listed patterns only; ids must be UUIDv7 or a CONTRACTS id; anything else is dropped.
DeepLinkTarget? resolveDeepLink(
  String deepLink, {
  required String? activeRole,
  required List<String> roles,
}) {
  final uri = Uri.tryParse(deepLink);
  if (uri == null || uri.scheme != 'hawa') return null;
  final entity = uri.host;
  final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  final date = uri.queryParameters['date'];
  final validDate = date != null && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date);

  // Prefer the active role when it can open the link; otherwise the first held role that can.
  String? pick(List<String> allowed) {
    if (activeRole != null && allowed.contains(activeRole)) return activeRole;
    for (final r in allowed) {
      if (roles.contains(r)) return r;
    }
    return null;
  }

  switch (entity) {
    case 'route':
      final role = pick(const ['driver', 'inspector']);
      if (role == null) return null;
      return DeepLinkTarget(route: role == 'driver' ? Routes.driver : Routes.inspector, role: role);
    case 'tasks':
      if (segs.length != 1 || !isUuidV7(segs.first)) return null;
      final role = pick(const ['driver', 'inspector']);
      if (role == null) return null;
      return DeepLinkTarget(
        route: role == 'driver' ? Routes.stop(segs.first) : Routes.target(segs.first),
        role: role,
      );
    case 'inspections':
      if (segs.length != 1 || !isUuidV7(segs.first)) return null;
      final role = pick(const ['inspector']);
      return role == null ? null : DeepLinkTarget(route: Routes.target(segs.first), role: role);
    case 'schools':
      if (segs.length != 2 || !isSchoolId(segs.first)) return null;
      final role = pick(const ['school']);
      if (role == null) return null;
      if (segs[1] == 'safe-window') {
        return DeepLinkTarget(route: validDate ? Routes.schoolOn(date) : Routes.school, role: role);
      }
      if (segs[1] == 'air') return DeepLinkTarget(route: Routes.schoolAir, role: role);
      return null;
    case 'reports':
      if (segs.length != 1 || !isUuidV7(segs.first)) return null;
      final role = pick(const ['citizen']);
      return role == null ? null : DeepLinkTarget(route: Routes.report(segs.first), role: role);
    case 'alerts':
      if (segs.length != 1 || !isUuidV7(segs.first)) return null;
      final role = activeRole ?? (roles.isEmpty ? null : roles.first);
      return role == null ? null : DeepLinkTarget(route: Routes.alert(segs.first), role: role);
    case 'sites':
      if (segs.length != 1 || segs.first != 'me') return null;
      final role = pick(const ['site_manager']);
      return role == null ? null : DeepLinkTarget(route: Routes.site, role: role);
    default:
      return null;
  }
}
