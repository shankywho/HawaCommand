import 'package:hawa_app/features/auth/domain/app_user.dart';
import 'package:hawa_app/features/auth/domain/user_role.dart';

/// Session for the router guard (ARCHITECTURE §5.2): booting / signed out / signed in.
sealed class SessionState {
  const SessionState({required this.languageChosen});

  final bool languageChosen;
}

final class SessionBooting extends SessionState {
  const SessionBooting() : super(languageChosen: true);
}

final class SessionSignedOut extends SessionState {
  const SessionSignedOut({required super.languageChosen, this.expired = false});

  /// The refresh token was rejected: data and outbox are kept for the same user.
  final bool expired;
}

final class SessionSignedIn extends SessionState {
  const SessionSignedIn({required super.languageChosen, required this.user, this.activeRole});

  final AppUser user;

  /// Null until chosen when the user holds several app roles.
  final UserRole? activeRole;

  List<UserRole> get roles => [for (final r in user.roles) UserRole.fromWire(r)];

  List<UserRole> get appRoles => [
    for (final r in UserRole.appOrder)
      if (roles.contains(r)) r,
  ];

  SessionSignedIn copyWith({
    AppUser? user,
    UserRole? activeRole,
    bool clearRole = false,
    bool? languageChosen,
  }) => SessionSignedIn(
    languageChosen: languageChosen ?? this.languageChosen,
    user: user ?? this.user,
    activeRole: clearRole ? null : (activeRole ?? this.activeRole),
  );
}
