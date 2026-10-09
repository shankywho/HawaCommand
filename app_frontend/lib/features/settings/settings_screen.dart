import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawacommand_app/app/theme.dart';
import 'package:hawacommand_app/core/air.dart';
import 'package:hawacommand_app/core/api_client.dart';
import 'package:hawacommand_app/core/config.dart';
import 'package:hawacommand_app/core/i18n.dart';
import 'package:hawacommand_app/features/auth/role_widgets.dart';
import 'package:hawacommand_app/features/auth/session.dart';
import 'package:hawacommand_app/features/driver/driver_data.dart';
import 'package:hawacommand_app/features/school/school_data.dart';
import 'package:hawacommand_app/widgets/common.dart';
import 'package:hawacommand_app/widgets/form_fields.dart';
import 'package:hawacommand_app/widgets/lang_switch.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _url = TextEditingController(
    text: ref.read(connectionSettingsProvider).apiUrl,
  );

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  void _refreshData() {
    final asset = ref.read(sessionProvider)?.assetId ?? 'T-12';
    ref
      ..invalidate(healthProvider)
      ..invalidate(hotspotsProvider)
      ..invalidate(schoolAlertProvider)
      ..invalidate(driverRouteProvider(asset))
      ..invalidate(vehiclePositionProvider(asset));
  }

  Future<void> _saveUrl() async {
    FocusScope.of(context).unfocus();
    await ref.read(connectionSettingsProvider.notifier).setApiUrl(_url.text);
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final settings = ref.watch(connectionSettingsProvider);
    final health = ref.watch(healthProvider);
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    final tr = context.tr;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: hawaSystemUi,
      child: Scaffold(
        backgroundColor: HawaColors.paper,
        appBar: AppBar(
          backgroundColor: HawaColors.paper,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(LucideIcons.chevronLeft, size: 22),
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          ),
          title: Text(
            tr('सेटिंग्स', 'Settings'),
            style: tr.style(17, weight: FontWeight.w600),
          ),
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + bottom),
          children: [
            _SectionLabel(tr('भाषा', 'Language')),
            const LanguageOptions(),
            const SizedBox(height: 16),
            if (session != null) ...[
              _SectionLabel(tr('खाता', 'Account')),
              HawaCard(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: HawaColors.ink,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        session.name.isEmpty ? '?' : session.name[0],
                        style: HawaText.sans(
                          22,
                          weight: FontWeight.w600,
                          color: HawaColors.paper,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.name,
                            style: HawaText.sans(16, weight: FontWeight.w600),
                          ),
                          Text(
                            session.phone,
                            style: HawaText.mono(13, color: HawaColors.muted),
                          ),
                          Text(
                            [
                              tr.primary(
                                session.role.labelHi,
                                session.role.labelEn,
                              ),
                              if (session.role == AppRole.driver) session.assetId,
                              ?session.orgName,
                            ].join(' · '),
                            style: tr.style(12.5, color: HawaColors.muted2),
                          ),
                        ],
                      ),
                    ),
                    if (session.isDemo) _Tag(tr('डेमो', 'DEMO', both: 'DEMO')),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _RowButton(
                icon: LucideIcons.repeat,
                labelHi: 'भूमिका बदलें',
                labelEn: 'Switch role',
                onTap: () async {
                  final role = await RolePickerSheet.show(
                    context,
                    current: session.role,
                  );
                  if (role == null) return;
                  await ref.read(sessionProvider.notifier).switchRole(role);
                  if (context.mounted) context.go(role.homePath);
                },
              ),
            ],
            const SizedBox(height: 24),
            _SectionLabel(tr('सर्वर', 'Backend')),
            TextField(
              controller: _url,
              keyboardType: TextInputType.url,
              autocorrect: false,
              style: HawaText.mono(15),
              onSubmitted: (_) => _saveUrl(),
              decoration: hawaInputDecoration(
                label: 'API URL',
                hint: AppConfig.defaultApiUrl,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tr(
                'एमुलेटर: http://10.0.2.2:8000 · उसी Wi-Fi पर फ़ोन: '
                    'http://<laptop-ip>:8000',
                'Emulator: http://10.0.2.2:8000 · Phone on the same Wi-Fi: '
                    'http://<laptop-ip>:8000',
                both:
                    'Emulator: http://10.0.2.2:8000 · Phone on the same Wi-Fi: '
                    'http://<laptop-ip>:8000',
              ),
              style: tr.style(12, color: HawaColors.muted),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _saveUrl,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: Text(
                tr('सहेजें और जाँचें', 'Save & test', both: 'Save & test'),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: HawaColors.teal,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            HawaCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    (health.value?.ok ?? false) ? LucideIcons.wifi : LucideIcons.wifiOff,
                    size: 18,
                    color: (health.value?.ok ?? false) ? HawaColors.teal : HawaColors.muted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      health.isLoading
                          ? 'Checking ${settings.apiUrl}…'
                          : (health.value?.detail ?? 'Unknown'),
                      style: HawaText.mono(12.5, color: HawaColors.muted2),
                    ),
                  ),
                  SourcePill(live: health.value?.ok ?? false),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: HawaColors.teal,
              value: settings.demoOnly,
              onChanged: (v) async {
                await ref.read(connectionSettingsProvider.notifier).setDemoOnly(value: v);
                _refreshData();
              },
              title: Text(
                tr('केवल डेमो डेटा', 'Demo data only'),
                style: tr.style(15, weight: FontWeight.w600),
              ),
              subtitle: Text(
                tr(
                  'बैकएंड छोड़ें और डिज़ाइन वाला डेमो डेटा दिखाएँ।',
                  'Skip the backend and use the bundled design data.',
                  both: 'Skip the backend and use the bundled design data.',
                ),
                style: tr.style(12.5, color: HawaColors.muted),
              ),
            ),
            const SizedBox(height: 24),
            if (session != null)
              _RowButton(
                icon: LucideIcons.logOut,
                labelHi: 'लॉग आउट',
                labelEn: 'Log out',
                danger: true,
                onTap: () async {
                  await ref.read(sessionProvider.notifier).signOut();
                  ref.read(routeRunProvider.notifier).stop();
                  if (context.mounted) context.go('/login');
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: context.tr.style(13, color: HawaColors.muted)),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: HawaColors.line,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: HawaText.mono(10.5, weight: FontWeight.w600)),
    );
  }
}

class _RowButton extends StatelessWidget {
  const _RowButton({
    required this.icon,
    required this.labelHi,
    required this.labelEn,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String labelHi;
  final String labelEn;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final color = danger ? HawaColors.alert : HawaColors.ink;
    return HawaCard(
      onTap: onTap,
      borderColor: danger ? HawaColors.alert.withValues(alpha: 0.4) : HawaColors.line,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: tr.primary(labelHi, labelEn),
                    style: tr.style(16, weight: FontWeight.w600, color: color),
                  ),
                  if (tr.isBoth)
                    TextSpan(
                      text: '  ·  $labelEn',
                      style: HawaText.sans(14, color: HawaColors.muted),
                    ),
                ],
              ),
            ),
          ),
          Icon(LucideIcons.chevronRight, size: 18, color: color),
        ],
      ),
    );
  }
}
