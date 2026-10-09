import 'package:freezed_annotation/freezed_annotation.dart';

part 'localized_text.freezed.dart';
part 'localized_text.g.dart';

/// Server text in English and (optionally) Hindi. Missing Hindi falls back to English and the
/// UI adds "(अंग्रेज़ी में)"; the app never machine-translates (ARCHITECTURE §14).
@freezed
abstract class LocalizedText with _$LocalizedText {
  const factory LocalizedText({required String en, String? hi}) = _LocalizedText;

  const LocalizedText._();

  factory LocalizedText.fromJson(Map<String, Object?> json) => _$LocalizedTextFromJson(json);

  String of(String lang) => lang == 'hi' && (hi?.isNotEmpty ?? false) ? hi! : en;

  /// True when Hindi was asked for but only English exists.
  bool isEnglishFallback(String lang) => lang == 'hi' && (hi == null || hi!.isEmpty);
}
