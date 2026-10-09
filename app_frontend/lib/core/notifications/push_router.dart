import 'package:hawa_app/core/notifications/push_payload.dart';
import 'package:logging/logging.dart';

/// A resolved deep link: the app route and the role that may open it.
class DeepLinkTarget {
  const DeepLinkTarget({required this.route, required this.role});

  final String route;
  final String role;
}

/// Resolves `hawa://{entity}/{id}` for the roles the user holds (allow-list + id validation live
/// in app/router/deep_links.dart). Returns null for anything not on the list.
typedef DeepLinkResolver =
    DeepLinkTarget? Function(
      String deepLink, {
      required String? activeRole,
      required List<String> roles,
    });

/// Opens a push payload (ARCHITECTURE §5.3): parse → resolve → switch role if needed → go.
class PushRouter {
  PushRouter({
    required this.resolve,
    required this.activeRole,
    required this.roles,
    required this.switchRole,
    required this.go,
  });

  final DeepLinkResolver resolve;
  final String? Function() activeRole;
  final List<String> Function() roles;

  /// Switches the active role and shows "Switched to …".
  final Future<void> Function(String role) switchRole;
  final void Function(String route) go;
  static final _log = Logger('push-router');

  /// Returns true when the payload was routed.
  Future<bool> open(PushPayload payload) async {
    final link = payload.deepLink;
    if (link == null) return false;
    final held = roles();
    if (payload.role != null && held.isNotEmpty && !held.contains(payload.role)) {
      _log.info('push for role ${payload.role} ignored');
      return false;
    }
    final target = resolve(link, activeRole: activeRole(), roles: held);
    if (target == null) {
      _log.info('deep link not on the allow-list');
      return false;
    }
    if (activeRole() != target.role && held.contains(target.role)) {
      await switchRole(target.role);
    }
    go(target.route);
    return true;
  }
}
