import 'package:flutter/material.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';

/// Shimmer-free placeholder blocks (cheap on low-end GPUs; SCREENS §0.1).
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({this.blocks = 4, this.blockHeight = 72, super.key});

  final int blocks;
  final double blockHeight;

  @override
  Widget build(BuildContext context) {
    final c = context.hawaColors;
    return Semantics(
      label: context.l10n.commonLoading,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: blocks,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) => Container(
          height: i == 0 ? blockHeight * 1.8 : blockHeight,
          decoration: BoxDecoration(color: c.muted, borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
