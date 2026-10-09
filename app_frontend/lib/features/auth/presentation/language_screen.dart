import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/storage/settings_store.dart';
import 'package:hawa_app/core/widgets/big_action_button.dart';

/// A2: first-run हिन्दी / English picker. The title shows in both scripts at once and each button
/// is labelled in its own script. Tapping sets the locale immediately.
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final en = lookupAppLocalizations(const Locale('en'));
    final hi = lookupAppLocalizations(const Locale('hi'));
    final c = context.hawaColors;
    final text = Theme.of(context).textTheme;
    Future<void> pick(String lang) =>
        ref.read(appPreferencesControllerProvider.notifier).setLanguage(lang);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 32),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset('assets/images/app_logo.png', width: 72, height: 72),
              ),
            ),
            const SizedBox(height: 12),
            Center(child: Text(en.appTitle, style: text.titleLarge)),
            const SizedBox(height: 40),
            Text(en.languageTitle, style: text.headlineSmall),
            const SizedBox(height: 4),
            Text(hi.languageTitle, style: text.headlineSmall?.copyWith(height: 1.5)),
            const SizedBox(height: 28),
            BigActionButton(
              icon: Icons.translate,
              label: hi.languageHindi,
              field: false,
              onPressed: () => pick('hi'),
            ),
            const SizedBox(height: 12),
            BigActionButton(
              icon: Icons.language,
              label: en.languageEnglish,
              field: false,
              variant: BigActionVariant.secondary,
              onPressed: () => pick('en'),
            ),
            const SizedBox(height: 24),
            Text(en.languageHint, style: text.bodySmall?.copyWith(color: c.mutedForeground)),
            Text(
              hi.languageHint,
              style: text.bodySmall?.copyWith(color: c.mutedForeground, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
