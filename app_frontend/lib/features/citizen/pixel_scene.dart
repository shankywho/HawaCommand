import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated pixel-art "garbage burning" scene (design `<px-scene kind=burning>`).
///
/// Used as the sample report photo so the demo works without a camera.
class BurningPixelScene extends StatefulWidget {
  const BurningPixelScene({super.key, this.animate = true});

  final bool animate;

  @override
  State<BurningPixelScene> createState() => _BurningPixelSceneState();
}

class _BurningPixelSceneState extends State<BurningPixelScene> with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) unawaited(_clock.repeat());
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Photo: garbage burning behind the market',
      image: true,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _clock,
          builder: (context, _) => CustomPaint(painter: _ScenePainter(_clock.value)),
        ),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.t);

  final double t;

  static const _cols = 72;

  @override
  void paint(Canvas canvas, Size size) {
    final px = size.width / _cols;
    final rows = (size.height / px).ceil();
    final paint = Paint()..isAntiAlias = false;

    void cell(int x, int y, Color c) {
      paint.color = c;
      canvas.drawRect(
        Rect.fromLTWH(x * px, y * px, px + 0.6, px + 0.6),
        paint,
      );
    }

    final horizon = (rows * 0.68).round();

    // Hazy sky: banded beige-grey, darker towards the top.
    for (var y = 0; y < horizon; y++) {
      final k = y / horizon;
      final c = Color.lerp(
        const Color(0xFF9A958A),
        const Color(0xFFC9C2B2),
        k,
      )!;
      for (var x = 0; x < _cols; x++) {
        cell(x, y, c);
      }
    }

    // Ground: dusty brown with a few darker specks.
    final rnd = math.Random(7);
    for (var y = horizon; y < rows; y++) {
      for (var x = 0; x < _cols; x++) {
        final speck = rnd.nextDouble() < 0.08;
        cell(
          x,
          y,
          speck ? const Color(0xFF6F6454) : const Color(0xFF857A67),
        );
      }
    }

    // Market wall silhouette on the left.
    for (var x = 0; x < 16; x++) {
      for (var y = horizon - 7; y < horizon; y++) {
        cell(x, y, const Color(0xFF7D766A));
      }
    }

    // Garbage pile.
    const pileX = 30;
    for (var i = 0; i < 12; i++) {
      final h = (3 - (i - 6).abs() / 2.2).clamp(1, 3).round();
      for (var j = 0; j < h; j++) {
        cell(
          pileX + i,
          horizon - j,
          j.isEven ? const Color(0xFF4A3F33) : const Color(0xFF5E5143),
        );
      }
    }

    // Smoke plume: dark puffs rising and drifting left over time.
    for (var k = 0; k < 26; k++) {
      final phase = (t + k / 26) % 1.0;
      final y = horizon - 3 - phase * (horizon - 2);
      final drift = math.sin(phase * math.pi * 1.4 + k) * 2 - phase * 9;
      final radius = 1.4 + phase * 3.2;
      final shade = Color.lerp(
        const Color(0xFF2E2F31),
        const Color(0xFF6B6B69),
        phase,
      )!;
      final cx = pileX + 6 + drift;
      for (var dx = -radius; dx <= radius; dx++) {
        for (var dy = -radius; dy <= radius; dy++) {
          if (dx * dx + dy * dy <= radius * radius) {
            final x = (cx + dx).round();
            final yy = (y + dy).round();
            if (x >= 0 && x < _cols && yy >= 0 && yy < horizon) {
              cell(x, yy, shade);
            }
          }
        }
      }
    }

    // Flames: flickering orange/yellow tongues on the pile.
    for (var i = 0; i < 8; i++) {
      final flicker = (math.sin(t * math.pi * 12 + i * 1.7) + 1) / 2;
      final h = 2 + (flicker * 3).round();
      for (var j = 0; j < h; j++) {
        final c = j == 0
            ? const Color(0xFFE2471B)
            : (j < h - 1 ? const Color(0xFFF08A24) : const Color(0xFFFFD34D));
        cell(pileX + 2 + i, horizon - 2 - j, c);
      }
    }

    // A person watching, and a white delivery van on the right.
    const personX = 52;
    const skin = Color(0xFF8C5A3C);
    const shirt = Color(0xFF1F2A36);
    cell(personX, horizon - 6, skin);
    for (var y = horizon - 5; y < horizon - 2; y++) {
      cell(personX, y, shirt);
      cell(personX + 1, y, shirt);
    }
    cell(personX, horizon - 2, const Color(0xFF2B2B2B));
    cell(personX + 1, horizon - 2, const Color(0xFF2B2B2B));
    cell(personX, horizon - 1, const Color(0xFF2B2B2B));
    cell(personX + 1, horizon - 1, const Color(0xFF2B2B2B));

    const vanX = 57;
    for (var x = vanX; x < vanX + 12; x++) {
      for (var y = horizon - 5; y < horizon - 1; y++) {
        cell(x, y, const Color(0xFFF2F1EC));
      }
    }
    for (var x = vanX + 8; x < vanX + 11; x++) {
      cell(x, horizon - 4, const Color(0xFF6E8FA6));
    }
    cell(vanX + 2, horizon - 1, const Color(0xFF1B1B1B));
    cell(vanX + 3, horizon - 1, const Color(0xFF1B1B1B));
    cell(vanX + 9, horizon - 1, const Color(0xFF1B1B1B));
    cell(vanX + 10, horizon - 1, const Color(0xFF1B1B1B));
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) => oldDelegate.t != t;
}
