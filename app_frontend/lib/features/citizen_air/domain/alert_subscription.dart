import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hawa_app/core/utils/geo.dart';
import 'package:hawa_app/core/utils/localized_text.dart';

part 'alert_subscription.freezed.dart';

/// Alerts for my area (proposed `GET/PUT /v1/me/alert-subscription`, SCREENS C2). The home is
/// rounded to 0.005° before it leaves the phone; the server stores only resolved cell ids.
@freezed
abstract class AlertSubscriptionPrefs with _$AlertSubscriptionPrefs {
  const factory AlertSubscriptionPrefs({
    GeoPoint? home,
    LocalizedText? placeName,
    @Default(1000) int radiusM,
    @Default(true) bool warnings,
    @Default(true) bool grapOutlook,
    @Default('22:00') String quietStart,
    @Default('06:00') String quietEnd,
  }) = _AlertSubscriptionPrefs;

  const AlertSubscriptionPrefs._();

  static const kindWarning = 'pollutant_warning';
  static const kindGrap = 'grap_outlook';

  /// "Alerts for my area: On" when an area is set and at least one kind is on.
  bool get isOn => home != null && (warnings || grapOutlook);

  List<String> get kinds => [if (warnings) kindWarning, if (grapOutlook) kindGrap];
}

/// A coarse area for the subscription: the rounded home and its place name if known.
class SubscriptionArea {
  const SubscriptionArea({required this.home, this.placeName});

  final GeoPoint home;
  final LocalizedText? placeName;
}
