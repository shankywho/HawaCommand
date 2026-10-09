import 'package:flutter_test/flutter_test.dart';
import 'package:hawa_app/app/router/guards.dart';
import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/features/auth/domain/app_user.dart';
import 'package:hawa_app/features/auth/domain/session_state.dart';
import 'package:hawa_app/features/auth/domain/user_role.dart';

AppUser _user(List<String> roles) => AppUser(id: 'u1', displayName: 'U', roles: roles, lang: 'hi');

void main() {
  const uri = Uri.parse;

  group('authRedirect', () {
    test('booting always shows the splash', () {
      expect(authRedirect(const SessionBooting(), uri('/driver')), Routes.splash);
      expect(authRedirect(const SessionBooting(), uri(Routes.splash)), isNull);
    });

    test('language comes before login', () {
      const s = SessionSignedOut(languageChosen: false);
      expect(authRedirect(s, uri(Routes.phone)), Routes.language);
      expect(authRedirect(s, uri(Routes.language)), isNull);
    });

    test('signed out goes to phone with from=', () {
      const s = SessionSignedOut(languageChosen: true);
      expect(authRedirect(s, uri(Routes.phone)), isNull);
      expect(authRedirect(s, uri(Routes.otp)), isNull);
      expect(authRedirect(s, uri('/driver/stops/abc')), '/auth/phone?from=%2Fdriver%2Fstops%2Fabc');
      expect(authRedirect(s, uri(Routes.splash)), Routes.phone);
      // Picking a language on A2 moves on to the phone screen.
      expect(authRedirect(s, uri(Routes.language)), Routes.phone);
    });

    test('web-only roles see the unsupported screen', () {
      final s = SessionSignedIn(languageChosen: true, user: _user(['officer']));
      expect(authRedirect(s, uri(Routes.driver)), Routes.unsupportedRole);
      expect(authRedirect(s, uri(Routes.unsupportedRole)), isNull);
    });

    test('multi-role without an active role picks first', () {
      final s = SessionSignedIn(languageChosen: true, user: _user(['driver', 'citizen']));
      expect(authRedirect(s, uri(Routes.driver)), Routes.rolePicker);
      expect(authRedirect(s, uri(Routes.rolePicker)), isNull);
    });

    test('a path of another role goes to the active home', () {
      final s = SessionSignedIn(
        languageChosen: true,
        user: _user(['driver', 'citizen']),
        activeRole: UserRole.citizen,
      );
      expect(authRedirect(s, uri(Routes.driver)), Routes.citizenMap);
      expect(authRedirect(s, uri(Routes.myReports)), isNull);
      expect(authRedirect(s, uri(Routes.alerts)), isNull);
      expect(authRedirect(s, uri(Routes.phone)), Routes.citizenMap);
    });
  });

  test('afterLogin honours from only when the role may open it', () {
    expect(afterLogin('/driver/stops/x', UserRole.driver), '/driver/stops/x');
    expect(afterLogin('/school', UserRole.driver), Routes.driver);
    expect(afterLogin(null, UserRole.inspector), Routes.inspector);
  });
}
