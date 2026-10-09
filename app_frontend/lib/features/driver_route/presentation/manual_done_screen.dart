import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/media/photo_capture.dart';
import 'package:hawa_app/core/widgets/big_action_button.dart';
import 'package:hawa_app/features/driver_route/application/stop_actions_controller.dart';
import 'package:hawa_app/features/driver_route/application/today_route_controller.dart';
import 'package:hawa_app/features/shell/domain/app_permission.dart';
import 'package:hawa_app/features/shell/presentation/permission_education_screen.dart';

/// D5 Manual done (`/driver/stops/:taskId/manual-done`), HawaTag offline only: optional litres
/// and photo, recorded as manual with lower evidence (photo upload op, then task_status done).
class ManualDoneScreen extends ConsumerStatefulWidget {
  const ManualDoneScreen({required this.taskId, super.key});

  final String taskId;

  @override
  ConsumerState<ManualDoneScreen> createState() => _ManualDoneScreenState();
}

class _ManualDoneScreenState extends ConsumerState<ManualDoneScreen> {
  final _litres = TextEditingController();
  String? _photo;
  bool _busy = false;

  @override
  void dispose() {
    _litres.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (!await ensurePermission(context, ref, AppPermission.camera)) return;
    final path = await ref.read(photoCaptureProvider).capture();
    if (path != null && mounted) setState(() => _photo = path);
  }

  Future<void> _confirm() async {
    final stop = ref.read(stopDetailProvider(widget.taskId)).value;
    if (stop == null) return;
    setState(() => _busy = true);
    await ref
        .read(stopActionsProvider.notifier)
        .manualDone(stop, litres: double.tryParse(_litres.text.trim()), photoPath: _photo);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.hawaColors;
    final text = Theme.of(context).textTheme;
    final route = ref.watch(todayRouteControllerProvider).value;
    final tagOff = route?.asset?.tagCannotConfirm ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(l.driverManualTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Icon(Icons.sensors_off, size: 48, color: c.warningText),
            const SizedBox(height: 8),
            Text(l.driverManualBody, style: text.bodyLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _litres,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l.driverManualLitres,
                suffixText: 'L',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_photo != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(_photo!), height: 180, fit: BoxFit.cover),
              ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _takePhoto,
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(l.driverManualPhoto),
            ),
            const SizedBox(height: 24),
            BigActionButton(
              icon: Icons.task_alt,
              label: _photo == null ? l.driverManualSendWithout : l.driverManualConfirm,
              busy: _busy,
              // Gated: only while the HawaTag cannot confirm (SCREENS D3/D5).
              onPressed: tagOff && !_busy ? _confirm : null,
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => context.pop(), child: Text(l.commonCancel)),
          ],
        ),
      ),
    );
  }
}
