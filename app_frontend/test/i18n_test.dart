import 'package:flutter_test/flutter_test.dart';
import 'package:hawacommand_app/core/i18n.dart';
import 'package:hawacommand_app/features/driver/driver_data.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('hi');
  });

  test('Tr picks the text for each language', () {
    const hi = Tr(AppLang.hi);
    const en = Tr(AppLang.en);
    const both = Tr(AppLang.both);

    expect(hi('अगला स्टॉप', 'Next stop'), 'अगला स्टॉप');
    expect(en('अगला स्टॉप', 'Next stop'), 'Next stop');
    expect(both('अगला स्टॉप', 'Next stop'), 'अगला स्टॉप · Next stop');
    expect(
      both('अगला स्टॉप', 'Next', both: 'अगला स्टॉप · Next'),
      'अगला स्टॉप · Next',
    );

    // Primary lines: Hindi unless English-only; the English sub-line is
    // shown only in bilingual mode.
    expect(both.primary('रूट शुरू करें', 'Start route'), 'रूट शुरू करें');
    expect(en.primary('रूट शुरू करें', 'Start route'), 'Start route');
    expect(both.secondary('Start route'), 'Start route');
    expect(hi.secondary('Start route'), isNull);
  });

  test('unknown stored value falls back to the bilingual design', () {
    expect(AppLang.fromName(null), AppLang.both);
    expect(AppLang.fromName('xx'), AppLang.both);
    expect(AppLang.fromName('hi'), AppLang.hi);
  });

  test('route date and actions are localised', () {
    final route = demoRoute('T-12');
    final date = route.date!;
    expect(const Tr(AppLang.en).shortDate(date), 'Thu 12 Nov');
    expect(const Tr(AppLang.hi).shortDate(date), isNot('Thu 12 Nov'));
    expect(route.stops[0].actionHi, 'छिड़काव');
    expect(route.stops[1].actionHi, 'पानी भरें');
    expect(route.stops[0].actionEn, 'Spray');
  });
}
