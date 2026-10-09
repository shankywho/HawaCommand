import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawacommand_app/app/theme.dart';
import 'package:hawacommand_app/core/i18n.dart';
import 'package:hawacommand_app/widgets/common.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Compact pill (`अ/A हिंदी + English`) that opens the language sheet.
class LanguageButton extends ConsumerWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final short = switch (lang) {
      AppLang.both => 'हि + En',
      AppLang.hi => 'हिंदी',
      AppLang.en => 'English',
    };
    return Semantics(
      button: true,
      label: 'Language: ${lang.label}',
      excludeSemantics: true,
      child: Pressable(
        onTap: () => LanguageSheet.show(context),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: HawaColors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: HawaColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.languages,
                size: 16,
                color: HawaColors.ink,
              ),
              const SizedBox(width: 6),
              Text(
                short,
                style: HawaText.deva(13, weight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet with the three language options.
class LanguageSheet extends StatelessWidget {
  const LanguageSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    builder: (_) => const LanguageSheet(),
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'भाषा · Language',
              style: HawaText.deva(22, weight: FontWeight.w700, height: 1.2),
            ),
            const SizedBox(height: 14),
            LanguageOptions(onChanged: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}

/// The three options as selectable cards (used in the sheet and Settings).
class LanguageOptions extends ConsumerWidget {
  const LanguageOptions({super.key, this.onChanged});

  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(langProvider);
    return Column(
      children: [
        for (final lang in AppLang.values) ...[
          _LanguageOption(
            lang: lang,
            selected: lang == current,
            onTap: () async {
              await HapticFeedback.selectionClick();
              await ref.read(langProvider.notifier).set(lang);
              onChanged?.call();
            },
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.lang,
    required this.selected,
    required this.onTap,
  });

  final AppLang lang;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glyph = switch (lang) {
      AppLang.both => 'अA',
      AppLang.hi => 'अ',
      AppLang.en => 'A',
    };
    return Semantics(
      button: true,
      selected: selected,
      label: lang.label,
      excludeSemantics: true,
      child: HawaCard(
        onTap: onTap,
        borderColor: selected ? HawaColors.ink : HawaColors.line,
        borderWidth: selected ? 2 : 1,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? HawaColors.ink : HawaColors.line,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                glyph,
                style: HawaText.deva(
                  18,
                  weight: FontWeight.w700,
                  color: selected ? HawaColors.paper : HawaColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.label,
                    style: HawaText.deva(17, weight: FontWeight.w600),
                  ),
                  Text(
                    lang.description,
                    style: HawaText.deva(12.5, color: HawaColors.muted),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                LucideIcons.circleCheck,
                size: 20,
                color: HawaColors.teal,
              ),
          ],
        ),
      ),
    );
  }
}
