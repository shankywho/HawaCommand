import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawacommand_app/features/auth/login_screen.dart';
import 'package:hawacommand_app/features/auth/session.dart';
import 'package:hawacommand_app/features/auth/signup_screen.dart';
import 'package:hawacommand_app/features/citizen/citizen_eyes_screen.dart';
import 'package:hawacommand_app/features/driver/active_route_screen.dart';
import 'package:hawacommand_app/features/driver/route_screen.dart';
import 'package:hawacommand_app/features/hub/hub_screen.dart';
import 'package:hawacommand_app/features/school/school_alert_screen.dart';
import 'package:hawacommand_app/features/settings/settings_screen.dart';

/// Re-runs the router redirect whenever the session changes.
class _SessionListenable extends ChangeNotifier {
  _SessionListenable(Ref ref) {
    ref.listen(sessionProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _SessionListenable(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = ref.read(sessionProvider) != null;
      final path = state.matchedLocation;
      final onAuth = path == '/login' || path == '/signup';
      final onSettings = path == '/settings';
      if (!signedIn && !onAuth && !onSettings) return '/login';
      if (signedIn && onAuth) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, _) => const SignupScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(
        path: '/',
        builder: (_, _) => const HubScreen(),
        routes: [
          GoRoute(
            path: 'driver',
            builder: (_, _) => const RouteScreen(),
            routes: [
              GoRoute(
                path: 'active',
                builder: (_, _) => const ActiveRouteScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'school',
            builder: (_, _) => const SchoolAlertScreen(),
          ),
          GoRoute(
            path: 'citizen',
            builder: (_, _) => const CitizenEyesScreen(),
          ),
        ],
      ),
    ],
  );
});
