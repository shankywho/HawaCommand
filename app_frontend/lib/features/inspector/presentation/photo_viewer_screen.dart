import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/core/utils/ist_time.dart';
import 'package:hawa_app/features/inspector/application/inspector_controllers.dart';
import 'package:hawa_app/features/inspector/presentation/target_detail_screen.dart';

/// I5 Photo viewer: full-screen pinch-zoom with the capture time and "Reported by a citizen".
/// No share or save action.
class PhotoViewerScreen extends ConsumerWidget {
  const PhotoViewerScreen({required this.targetId, required this.index, super.key});

  final String targetId;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final ev = ref.watch(targetEvidenceProvider(targetId)).value;
    final photos = ev?.photos ?? const <String>[];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          ev?.photoAt == null
              ? l.inspectorReporter
              : '${IstTime.time(ev!.photoAt!, context.lang)} · ${l.inspectorReporter}',
        ),
      ),
      body: photos.isEmpty
          ? const SizedBox.shrink()
          : PageView(
              controller: PageController(initialPage: index.clamp(0, photos.length - 1)),
              children: [
                for (final url in photos)
                  InteractiveViewer(
                    minScale: 1,
                    maxScale: 5,
                    child: Center(
                      child: EvidenceImage(url: url, fit: BoxFit.contain),
                    ),
                  ),
              ],
            ),
    );
  }
}
