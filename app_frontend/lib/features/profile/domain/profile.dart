import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';

/// X5 Profile: the signed-in user only. The phone is held **masked**; the full number never
/// reaches the UI, and there is no way to look up another user.
@freezed
abstract class Profile with _$Profile {
  const factory Profile({
    required String name,

    /// App version ("0.1.0+3").
    required String appVersion,

    /// Per-install id for support (not the user id).
    required String installId,

    /// "+91 98•••••210", or null when the cached user has no phone.
    String? maskedPhone,

    /// `UserRole` wire values, in the order the server sent them.
    @Default(<String>[]) List<String> roles,

    /// Ward names (ids when names are missing).
    @Default(<String>[]) List<String> wards,
    @Default(false) bool isSimulated,
  }) = _Profile;
}

/// Masks an E.164 phone for display (SCREENS X5): country code, the first two and the last three
/// digits of the national number stay; the rest become bullets. `+919810044210` →
/// `+91 98•••••210`.
abstract final class PhoneMask {
  static const bullet = '•';

  static String? mask(String? e164) {
    if (e164 == null) return null;
    final digits = e164.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    final String cc;
    final String national;
    if (e164.trim().startsWith('+91') && digits.length == 12) {
      cc = '+91';
      national = digits.substring(2);
    } else if (e164.trim().startsWith('+') && digits.length > 10) {
      cc = '+${digits.substring(0, digits.length - 10)}';
      national = digits.substring(digits.length - 10);
    } else {
      cc = '';
      national = digits;
    }
    final String shown;
    if (national.length <= 5) {
      shown = bullet * national.length;
    } else {
      final head = national.substring(0, 2);
      final tail = national.substring(national.length - 3);
      shown = '$head${bullet * (national.length - 5)}$tail';
    }
    return cc.isEmpty ? shown : '$cc $shown';
  }
}
