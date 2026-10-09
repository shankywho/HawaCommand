import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawacommand_app/app/theme.dart';
import 'package:hawacommand_app/core/api_client.dart';
import 'package:hawacommand_app/core/i18n.dart';
import 'package:hawacommand_app/core/prefs.dart';
import 'package:hawacommand_app/features/auth/role_widgets.dart';
import 'package:hawacommand_app/features/auth/session.dart';
import 'package:hawacommand_app/widgets/common.dart';
import 'package:hawacommand_app/widgets/form_fields.dart';
import 'package:hawacommand_app/widgets/lang_switch.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Sign-in screen with demo login / demo sign-up.
///
/// The backend has no auth endpoints yet, so "Demo login" signs in with a
/// ready-made account (or a demo account created on this phone).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  /// A demo account created on this phone with the typed number, if any.
  Session? _storedAccountFor(String digits) {
    if (digits.length < 10) return null;
    final raw = ref.read(sharedPrefsProvider).getStringList(PrefKeys.accounts) ?? [];
    for (final entry in raw.reversed) {
      final account = Session.fromJson(
        jsonDecode(entry) as Map<String, dynamic>,
      );
      if (account.phone.replaceAll(RegExp(r'\D'), '').endsWith(digits)) {
        return account;
      }
    }
    return null;
  }

  Future<void> _demoLogin() async {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    final stored = _storedAccountFor(digits);
    final Session session;
    if (stored != null) {
      session = stored;
    } else {
      final role = await RolePickerSheet.show(context);
      if (role == null) return;
      session = Session.demoFor(role);
    }
    setState(() => _busy = true);
    await HapticFeedback.mediumImpact();
    await ref.read(sessionProvider.notifier).signIn(session);
    if (mounted) context.go(session.role.homePath);
  }

  @override
  Widget build(BuildContext context) {
    final health = ref.watch(healthProvider);
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    final tr = context.tr;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: hawaSystemUi,
      child: Scaffold(
        backgroundColor: HawaColors.paper,
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottom),
            children: [
              const Row(
                children: [
                  HawaMark(size: 56),
                  Spacer(),
                  LanguageButton(),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'HawaCommand',
                style: HawaText.sans(
                  34,
                  weight: FontWeight.w700,
                  height: 1.1,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 6),
              if (tr.showHi)
                Text(
                  'दिल्ली की हवा, गली-गली',
                  style: HawaText.deva(17, weight: FontWeight.w600),
                ),
              if (tr.showEn)
                Text(
                  "Field & community app for Delhi's air",
                  style: tr.isEn
                      ? HawaText.sans(17, weight: FontWeight.w600)
                      : HawaText.sans(14, color: HawaColors.muted),
                ),
              const SizedBox(height: 32),
              Text(
                tr.primary('लॉगिन करें', 'Sign in'),
                style: tr.style(24, weight: FontWeight.w700, height: 1.2),
              ),
              if (tr.isBoth)
                Text(
                  'Sign in',
                  style: HawaText.sans(14, color: HawaColors.muted),
                ),
              const SizedBox(height: 14),
              PhoneField(controller: _phone),
              const SizedBox(height: 8),
              Text(
                tr(
                  'डेमो लॉगिन: बनाए गए डेमो खाते का नंबर लिखें, या खाली छोड़कर '
                      'भूमिका चुनें।',
                  'Demo login: enter the number of a demo account you created, '
                      'or leave it empty and pick a role.',
                  both:
                      'Demo login: enter the number of a demo account you '
                      'created, or leave it empty and pick a role.',
                ),
                style: tr.style(12.5, color: HawaColors.muted),
              ),
              const SizedBox(height: 18),
              BigActionButton(
                icon: LucideIcons.logIn,
                labelHi: 'डेमो लॉगिन',
                labelEn: 'Demo login',
                busy: _busy,
                onTap: _demoLogin,
              ),
              const SizedBox(height: 12),
              BigActionButton(
                icon: LucideIcons.userPlus,
                labelHi: 'डेमो साइन अप',
                labelEn: 'Demo sign up',
                background: HawaColors.white,
                foreground: HawaColors.ink,
                englishOpacity: 0.7,
                shadow: false,
                onTap: () => context.push('/signup'),
              ),
              const SizedBox(height: 22),
              const _DemoNotice(),
              const SizedBox(height: 14),
              _BackendLine(health: health),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    const en =
        'The HawaCommand backend has no login API yet. Demo accounts are kept '
        'on this phone only; route, alert and hotspot data come from the '
        'backend when it is reachable.';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HawaColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HawaColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.info, size: 18, color: HawaColors.muted2),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tr(
                'HawaCommand बैकएंड में अभी लॉगिन API नहीं है। डेमो खाते केवल इसी '
                'फ़ोन पर रहते हैं; रूट, चेतावनी और हॉटस्पॉट का डेटा बैकएंड से '
                'आता है, जब वह उपलब्ध हो।',
                en,
                both: en,
              ),
              style: tr.style(12.5, height: 1.45, color: HawaColors.muted2),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackendLine extends StatelessWidget {
  const _BackendLine({required this.health});

  final AsyncValue<HealthStatus> health;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final status = health.value;
    final ok = status?.ok ?? false;
    final text = switch (health) {
      AsyncLoading() => tr('बैकएंड जाँच रहे हैं…', 'Checking backend…'),
      _ => status?.detail ?? 'Backend status unknown',
    };
    final demoSuffix = tr(
      'डेमो डेटा',
      'using demo data',
      both: 'using demo data',
    );
    return Pressable(
      onTap: () => context.push('/settings'),
      child: Row(
        children: [
          Icon(
            ok ? LucideIcons.wifi : LucideIcons.wifiOff,
            size: 14,
            color: ok ? HawaColors.teal : HawaColors.muted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              ok ? text : '$text · $demoSuffix',
              style: HawaText.mono(
                11.5,
                color: ok ? HawaColors.teal : HawaColors.muted,
              ),
            ),
          ),
          const Icon(LucideIcons.settings, size: 14, color: HawaColors.muted),
        ],
      ),
    );
  }
}
