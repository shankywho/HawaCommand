import 'package:flutter/material.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';

/// Numbered stop marker (ARCHITECTURE §12.2): 40 dp ink circle with white Latin digits and a
/// status icon badge (never colour alone). A simulated asset gets a 2 dp violet outer ring.
class StopMarker extends StatelessWidget {
  const StopMarker({
    required this.number,
    required this.statusIcon,
    this.highlighted = false,
    this.simulated = false,
    this.semanticLabel,
    super.key,
  });

  final int number;
  final IconData? statusIcon;
  final bool highlighted;
  final bool simulated;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.hawaColors;
    return Semantics(
      label: semanticLabel,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: highlighted ? c.brand : c.ink,
                  shape: BoxShape.circle,
                  border: Border.all(color: simulated ? c.simulated : Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            if (statusIcon != null)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.ink),
                  ),
                  child: Icon(statusIcon, size: 14, color: c.ink),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Suspect pin (DESIGN_SYSTEM §8): ink teardrop, white cause glyph, 2 dp white stroke, scaled
/// 0.8–1.2 by `cause_conf`. Not danger red, which is reserved for real danger.
class SuspectPin extends StatelessWidget {
  const SuspectPin({required this.icon, required this.confidence, this.semanticLabel, super.key});

  final IconData icon;
  final double confidence;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scale = 0.8 + 0.4 * confidence.clamp(0.0, 1.0);
    return Semantics(
      label: semanticLabel,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.bottomCenter,
        child: CustomPaint(
          size: const Size(28, 36),
          painter: _TeardropPainter(context.hawaColors.ink),
          child: SizedBox(
            width: 28,
            height: 36,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _TeardropPainter extends CustomPainter {
  _TeardropPainter(this.fill);

  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..quadraticBezierTo(0, size.height * 0.55, 0, r)
      ..arcToPoint(Offset(size.width, r), radius: Radius.circular(r))
      ..quadraticBezierTo(size.width, size.height * 0.55, size.width / 2, size.height)
      ..close();
    canvas
      ..drawPath(path, Paint()..color = fill)
      ..drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
  }

  @override
  bool shouldRepaint(_TeardropPainter old) => old.fill != fill;
}

/// Citizen photo location (camera glyph in a rounded ink square).
class PhotoMarker extends StatelessWidget {
  const PhotoMarker({this.semanticLabel, super.key});

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    child: Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: context.hawaColors.ink,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(Icons.photo_camera, size: 16, color: Colors.white),
    ),
  );
}

/// The user's own position during a shift.
class PositionMarker extends StatelessWidget {
  const PositionMarker({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    decoration: BoxDecoration(
      color: context.hawaColors.info,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
    ),
  );
}
