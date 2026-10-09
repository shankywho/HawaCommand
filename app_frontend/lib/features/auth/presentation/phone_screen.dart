import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/env.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/network/connectivity_service.dart';
import 'package:hawa_app/core/widgets/big_action_button.dart';
import 'package:hawa_app/features/auth/application/otp_controller.dart';
import 'package:hawa_app/features/auth/application/session_controller.dart';
import 'package:hawa_app/features/auth/domain/session_state.dart';
import 'package:hawa_app/features/auth/presentation/widgets/phone_field.dart';

/// A3: +91 number entry; OTP is online-only (SCREENS A3).
class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({this.from, super.key});

  /// Where to go after login (deep link that sent the user here).
  final String? from;

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _phone = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final ok = await ref.read(otpControllerProvider.notifier).sendCode(_phone.text);
    if (ok && mounted) {
      await context.push(Uri(path: Routes.otp, queryParameters: {'from': ?widget.from}).toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.hawaColors;
    final text = Theme.of(context).textTheme;
    final flow = ref.watch(otpControllerProvider);
    final offline = ref.watch(networkStatusProvider).value?.isOffline ?? false;
    final session = ref.watch(sessionControllerProvider);
    final expired = session is SessionSignedOut && session.expired;
    final error = switch (flow.error) {
      OtpError.invalidPhone => l.phoneInvalid,
      OtpError.rateLimited => l.phoneRateLimited(
        ((flow.retryAfter?.inSeconds ?? 60) / 60).ceil().toString(),
      ),
      OtpError.offline => l.phoneOffline,
      OtpError.other => l.failureUnknown,
      _ => null,
    };
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (expired)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  l.sessionExpired,
                  style: text.titleMedium?.copyWith(color: c.warningText),
                ),
              ),
            Text(l.phoneTitle, style: text.headlineSmall),
            const SizedBox(height: 20),
            PhoneField(
              controller: _phone,
              onSubmitted: (_) => _send(),
              errorText: offline ? null : error,
            ),
            const SizedBox(height: 8),
            Text(l.phoneHelper, style: text.bodyMedium),
            const SizedBox(height: 24),
            BigActionButton(
              icon: Icons.sms,
              label: l.phoneSend,
              field: false,
              busy: flow.sending,
              onPressed: offline ? null : _send,
            ),
            if (offline) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.wifi_off, color: c.mutedForeground),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l.phoneOffline)),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 20, color: c.mutedForeground),
                const SizedBox(width: 8),
                Expanded(child: Text(l.phonePrivacy, style: text.bodySmall)),
              ],
            ),
            if (Env.isFake('auth')) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.simulated.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.simulated),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.science, color: c.simulatedText, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l.phoneDemoTitle,
                            style: text.labelLarge?.copyWith(color: c.simulatedText),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(l.phoneDemoBody, style: text.bodySmall),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
