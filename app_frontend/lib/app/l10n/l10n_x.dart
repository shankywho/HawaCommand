import 'package:flutter/widgets.dart';
import 'package:hawa_app/app/l10n/gen/app_localizations.dart';

export 'package:hawa_app/app/l10n/gen/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// `en` or `hi`.
  String get lang => Localizations.localeOf(this).languageCode == 'hi' ? 'hi' : 'en';

  bool get isHindi => lang == 'hi';
}
