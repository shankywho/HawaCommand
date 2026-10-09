import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawacommand_app/app/theme.dart';
import 'package:hawacommand_app/core/api_client.dart';
import 'package:hawacommand_app/core/i18n.dart';
import 'package:hawacommand_app/features/school/school_data.dart';
import 'package:hawacommand_app/widgets/chat.dart';
import 'package:hawacommand_app/widgets/common.dart';
import 'package:hawacommand_app/widgets/states.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A one-tap reply under the alert, in both languages.
enum _QuickReply {
  indoors(
    LucideIcons.check,
    'प्रार्थना सभा अंदर कर दी',
    'Assembly moved indoors',
  ),
  resend(
    LucideIcons.clock,
    '12 बजे सुरक्षित समय फिर भेजें',
    'Send me the safe window again at 12',
  );

  const _QuickReply(this.icon, this.hi, this.en);

  final IconData icon;
  final String hi;
  final String en;

  /// The design keeps quick replies in English in bilingual mode.
  String label(Tr tr) => tr.isHi ? hi : en;
}

/// Design screen 03 · School principal · WhatsApp alert.
class SchoolAlertScreen extends ConsumerStatefulWidget {
  const SchoolAlertScreen({super.key});

  @override
  ConsumerState<SchoolAlertScreen> createState() => _SchoolAlertScreenState();
}

class _SchoolAlertScreenState extends ConsumerState<SchoolAlertScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(String text, {bool resend = false}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final tr = context.tr;
    unawaited(HapticFeedback.selectionClick());
    final replies = ref.read(schoolRepliesProvider.notifier)..send(trimmed);
    _input.clear();
    if (resend) {
      final ack = tr(
        'ठीक है। दोपहर 12:00 बजे सुरक्षित समय फिर भेजेंगे।',
        "OK. We'll resend the safe window at 12:00.",
        both:
            'ठीक है। दोपहर 12:00 बजे सुरक्षित समय फिर भेजेंगे।\n'
            "OK. We'll resend the safe window at 12:00.",
      );
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        replies.acknowledge(ack);
        _scrollToEnd();
      });
    }
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      unawaited(
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final alertAsync = ref.watch(schoolAlertProvider);
    final replies = ref.watch(schoolRepliesProvider);
    final tr = context.tr;
    final empty = _input.text.trim().isEmpty;

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
                  avatar: const HawaMark(),
                  title: 'HawaCommand Alerts',
                  subtitle: tr(
                    'दिल्ली की हवा · आधिकारिक बिज़नेस अकाउंट',
                    'Delhi air · official business account',
                    both: 'Delhi air · official business account',
                  ),
                  onBack: () => context.canPop() ? context.pop() : context.go('/'),
                  trailing: alertAsync.value == null
                      ? null
                      : SourcePill(
                          live: alertAsync.value!.isLive,
                          onTap: () => context.push('/settings'),
                        ),
                ),
              ),
            ),
            Expanded(
              child: alertAsync.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(
                  message: HawaApi.describeError(error),
                  onRetry: () => ref.invalidate(schoolAlertProvider),
                ),
                data: (sourced) => _Thread(
                  alert: sourced.data,
                  replies: replies,
                  controller: _scroll,
                  onQuick: (q) => _send(q.label(tr), resend: q == _QuickReply.resend),
                  onRefresh: () => ref.refresh(schoolAlertProvider.future),
                ),
              ),
            ),
            ChatComposer(
              hint: tr('संदेश', 'Message', both: 'Message'),
              controller: _input,
              onSubmit: _send,
              trailing: RoundIconButton(
                icon: empty ? LucideIcons.mic : LucideIcons.send,
                tooltip: empty ? tr('वॉइस नोट', 'Voice note') : tr('भेजें', 'Send'),
                onTap: () {
                  if (empty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          tr(
                            'वॉइस नोट जल्द आएँगे',
                            'Voice notes are coming soon',
                          ),
                        ),
                      ),
                    );
                  } else {
                    _send(_input.text);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thread extends StatelessWidget {
  const _Thread({
    required this.alert,
    required this.replies,
    required this.controller,
    required this.onQuick,
    required this.onRefresh,
  });

  final SchoolAlert alert;
  final List<SentReply> replies;
  final ScrollController controller;
  final ValueChanged<_QuickReply> onQuick;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final time = DateFormat('HH:mm').format(alert.sentAt);
    final hindi = alert.messageHi;
    final showEnglishBubble = tr.showEn || hindi == null;
    final showHindiBubble = tr.showHi && hindi != null;

    return RefreshIndicator(
      color: HawaColors.teal,
      onRefresh: onRefresh,
      child: ListView(
        controller: controller,
        padding: const EdgeInsets.all(16),
        children: [
          DatePill(tr.shortDate(alert.sentAt)),
          const SizedBox(height: 10),
          if (showEnglishBubble)
            Bubble(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AqiChip(alert.chip),
                  const SizedBox(height: 8),
                  _BoldTimes(
                    alert.message,
                    style: HawaText.sans(16, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    alert.detail,
                    style: HawaText.sans(
                      13,
                      height: 1.5,
                      color: HawaColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  BubbleTime(time),
                ],
              ),
            ),
          if (showHindiBubble) ...[
            if (showEnglishBubble) const SizedBox(height: 10),
            Bubble(
              // In Hindi-only mode this is the first bubble, so it gets the
              // tail, the AQI chip and the detail line.
              side: tr.isHi ? BubbleSide.incoming : BubbleSide.plain,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tr.isHi) ...[
                    _AqiChip(alert.chip),
                    const SizedBox(height: 8),
                  ],
                  Text(hindi, style: HawaText.deva(15, height: 1.6)),
                  if (tr.isHi) ...[
                    const SizedBox(height: 8),
                    Text(
                      alert.detailHi,
                      style: HawaText.deva(
                        13,
                        height: 1.5,
                        color: HawaColors.muted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  BubbleTime(time),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 0.88,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final q in _QuickReply.values) ...[
                  _QuickReplyButton(
                    icon: q.icon,
                    label: q.label(tr),
                    hindi: tr.isHi,
                    onTap: () => onQuick(q),
                  ),
                  if (q != _QuickReply.values.last) const SizedBox(height: 6),
                ],
              ],
            ),
          ),
          for (final reply in replies) ...[
            const SizedBox(height: 10),
            if (reply.fromSystem)
              Bubble(
                side: BubbleSide.plain,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(reply.text, style: HawaText.deva(15, height: 1.5)),
                    const SizedBox(height: 6),
                    BubbleTime(DateFormat('HH:mm').format(reply.at)),
                  ],
                ),
              )
            else
              OutgoingText(
                text: reply.text,
                time: DateFormat('HH:mm').format(reply.at),
              ),
          ],
        ],
      ),
    );
  }
}

class _AqiChip extends StatelessWidget {
  const _AqiChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: HawaColors.alert,
      child: Center(
        widthFactor: 1,
        child: Text(label, style: HawaText.pixel(10, color: HawaColors.white)),
      ),
    );
  }
}

class _QuickReplyButton extends StatelessWidget {
  const _QuickReplyButton({
    required this.icon,
    required this.label,
    required this.hindi,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool hindi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = hindi
        ? HawaText.deva(15, weight: FontWeight.w500, color: HawaColors.teal)
        : HawaText.sans(15, weight: FontWeight.w500, color: HawaColors.teal);
    return Material(
      color: HawaColors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: HawaColors.teal),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders [text] with time windows such as `12:30–2:00 PM` in semibold.
class _BoldTimes extends StatelessWidget {
  const _BoldTimes(this.text, {required this.style});

  final String text;
  final TextStyle style;

  static final _window = RegExp(
    r'\d{1,2}:\d{2}\s*(?:–|-|to)\s*\d{1,2}:\d{2}(?:\s*[AP]M)?',
  );

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    var last = 0;
    for (final m in _window.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      spans.add(
        TextSpan(
          text: m.group(0),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      );
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return Text.rich(TextSpan(style: style, children: spans));
  }
}
