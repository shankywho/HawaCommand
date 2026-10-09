import 'package:flutter/material.dart';
import 'package:hawacommand_app/app/theme.dart';
import 'package:hawacommand_app/core/i18n.dart';

/// The HawaCommand mark: a 2×2 pixel grid (paper/teal) on an ink disc.
class HawaMark extends StatelessWidget {
  const HawaMark({super.key, this.size = 38});

  final double size;

  @override
  Widget build(BuildContext context) {
    final cell = size * 5 / 38;
    final gap = size * 2 / 38;
    Widget px(Color c) => SizedBox(
      width: cell,
      height: cell,
      child: ColoredBox(color: c),
    );
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: HawaColors.ink,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              px(HawaColors.paper),
              SizedBox(width: gap),
              px(HawaColors.tealBright),
            ],
          ),
          SizedBox(height: gap),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              px(HawaColors.tealBright),
              SizedBox(width: gap),
              px(HawaColors.paper),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dark vehicle chip, e.g. `T-12`.
class AssetChip extends StatelessWidget {
  const AssetChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: HawaColors.ink,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: HawaText.mono(
          13,
          weight: FontWeight.w600,
          color: HawaColors.paper,
        ),
      ),
    );
  }
}

/// Shrinks slightly while pressed (`style-active: transform: scale(.98)`).
class Pressable extends StatefulWidget {
  const Pressable({required this.child, this.onTap, super.key});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool value) {
    if (widget.onTap == null) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.98 : 1,
        duration: const Duration(milliseconds: 90),
        child: widget.child,
      ),
    );
  }
}

/// The 68 px two-line action button (Hindi on top, English below).
class BigActionButton extends StatelessWidget {
  const BigActionButton({
    required this.icon,
    required this.labelHi,
    required this.labelEn,
    required this.onTap,
    this.background = HawaColors.teal,
    this.foreground = HawaColors.white,
    this.englishOpacity = 0.9,
    this.shadow = true,
    this.busy = false,
    super.key,
  });

  final IconData icon;
  final String labelHi;
  final String labelEn;
  final VoidCallback? onTap;
  final Color background;
  final Color foreground;
  final double englishOpacity;
  final bool shadow;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return Semantics(
      button: true,
      label: tr(labelHi, labelEn, both: '$labelHi, $labelEn'),
      excludeSemantics: true,
      child: Pressable(
        onTap: busy ? null : onTap,
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: onTap == null ? background.withValues(alpha: 0.5) : background,
            borderRadius: BorderRadius.circular(14),
            boxShadow: shadow
                ? [
                    BoxShadow(
                      color: background.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: foreground,
                  ),
                )
              else
                Icon(icon, size: 22, color: foreground),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr.primary(labelHi, labelEn),
                    style: tr.style(
                      22,
                      weight: FontWeight.w700,
                      height: 1.1,
                      color: foreground,
                    ),
                  ),
                  if (tr.isBoth)
                    Opacity(
                      opacity: englishOpacity,
                      child: Text(
                        labelEn,
                        style: HawaText.sans(
                          13,
                          weight: FontWeight.w500,
                          color: foreground,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Numbered stop badge: 56×56, radius 10, Geist Mono 600 28.
class StopBadge extends StatelessWidget {
  const StopBadge({
    required this.number,
    this.active = false,
    this.done = false,
    super.key,
  });

  final int number;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (active) {
      bg = HawaColors.ink;
      fg = HawaColors.paper;
    } else if (done) {
      bg = HawaColors.outgoing;
      fg = HawaColors.teal;
    } else {
      bg = HawaColors.line;
      fg = HawaColors.ink;
    }
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: done
          ? Icon(Icons.check_rounded, size: 30, color: fg)
          : Text(
              '$number',
              style: HawaText.mono(28, weight: FontWeight.w600, color: fg),
            ),
    );
  }
}

/// White card with a hairline border, used for stops and list rows.
class HawaCard extends StatelessWidget {
  const HawaCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderColor = HawaColors.line,
    this.borderWidth = 1,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color borderColor;
  final double borderWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: HawaColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Pressable(onTap: onTap, child: card);
  }
}

/// Small pill telling the user whether data is live or bundled demo data.
class SourcePill extends StatelessWidget {
  const SourcePill({required this.live, super.key, this.onTap});

  final bool live;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = live ? HawaColors.teal : HawaColors.muted;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: live ? HawaColors.outgoing : HawaColors.line,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              live
                  ? context.tr('लाइव', 'LIVE', both: 'LIVE')
                  : context.tr('डेमो डेटा', 'DEMO DATA', both: 'DEMO DATA'),
              style: HawaText.mono(10, weight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
