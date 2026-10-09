import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/core/widgets/big_action_button.dart';
import 'package:hawa_app/features/driver_route/application/stop_actions_controller.dart';
import 'package:hawa_app/features/driver_route/domain/skip_reason.dart';

extension SkipReasonLabel on SkipReason {
  String label(AppLocalizations l) => switch (this) {
    SkipReason.roadBlocked => l.skipRoadBlocked,
    SkipReason.vehicleIssue => l.skipVehicleIssue,
    SkipReason.waterEmpty => l.skipWaterEmpty,
    SkipReason.unsafe => l.skipUnsafe,
    SkipReason.accessDenied => l.skipAccessDenied,
    SkipReason.other || SkipReason.unknown => l.skipOther,
  };
}

/// D4 Skip reason (`/driver/stops/:taskId/skip`): two taps to skip; `other` needs a ≥ 3 letter
/// note. Works offline (outbox `task_status skipped`).
class SkipReasonScreen extends ConsumerStatefulWidget {
  const SkipReasonScreen({required this.taskId, super.key});

  final String taskId;

  @override
  ConsumerState<SkipReasonScreen> createState() => _SkipReasonScreenState();
}

class _SkipReasonScreenState extends ConsumerState<SkipReasonScreen> {
  SkipReason? _reason;
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _valid => _reason != null && (!_reason!.needsNote || _note.text.trim().length >= 3);

  Future<void> _skip() async {
    final stop = ref.read(stopDetailProvider(widget.taskId)).value;
    if (stop == null || !_valid) return;
    setState(() => _busy = true);
    await ref
        .read(stopActionsProvider.notifier)
        .skip(stop, _reason!, note: _reason!.needsNote ? _note.text.trim() : null);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.driverSkipTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            RadioGroup<SkipReason>(
              groupValue: _reason,
              onChanged: (v) => setState(() => _reason = v),
              child: Column(
                children: [
                  for (final r in SkipReason.choices)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: RadioListTile<SkipReason>(
                        value: r,
                        title: Text(r.label(l), style: Theme.of(context).textTheme.titleMedium),
                      ),
                    ),
                ],
              ),
            ),
            if (_reason?.needsNote ?? false)
              TextField(
                controller: _note,
                autofocus: true,
                maxLength: 200,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l.driverSkipNote,
                  border: const OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(onPressed: () => context.pop(), child: Text(l.commonCancel)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: BigActionButton(
                    icon: Icons.skip_next,
                    label: l.driverSkipButton,
                    busy: _busy,
                    onPressed: _valid && !_busy ? _skip : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
