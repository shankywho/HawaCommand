import 'package:flutter/material.dart';
import 'package:hawacommand_app/app/theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// WhatsApp-style thread header: back chevron, round avatar, title, subtitle.
class ChatHeader extends StatelessWidget {
  const ChatHeader({
    required this.avatar,
    required this.title,
    required this.subtitle,
    this.onBack,
    this.trailing,
    super.key,
  });

  final Widget avatar;
  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
      decoration: const BoxDecoration(
        color: HawaColors.paper,
        border: Border(bottom: BorderSide(color: HawaColors.line)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(LucideIcons.chevronLeft, size: 22),
            color: HawaColors.ink,
          ),
          avatar,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: HawaText.sans(16, weight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: HawaText.sans(12, color: HawaColors.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Round 38 px ink avatar with a teal icon (Citizen Eyes).
class IconAvatar extends StatelessWidget {
  const IconAvatar(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        color: HawaColors.ink,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: HawaColors.tealBright),
    );
  }
}

/// Which corner of a bubble is "pinched" (the tail side).
enum BubbleSide { incoming, outgoing, plain }

/// A chat bubble with the design's radii and shadow.
class Bubble extends StatelessWidget {
  const Bubble({
    required this.child,
    this.side = BubbleSide.incoming,
    this.color,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    this.maxWidthFactor = 0.88,
    this.border,
    this.shadow = true,
    this.width,
    super.key,
  });

  final Widget child;
  final BubbleSide side;
  final Color? color;
  final EdgeInsets padding;
  final double maxWidthFactor;
  final BoxBorder? border;
  final bool shadow;

  /// Fixed width as a fraction of the thread width (e.g. photo bubbles).
  final double? width;

  @override
  Widget build(BuildContext context) {
    final radius = switch (side) {
      BubbleSide.incoming => const BorderRadius.only(
        topLeft: Radius.circular(4),
        topRight: Radius.circular(14),
        bottomLeft: Radius.circular(14),
        bottomRight: Radius.circular(14),
      ),
      BubbleSide.outgoing => const BorderRadius.only(
        topLeft: Radius.circular(14),
        topRight: Radius.circular(4),
        bottomLeft: Radius.circular(14),
        bottomRight: Radius.circular(14),
      ),
      BubbleSide.plain => BorderRadius.circular(14),
    };
    final bg = color ?? (side == BubbleSide.outgoing ? HawaColors.outgoing : HawaColors.white);
    return LayoutBuilder(
      builder: (context, constraints) {
        final max = constraints.maxWidth;
        return Align(
          alignment: side == BubbleSide.outgoing ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: max * maxWidthFactor),
            child: _maybeIntrinsic(
              Container(
                width: width == null ? null : max * width!,
                padding: padding,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: radius,
                  border: border,
                  boxShadow: shadow
                      ? const [
                          BoxShadow(
                            color: Color(0x140B1215),
                            blurRadius: 1,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Fixed-width bubbles keep their width; others shrink to their content.
  Widget _maybeIntrinsic(Widget bubble) => width == null ? IntrinsicWidth(child: bubble) : bubble;
}

/// Right-aligned `11px Geist Mono` timestamp.
class BubbleTime extends StatelessWidget {
  const BubbleTime(this.text, {this.color = HawaColors.muted, super.key});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(text, style: HawaText.mono(11, color: color)),
    );
  }
}

/// Centered date pill, e.g. `Wed 11 Nov`.
class DatePill extends StatelessWidget {
  const DatePill(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: HawaColors.paper,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text, style: HawaText.sans(12, color: HawaColors.muted2)),
      ),
    );
  }
}

/// Outgoing text reply bubble with delivered ticks.
class OutgoingText extends StatelessWidget {
  const OutgoingText({required this.text, required this.time, super.key});

  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Bubble(
      side: BubbleSide.outgoing,
      maxWidthFactor: 0.78,
      shadow: false,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: HawaText.sans(15)),
          const SizedBox(height: 2),
          BubbleTime('$time ✓✓', color: HawaColors.muted2),
        ],
      ),
    );
  }
}

/// Bottom composer bar: rounded input plus a round action button.
class ChatComposer extends StatelessWidget {
  const ChatComposer({
    required this.hint,
    this.controller,
    this.onSubmit,
    this.onTapField,
    this.leading,
    this.trailing,
    super.key,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onSubmit;

  /// When set, the field is read-only and tapping it calls this instead.
  final VoidCallback? onTapField;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      color: HawaColors.paper,
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + (bottom > 0 ? bottom : 16)),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          Expanded(
            child: SizedBox(
              height: 42,
              child: TextField(
                controller: controller,
                expands: true,
                maxLines: null,
                textAlignVertical: TextAlignVertical.center,
                keyboardType: TextInputType.text,
                readOnly: onTapField != null,
                onTap: onTapField,
                onSubmitted: onSubmit,
                textInputAction: TextInputAction.send,
                style: HawaText.sans(15),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: HawaText.sans(15, color: HawaColors.muted),
                  filled: true,
                  fillColor: HawaColors.white,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(21),
                    borderSide: const BorderSide(color: HawaColors.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(21),
                    borderSide: const BorderSide(color: HawaColors.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(21),
                    borderSide: const BorderSide(color: HawaColors.teal),
                  ),
                ),
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

/// 42 px round button used in the composer (mic / send / camera).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.filled = true,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? HawaColors.teal : HawaColors.white,
        shape: CircleBorder(
          side: filled ? BorderSide.none : const BorderSide(color: HawaColors.line),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              icon,
              size: 18,
              color: filled ? HawaColors.white : HawaColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
