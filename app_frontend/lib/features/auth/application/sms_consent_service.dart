/// SMS User Consent (Android) autofill for the OTP (SCREENS A4).
///
/// Not wired yet: no SMS-consent plugin is in STRUCTURE §10.2, and the docs ask for either a
/// vetted plugin or a ~40-line platform channel. Until then the OTP screen offers paste and the
/// keyboard's one-time-code suggestion (`AutofillHints.oneTimeCode`). This needs neither
/// READ_SMS nor RECEIVE_SMS.
class SmsConsentService {
  const SmsConsentService();

  /// Returns the code from the consent prompt, or null when unavailable.
  Future<String?> listenForCode() async => null;
}
