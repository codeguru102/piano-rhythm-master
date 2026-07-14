import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A short-lived burst played when a note is hit: an expanding glowing ring
/// plus radiating sparks. Calls [onDone] when finished so it can be removed.
class HitBurst extends StatefulWidget {
  const HitBurst({super.key, required this.color, required this.onDone});

  final Color color;
  final VoidCallback onDone;

  @override
  State<HitBurst> createState() => _HitBurstState();
}

class _HitBurstState extends State<HitBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480))
      ..forward()
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone();
      });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) =>
            CustomPaint(painter: _BurstPainter(_c.value, widget.color)),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.t, this.color);
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final fade = (1 - t).clamp(0.0, 1.0);

    // expanding ring
    final ringR = 8 + t * 34;
    canvas.drawCircle(
      center,
      ringR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * fade
        ..color = color.withValues(alpha: 0.8 * fade)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // bright core flash
    canvas.drawCircle(
      center,
      10 * fade,
      Paint()..color = Colors.white.withValues(alpha: 0.9 * fade),
    );

    // radiating sparks
    const sparks = 8;
    final sparkPaint = Paint()
      ..color = color.withValues(alpha: fade)
      ..strokeWidth = 2.4 * fade
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < sparks; i++) {
      final a = (i / sparks) * 2 * math.pi;
      final r0 = 10 + t * 20;
      final r1 = 16 + t * 40;
      canvas.drawLine(
        center + Offset(math.cos(a) * r0, math.sin(a) * r0),
        center + Offset(math.cos(a) * r1, math.sin(a) * r1),
        sparkPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}
