import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawacommand_app/app/theme.dart';
import 'package:hawacommand_app/core/air.dart';
import 'package:hawacommand_app/core/geo.dart';
import 'package:hawacommand_app/core/i18n.dart';
import 'package:hawacommand_app/features/citizen/citizen_data.dart';
import 'package:hawacommand_app/features/citizen/pixel_scene.dart';
import 'package:hawacommand_app/widgets/chat.dart';
import 'package:hawacommand_app/widgets/common.dart';
import 'package:hawacommand_app/widgets/form_fields.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Design screen 04 · Citizen Eyes · report burning.
class CitizenEyesScreen extends ConsumerWidget {
  const CitizenEyesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hotspotsAsync = ref.watch(hotspotsProvider);
    final hotspot = burningHotspot(
      hotspotsAsync.value?.data ?? demoHotspots,
    );
    final controller = ref.read(citizenReportProvider.notifier);
    final report = ref.watch(citizenReportProvider) ?? controller.exampleFrom(hotspot);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: hawaSystemUi,
      child: Scaffold(
        backgroundColor: HawaColors.chat,
        body: Column(
          children: [
            ColoredBox(
              color: HawaColors.paper,
              child: SafeArea(
                bottom: false,
                child: ChatHeader(
                  avatar: const IconAvatar(LucideIcons.eye),
                  title: 'Citizen Eyes',
                  subtitle: context.tr(
                    'रिपोर्ट ${report.id} · ${placeNameHi(report.place)}',
                    'Report ${report.id} · ${report.place}',
                    both: 'Report ${report.id} · ${report.place}',
                  ),
                  onBack: () => context.canPop() ? context.pop() : context.go('/'),
                  trailing: hotspotsAsync.value == null
                      ? null
                      : SourcePill(
                          live: hotspotsAsync.value!.isLive,
                          onTap: () => context.push('/settings'),
                        ),
                ),
              ),
            ),
            Expanded(child: _ReportThread(report: report)),
            ChatComposer(
              hint: context.tr(
                'रिपोर्ट के लिए फ़ोटो भेजें',
                'Send a photo to report',
                both: 'Send a photo to report',
              ),
              onTapField: () => _startReport(context, ref, hotspot),
              leading: RoundIconButton(
                icon: LucideIcons.camera,
                tooltip: context.tr('फ़ोटो खींचें', 'Take a photo'),
                filled: false,
                onTap: () => _startReport(context, ref, hotspot),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startReport(
    BuildContext context,
    WidgetRef ref,
    Hotspot hotspot,
  ) async {
    final source = await showModalBottomSheet<_PhotoSource>(
      context: context,
      builder: (_) => const _PhotoSourceSheet(),
    );
    if (source == null || !context.mounted) return;

    String? path;
    if (source != _PhotoSource.sample) {
      try {
        final picked = await ImagePicker().pickImage(
          source: source == _PhotoSource.camera ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 1280,
          imageQuality: 80,
        );
        if (picked == null) return;
        path = picked.path;
      } on PlatformException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${context.tr('कैमरा उपलब्ध नहीं', 'Camera unavailable')}: '
                '${e.message ?? e.code}',
              ),
            ),
          );
        }
        return;
      }
    }
    if (!context.mounted) return;

    final caption = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CaptionSheet(photoPath: path),
    );
    if (caption == null) return;
    unawaited(HapticFeedback.mediumImpact());
    ref
        .read(citizenReportProvider.notifier)
        .submit(hotspot: hotspot, caption: caption, photoPath: path);
  }
}

class _ReportThread extends StatelessWidget {
  const _ReportThread({required this.report});

  final CitizenReport report;

  @override
  Widget build(BuildContext context) {
    String hm(DateTime? t) => t == null ? '' : DateFormat('HH:mm').format(t);
    final tr = context.tr;
    final caption = tr.isHi && report.captionHi != null ? report.captionHi! : report.caption;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      children: [
        Bubble(
          side: BubbleSide.outgoing,
          width: 0.62,
          shadow: false,
          padding: const EdgeInsets.all(5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 110,
                  child: report.photoPath == null
                      ? const BurningPixelScene()
                      : Image.file(File(report.photoPath!), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(caption, style: tr.style(14)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 2),
                child: BubbleTime(
                  '${hm(report.sentAt)} ✓✓',
                  color: HawaColors.muted2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (!report.reached(ReportStage.verified))
          _TypingBubble(
            text: tr(
              'फ़ोटो जाँच रहे हैं…',
              'Checking the photo…',
              both: 'Checking the photo…',
            ),
          )
        else
          _StatusBubble(
            icon: LucideIcons.badgeCheck,
            title: tr('पुष्टि हुई', 'Verified', both: 'Verified'),
            titleIsHindi: tr.isHi,
            body: tr.isHi
                ? 'फ़ोटो में खुले में कूड़ा जलता दिख रहा है। 300 मीटर दूर सेंसर '
                      'स्पाइक से मिलान हुआ। भरोसा '
                      '${report.confidence.toStringAsFixed(2)}।'
                : 'Photo shows open burning. Matched to a sensor spike 300 m '
                      'away. Confidence ${report.confidence.toStringAsFixed(2)}.',
            bodyIsHindi: tr.isHi,
            time: hm(report.verifiedAt),
            incomingTail: true,
          ),
        if (report.reached(ReportStage.onTheWay)) ...[
          const SizedBox(height: 8),
          _StatusBubble(
            icon: LucideIcons.users,
            title: tr(
              'जाँच टीम रास्ते में',
              'Inspection team on the way',
              both: 'Inspection team on the way',
            ),
            titleIsHindi: tr.isHi,
            body: tr.isEn
                ? 'Inspection team ${report.team} is on the way · '
                      'ETA ${report.etaMinutes} min'
                : 'जाँच टीम ${report.team} रास्ते में है · '
                      'ETA ${report.etaMinutes} min',
            bodyIsHindi: !tr.isEn,
            time: hm(report.dispatchedAt),
          ),
        ],
        if (report.reached(ReportStage.resolved)) ...[
          const SizedBox(height: 8),
          _StatusBubble(
            icon: LucideIcons.circleCheck,
            title: tr(
              '${hm(report.resolvedAt)} पर हल हुआ',
              'Resolved at ${hm(report.resolvedAt)}',
              both: 'Resolved at ${hm(report.resolvedAt)}',
            ),
            titleIsHindi: tr.isHi,
            body: tr.isHi
                ? 'आग बुझा दी गई और साइट मालिक को सूचित किया गया। इलाके की हवा '
                      'सामान्य हो रही है। रिपोर्ट करने के लिए धन्यवाद।'
                : 'Fire put out and site owner notified. The cell is returning '
                      'to baseline. Thank you for reporting.',
            bodyIsHindi: tr.isHi,
            time: hm(report.resolvedAt),
            highlight: true,
          ),
        ],
        const SizedBox(height: 8),
        _Tracker(report: report),
      ],
    );
  }
}

class _StatusBubble extends StatelessWidget {
  const _StatusBubble({
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    this.incomingTail = false,
    this.highlight = false,
    this.bodyIsHindi = false,
    this.titleIsHindi = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final String time;
  final bool incomingTail;
  final bool highlight;
  final bool bodyIsHindi;
  final bool titleIsHindi;

  @override
  Widget build(BuildContext context) {
    final titleColor = highlight ? HawaColors.teal : HawaColors.ink;
    final bodyStyle = bodyIsHindi
        ? HawaText.deva(13.5, height: 1.5, color: HawaColors.muted2)
        : HawaText.sans(13.5, height: 1.5, color: HawaColors.muted2);
    return Bubble(
      side: incomingTail ? BubbleSide.incoming : BubbleSide.plain,
      maxWidthFactor: 0.84,
      shadow: false,
      border: highlight ? Border.all(color: HawaColors.teal, width: 2) : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: highlight ? 16 : 15, color: titleColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: (titleIsHindi ? HawaText.deva : HawaText.sans)(
                    highlight ? 15 : 14,
                    weight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: highlight ? 6 : 4),
          Text(body, style: bodyStyle),
          const SizedBox(height: 4),
          BubbleTime(time),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Bubble(
      maxWidthFactor: 0.84,
      shadow: false,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: HawaColors.teal,
            ),
          ),
          const SizedBox(width: 10),
          Text(text, style: HawaText.sans(14, color: HawaColors.muted2)),
        ],
      ),
    );
  }
}

class _Tracker extends StatelessWidget {
  const _Tracker({required this.report});

  final CitizenReport report;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: HawaColors.paper,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final stage in ReportStage.values)
            Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: report.reached(stage) ? HawaColors.teal : Colors.transparent,
                    border: report.reached(stage)
                        ? null
                        : Border.all(color: HawaColors.muted, width: 1.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr.isHi ? stage.labelHi : stage.label,
                  style: context.tr.isHi
                      ? HawaText.deva(12, color: HawaColors.muted2)
                      : HawaText.mono(12, color: HawaColors.muted2),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

enum _PhotoSource { camera, gallery, sample }

class _PhotoSourceSheet extends StatelessWidget {
  const _PhotoSourceSheet();

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    Widget option(_PhotoSource s, IconData icon, String hi, String en) => ListTile(
      leading: Icon(icon, color: HawaColors.ink),
      title: Text(
        tr.primary(hi, en),
        style: tr.style(16, weight: FontWeight.w600),
      ),
      subtitle: tr.isBoth ? Text(en, style: HawaText.sans(13, color: HawaColors.muted)) : null,
      onTap: () => Navigator.pop(context, s),
    );
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              tr.primary('जलता कूड़ा या धुआँ दिखा?', 'See burning or smoke?'),
              style: tr.style(20, weight: FontWeight.w700),
            ),
          ),
          option(
            _PhotoSource.camera,
            LucideIcons.camera,
            'फ़ोटो खींचें',
            'Take a photo',
          ),
          option(
            _PhotoSource.gallery,
            LucideIcons.image,
            'गैलरी से चुनें',
            'Choose from gallery',
          ),
          option(
            _PhotoSource.sample,
            LucideIcons.eye,
            'सैंपल फ़ोटो',
            'Use the sample photo (demo)',
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _CaptionSheet extends StatefulWidget {
  const _CaptionSheet({this.photoPath});

  final String? photoPath;

  @override
  State<_CaptionSheet> createState() => _CaptionSheetState();
}

class _CaptionSheetState extends State<_CaptionSheet> {
  late final TextEditingController _caption = TextEditingController(
    text: context.tr.isHi ? 'मार्केट के पीछे कूड़ा जल रहा है' : 'Garbage burning behind the market',
  );

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + keyboard),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 150,
                child: widget.photoPath == null
                    ? const BurningPixelScene()
                    : Image.file(File(widget.photoPath!), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _caption,
              maxLength: 120,
              style: HawaText.sans(15),
              decoration: hawaInputDecoration(
                label: context.tr('क्या दिख रहा है?', 'What do you see?'),
              ),
            ),
            const SizedBox(height: 4),
            BigActionButton(
              icon: LucideIcons.send,
              labelHi: 'रिपोर्ट भेजें',
              labelEn: 'Send report',
              onTap: () {
                final text = _caption.text.trim();
                Navigator.pop(
                  context,
                  text.isEmpty ? context.tr('जलने की रिपोर्ट', 'Burning reported') : text,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
