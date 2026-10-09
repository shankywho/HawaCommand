import 'package:flutter_test/flutter_test.dart';
import 'package:hawa_app/features/auth/presentation/language_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('A2 shows the title in both scripts and both options', (tester) async {
    await tester.pumpApp(const LanguageScreen());
    expect(find.text('Choose your language'), findsOneWidget);
    expect(find.text('अपनी भाषा चुनें'), findsOneWidget);
    expect(find.text('हिन्दी'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });
}
