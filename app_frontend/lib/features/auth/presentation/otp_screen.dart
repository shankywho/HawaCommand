import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/router/guards.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/utils/clock.dart';
import 'package:hawa_app/core/widgets/big_action_button.dart';
import 'package:hawa_app/features/auth/application/otp_controller.dart';
import 'package:hawa_app/features/auth/application/session_controller.dart';
import 'package:hawa_app/features/auth/domain/session_state.dart';
import 'package:hawa_app/features/auth/presentation/widgets/otp_boxes.dart';

/// A4: 6-digit code, resend timer, auto-submit on the 6th digit. In fake mode `123456` logs in.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({this.from, super.key});

  final String? from;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _boxes = GlobalKey<OtpBoxesState>();
  Timer? _ticker;
  String _code = '';

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _verify(String code) async {
    _code = code;
    final ok = await ref.read(otpControllerProvider.notifier).verify(code);
    if (!mounted) return;
    if (!ok) {
      _boxes.currentState?.clear();
      return;
    }
    final session = ref.read(sessionControllerProvider);
    if (session is SessionSignedIn && session.activeRole != null) {
      context.go(afterLogin(widget.from, session.activeRole!));
    }
    // Otherwise the guard sends the user to the role picker / unsupported screen.
  }

  /// "+91 98•••••210": only the user's own number, masked.
  static String _mask(String e164) {
    final d = e164.replaceFirst('+91', '');
    if (d.length != 10) return e164;
    return '+91 ${d.substring(0, 2)}•••••${d.substring(7)}';
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.hawaColors;
    final text = Theme.of(context).textTheme;
    final flow = ref.watch(otpControllerProvider);
    final request = flow.request;
    final now = ref.watch(appClockProvider).now();
    final wait = flow.resendAt == null ? 0 : flow.resendAt!.difference(now).inSeconds;
    final error = switch (flow.error) {
      OtpError.wrongCode => l.otpWrong('${flow.attemptsLeft ?? '?'}'),
      OtpError.expired => l.otpExpired,
      OtpError.tooMany => l.otpTooMany,
      OtpError.offline => l.phoneOffline,
      OtpError.rateLimited => l.phoneRateLimited(
        ((flow.retryAfter?.inSeconds ?? 60) / 60).ceil().toString(),
      ),
      OtpError.other => l.failureUnknown,
      _ => null,
    };
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l.otpChangeNumber,
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(otpControllerProvider.notifier).reset();
            context.pop();
          },
        ),
        title: Text(l.otpChangeNumber),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              l.otpTitle(request == null ? '' : _mask(request.phoneE164)),
              style: text.headlineSmall,
            ),
            const SizedBox(height: 24),
            OtpBoxes(
              key: _boxes,
              onCompleted: _verify,
              enabled: !flow.verifying,
              hasError: error != null,
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error, style: text.bodyMedium?.copyWith(color: c.dangerText)),
            ],
            const SizedBox(height: 16),
            if (wait > 0)
              Text(l.otpResendIn('$wait'), style: text.bodyMedium)
            else
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: flow.sending
                      ? null
                      : () => ref.read(otpControllerProvider.notifier).resend(),
                  icon: const Icon(Icons.refresh),
                  label: Text(l.otpResend),
                ),
              ),
            const SizedBox(height: 24),
            BigActionButton(
              icon: Icons.verified_user,
              label: l.otpVerify,
              field: false,
              busy: flow.verifying,
              onPressed: _code.length == 6 ? () => _verify(_code) : null,
            ),
          ],
        ),
      ),
    );
  }
}
