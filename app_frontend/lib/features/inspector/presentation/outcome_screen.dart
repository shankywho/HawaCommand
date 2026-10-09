import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/core/network/connectivity_service.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/core/widgets/big_action_button.dart';
import 'package:hawa_app/features/inspector/application/inspector_controllers.dart';
import 'package:hawa_app/features/shell/domain/app_permission.dart';
import 'package:hawa_app/features/shell/presentation/permission_education_screen.dart';

/// I4 Record outcome (`/inspector/targets/:targetId/outcome`): confirmed needs ≥ 1 photo, the
/// other two need a note. Saves offline (photo ops then `inspection_close`, closed exactly once).
class OutcomeScreen extends ConsumerStatefulWidget {
  const OutcomeScreen({required this.targetId, super.key});

  final String targetId;

  @override
  ConsumerState<OutcomeScreen> createState() => _OutcomeScreenState();
}

class _OutcomeScreenState extends ConsumerState<OutcomeScreen> {
  InspectionStatus? _outcome;
  final _photos = <String>[];
  final _notes = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  String? _problem() {
    final l = context.l10n;
    if (_outcome == null) return null;
    if (_outcome == InspectionStatus.closedConfirmed && _photos.isEmpty) return l.outcomeNeedPhoto;
    if (_outcome != InspectionStatus.closedConfirmed && _notes.text.trim().isEmpty) {
      return l.outcomeNeedNote;
    }
    return null;
  }

  Future<void> _addPhoto() async {
    if (!await ensurePermission(context, ref, AppPermission.camera)) return;
    final path = await ref.read(inspectorActionsProvider.notifier).takePhoto();
    if (path != null && mounted) setState(() => _photos.add(path));
  }

  Future<void> _save() async {
    final l = context.l10n;
    final offline = ref.read(networkStatusProvider).value?.isOffline ?? false;
    setState(() => _busy = true);
    await ref
        .read(inspectorActionsProvider.notifier)
        .close(widget.targetId, outcome: _outcome!, photos: _photos, notes: _notes.text);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(offline ? l.outcomeSavedOffline : l.outcomeSent)));
    context.go(Routes.inspector);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final options = [
      (InspectionStatus.closedConfirmed, Icons.check_circle_outline, l.outcomeConfirmed),
      (InspectionStatus.closedNotFound, Icons.cancel_outlined, l.outcomeNotFound),
      (InspectionStatus.closedUnreachable, Icons.do_not_disturb_on_outlined, l.outcomeUnreachable),
    ];
    final problem = _problem();
    return Scaffold(
      appBar: AppBar(title: Text(l.outcomeTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final (value, icon, label) in options)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: _outcome == value
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ListTile(
                  leading: Icon(icon),
                  title: Text(label, style: text.titleMedium),
                  selected: _outcome == value,
                  onTap: () => setState(() => _outcome = value),
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _busy ? null : _addPhoto,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(l.outcomeAddPhotos),
                ),
                for (final (i, p) in _photos.indexed)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(p), width: 72, height: 72, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton.filledTonal(
                          visualDensity: VisualDensity.compact,
                          tooltip: l.outcomeRemovePhoto,
                          onPressed: () => setState(() => _photos.removeAt(i)),
                          icon: const Icon(Icons.close, size: 16),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l.outcomeNotes,
                border: const OutlineInputBorder(),
              ),
            ),
            if (problem != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  problem,
                  style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 16),
            BigActionButton(
              icon: Icons.save_outlined,
              label: l.outcomeSave,
              busy: _busy,
              onPressed: _outcome != null && problem == null && !_busy ? _save : null,
            ),
          ],
        ),
      ),
    );
  }
}
