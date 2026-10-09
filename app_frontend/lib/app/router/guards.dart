import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/features/auth/domain/session_state.dart';
import 'package:hawa_app/features/auth/domain/user_role.dart';

/// Redirect guard: a pure function of the session and the requested URI (ARCHITECTURE §5.2),
/// unit tested as a matrix.
String? authRedirect(SessionState s, Uri uri) {
  final path = uri.path;
  if (s is SessionBooting) return path == Routes.splash ? null : Routes.splash;
  if (!s.languageChosen) return path == Routes.language ? null : Routes.language;

  if (s is SessionSignedOut) {
    // The language is chosen (checked above), so A2 moves on to the phone screen.
    if (path == Routes.language) return Routes.phone;
    if (Routes.publicAuth.contains(path)) return null;
    final from = path == Routes.splash || path == '/' ? null : uri.toString();
    return Uri(
      path: Routes.phone,
      queryParameters: from == null ? null : {'from': from},
    ).toString();
  }

  final signedIn = s as SessionSignedIn;
  if (signedIn.roles.every((r) => r.isWebOnly)) {
    return path == Routes.unsupportedRole ? null : Routes.unsupportedRole;
  }
  final active = signedIn.activeRole;
  if (active == null) return path == Routes.rolePicker ? null : Routes.rolePicker;
  if (Routes.publicAuth.contains(path) ||
      path == Routes.splash ||
      path == Routes.language ||
      path == Routes.unsupportedRole ||
      path == '/') {
    return Routes.homeFor(active.wire);
  }

  final required = Routes.requiredRoleFor(path);
  if (required != null && required != active.wire) return Routes.homeFor(active.wire);
  return null;
}

/// After login: go to `from` if the active role may open it, otherwise the role home.
String afterLogin(String? from, UserRole role) {
  if (from == null || from.isEmpty) return Routes.homeFor(role.wire);
  final path = Uri.parse(from).path;
  final required = Routes.requiredRoleFor(path);
  if (required != null && required != role.wire) return Routes.homeFor(role.wire);
  if (Routes.publicAuth.contains(path) || path == Routes.splash) return Routes.homeFor(role.wire);
  return from;
}
