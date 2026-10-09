import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/features/alerts/domain/alert_kind.dart';

part 'app_alert.freezed.dart';

/// One inbox alert (X1/X2). Times are UTC; the UI formats them in IST.
@freezed
abstract class AppAlert with _$AppAlert {
  const factory AppAlert({
    required String id,
    required AlertKind kind,

    /// `AlertAudience` wire value (`school`, `citizen`, …); empty when unknown (e.g. a push row).
    required String audience,
    required String title,
    required String body,

    /// Language of `title`/`body` as sent by the server (`en` | `hi`).
    required String lang,
    required DateTime createdAt,

    /// When the device received it (inbox order).
    required DateTime receivedAt,

    /// Backend entity form `hawa://…` (the app resolves the route, ARCHITECTURE §5.3).
    String? deepLink,
    Pollutant? pollutant,
    String? entityId,
    DateTime? readAt,
    DateTime? ackedAt,
    DateTime? expiresAt,
    @Default(false) bool isSimulated,
  }) = _AppAlert;

  const AppAlert._();

  bool get isRead => readAt != null;

  bool get isAcked => ackedAt != null;

  /// `expires_at` has passed: the inbox greys the row and shows "Expired".
  bool isExpiredAt(DateTime now) => expiresAt != null && !now.isBefore(expiresAt!);

  /// Acknowledge is offered for school alerts, and for GRAP outlooks to site managers
  /// (SCREENS X2).
  bool canAcknowledge(String? activeRole) =>
      audience == 'school' ||
      (kind == AlertKind.grapOutlook &&
          (audience == 'site_manager' || activeRole == 'site_manager'));
}
