import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/widgets/big_action_button.dart';
import 'package:hawa_app/features/citizen_reports/application/reports_controllers.dart';
import 'package:hawa_app/features/shell/domain/app_permission.dart';
import 'package:hawa_app/features/shell/presentation/permission_education_screen.dart';
import 'package:hawa_app/features/shell/presentation/widgets/shell_app_bar.dart';

/// C4 Report capture (`/citizen/report/new`): camera only (no gallery), GPS in parallel, then C5.
/// A photo lost to an activity kill is recovered via `retrieveLostData()`.
class ReportCaptureScreen extends ConsumerStatefulWidget {
  const ReportCaptureScreen({super.key});

  @override
  ConsumerState<ReportCaptureScreen> createState() => _ReportCaptureScreenState();
}

class _ReportCaptureScreenState extends ConsumerState<ReportCaptureScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (!ref.read(reportPrivacyAcceptedProvider)) {
        await context.push(Routes.reportPrivacy);
        return;
      }
      // Recover a photo if Android killed us during capture.
      final id = await ref.read(reportCaptureProvider.notifier).capture(recover: true);
      if (id != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.captureRecovered)));
        await context.push(Routes.reportReviewOf(id));
      }
    });
  }

  Future<void> _take() async {
    final l = context.l10n;
    if (!ref.read(reportPrivacyAcceptedProvider)) {
      await context.push(Routes.reportPrivacy);
      return;
    }
    if (!await ensurePermission(context, ref, AppPermission.camera)) return;
    if (!mounted) return;
    await ensurePermission(context, ref, AppPermission.location);
    final id = await ref.read(reportCaptureProvider.notifier).capture();
    if (!mounted || id == null) return;
    final s = ref.read(reportCaptureProvider);
    if (s.noFix) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.captureNoFix)));
    }
    await context.push(Routes.reportReviewOf(id));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.hawaColors;
    final s = ref.watch(reportCaptureProvider);
    return Scaffold(
      appBar: ShellAppBar(
        title: l.captureTitle,
        extraActions: [
          IconButton(
            tooltip: l.privacyTitle,
            icon: const Icon(Icons.info_outline),
            onPressed: () => context.push(Routes.reportPrivacy),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_fire_department_outlined, size: 96, color: c.dangerText),
              const SizedBox(height: 16),
              Text(
                l.captureHint,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (s.step == CaptureStep.locating || s.step == CaptureStep.saving) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 8),
                Text(l.captureLocating),
              ] else
                BigActionButton(
                  icon: Icons.photo_camera,
                  label: l.captureTake,
                  busy: s.step == CaptureStep.capturing,
                  onPressed: s.step == CaptureStep.idle ? _take : null,
                ),
              if (s.roughM != null) ...[
                const SizedBox(height: 12),
                Text(l.captureRough('${s.roughM!.round()}'), textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
