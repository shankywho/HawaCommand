import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawacommand_app/app/theme.dart';
import 'package:hawacommand_app/core/prefs.dart';
import 'package:intl/intl.dart';

/// Display language. [both] is the design's Hindi-first bilingual layout.
enum AppLang {
  both('हिंदी + English', 'Hindi and English, as in the design'),
  hi('हिंदी', 'केवल हिंदी'),
  en('English', 'English only');

  const AppLang(this.label, this.description);

  final String label;
  final String description;

  static AppLang fromName(String? name) => AppLang.values.firstWhere(
    (l) => l.name == name,
    orElse: () => AppLang.both,
  );

  /// Locale for Material widgets and date formatting.
  Locale get locale => this == AppLang.en ? const Locale('en') : const Locale('hi');
}

class LangController extends Notifier<AppLang> {
  @override
  AppLang build() => AppLang.fromName(
    ref.watch(sharedPrefsProvider).getString(PrefKeys.lang),
  );

  Future<void> set(AppLang lang) async {
    await ref.read(sharedPrefsProvider).setString(PrefKeys.lang, lang.name);
    state = lang;
  }
}

final langProvider = NotifierProvider<LangController, AppLang>(
  LangController.new,
);

/// Picks text for the current [AppLang].
///
/// `tr('आज का रूट', "Today's route")` returns the Hindi string in Hindi mode,
/// the English string in English mode, and `both` (default `hi · en`) in
/// bilingual mode.
@immutable
class Tr {
  const Tr(this.lang);

  final AppLang lang;

  bool get isEn => lang == AppLang.en;
  bool get isHi => lang == AppLang.hi;
  bool get isBoth => lang == AppLang.both;

  /// Hindi text is shown (Hindi-only or bilingual).
  bool get showHi => lang != AppLang.en;

  /// English text is shown (English-only or bilingual).
  bool get showEn => lang != AppLang.hi;

  String call(String hi, String en, {String? both}) => switch (lang) {
    AppLang.hi => hi,
    AppLang.en => en,
    AppLang.both => both ?? '$hi · $en',
  };

  /// Like [call] but the bilingual form is just the Hindi text, for primary
  /// lines that already have an English sub-line in bilingual mode.
  String primary(String hi, String en) => isEn ? en : hi;

  /// The secondary English line shown under Hindi in bilingual mode only.
  String? secondary(String en) => isBoth ? en : null;

  /// Hindi-first text uses Noto Sans Devanagari; English-only text uses Geist.
  TextStyle style(
    double size, {
    FontWeight weight = FontWeight.w400,
    double? height,
    Color color = HawaColors.ink,
    double letterSpacing = 0,
  }) => isEn
      ? HawaText.sans(
          size,
          weight: weight,
          height: height,
          color: color,
          letterSpacing: letterSpacing,
        )
      : HawaText.deva(
          size,
          weight: weight,
          height: height,
          color: color,
          letterSpacing: letterSpacing,
        );

  /// Date like `Thu 12 Nov` (English) or `गुरु 12 नव॰` (Hindi).
  String shortDate(DateTime date) =>
      DateFormat('EEE d MMM', isEn || isBoth ? 'en' : 'hi').format(date);
}

/// Makes [Tr] available to every widget below `MaterialApp`.
class LangScope extends InheritedWidget {
  const LangScope({required this.tr, required super.child, super.key});

  final Tr tr;

  static Tr of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LangScope>()?.tr ?? const Tr(AppLang.both);

  @override
  bool updateShouldNotify(LangScope oldWidget) => oldWidget.tr.lang != tr.lang;
}

extension TrContext on BuildContext {
  Tr get tr => LangScope.of(this);
}
