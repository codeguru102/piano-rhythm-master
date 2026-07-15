import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Played once at the tap position when a tile is hit correctly: the tile
/// bursts into shards and a lush multi-color fireworks spray — glowing sparks
/// with tapered trails that arc under gravity, twin shockwave rings, a
/// white-hot core flash and drifting sparkles. Calls [onDone] when finished.
class Fireworks extends StatefulWidget {
  const Fireworks({super.key, required this.color, required this.onDone});

  /// The lane's accent color — anchors the spark/shard palette.
  final Color color;
  final VoidCallback onDone;

  @override
  State<Fireworks> createState() => _FireworksState();
}

class _FireworksState extends State<Fireworks>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 720))
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
            CustomPaint(painter: _FireworksPainter(_c.value, widget.color)),
      ),
    );
  }
}

class _FireworksPainter extends CustomPainter {
  _FireworksPainter(this.t, this.color);

  final double t;
  final Color color;

  static const _gold = Color(0xFFFFD76B);
  static const _pink = Color(0xFFFF4D9D);
  static const _cyan = Color(0xFF33E1ED);

  double _r(int i, int salt) {
    final v = math.sin(i * 12.9898 + salt * 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final maxR = size.shortestSide / 2;

    final eo = 1 - math.pow(1 - t, 1.9).toDouble(); // fast punch, decelerate
    final fade = math.pow(1 - t, 1.25).toDouble().clamp(0.0, 1.0);
    final gravity = maxR * 0.85 * t * t;
    final palette = [Colors.white, color, _gold, _pink, _cyan];

    // 1) heat glow bloom behind everything
    canvas.drawCircle(
      c,
      maxR * (0.30 + 0.55 * eo),
      Paint()
        ..color = color.withValues(alpha: 0.22 * fade)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26)
        ..blendMode = BlendMode.plus,
    );

    // 2) twin shockwave rings
    for (var k = 0; k < 2; k++) {
      final rt = (t / (k == 0 ? 0.5 : 0.8)).clamp(0.0, 1.0);
      final rFade = (1 - rt).clamp(0.0, 1.0);
      if (rFade <= 0) continue;
      canvas.drawCircle(
        c,
        maxR * (0.15 + 0.85 * rt),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (k == 0 ? 4 : 2.2) * rFade
          ..color = (k == 0 ? Colors.white : color).withValues(alpha: 0.75 * rFade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
          ..blendMode = BlendMode.plus,
      );
    }

    // 3) tile shards flying out (the tile breaking apart)
    const shards = 7;
    for (var j = 0; j < shards; j++) {
      final a = (j / shards) * 2 * math.pi + 0.5;
      final dir = Offset(math.cos(a), math.sin(a));
      final d = maxR * (0.26 + _r(j, 5) * 0.32) * eo;
      final pos = c + dir * d + Offset(0, gravity * 0.75);
      final w = 15.0 * fade;
      final hh = 10.0 * fade;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(a + t * 5);
      final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: hh),
          const Radius.circular(3));
      canvas.drawRRect(
          rect,
          Paint()
            ..color = Color.lerp(color, const Color(0xFF0B0917), 0.5)!
                .withValues(alpha: fade));
      canvas.drawRRect(
          rect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = color.withValues(alpha: fade));
      canvas.restore();
    }

    // 4) fireworks sparks: glowing heads + tapered trails, arcing with gravity
    const sparks = 42;
    for (var i = 0; i < sparks; i++) {
      final a = (i / sparks) * 2 * math.pi + (_r(i, 2) - 0.5) * 0.4;
      final dir = Offset(math.cos(a), math.sin(a));
      final sp = 0.45 + _r(i, 1) * 0.6;
      final dist = maxR * sp * eo;
      final pos = c + dir * dist + Offset(0, gravity);
      final col = palette[i % palette.length];
      // subtle twinkle
      final tw = 0.65 + 0.35 * math.sin(t * 34 + i.toDouble());
      final alpha = (fade * tw).clamp(0.0, 1.0);
      final headR = (1.5 + _r(i, 3) * 2.4) * fade;

      // trail
      final trail = dir * (maxR * 0.15 * sp * eo);
      canvas.drawLine(
        pos - trail,
        pos,
        Paint()
          ..color = col.withValues(alpha: 0.45 * alpha)
          ..strokeWidth = headR * 0.85
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5)
          ..blendMode = BlendMode.plus,
      );
      // glowing head
      canvas.drawCircle(
        pos,
        headR,
        Paint()
          ..color = col.withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)
          ..blendMode = BlendMode.plus,
      );
      // white hot core on the brightest sparks
      if (i.isEven) {
        canvas.drawCircle(
          pos,
          headR * 0.5,
          Paint()..color = Colors.white.withValues(alpha: alpha),
        );
      }
    }

    // 5) white-hot core flash (very start)
    final flash = (1 - t * 3).clamp(0.0, 1.0);
    if (flash > 0) {
      canvas.drawCircle(
        c,
        maxR * 0.3 * flash + 4,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.95 * flash)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
          ..blendMode = BlendMode.plus,
      );
    }

    // 6) drifting sparkle stars for extra shimmer
    const stars = 5;
    for (var s = 0; s < stars; s++) {
      final a = _r(s, 7) * 2 * math.pi;
      final d = maxR * (0.45 + _r(s, 8) * 0.4) * eo;
      final p = c + Offset(math.cos(a), math.sin(a)) * d + Offset(0, gravity * 0.6);
      final tw = (math.sin(t * 20 + s * 2) * 0.5 + 0.5) * fade;
      if (tw <= 0.05) continue;
      final rr = 3.0 + tw * 4;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: tw)
        ..blendMode = BlendMode.plus;
      canvas.drawPath(_star4(p, rr), paint);
    }
  }

  Path _star4(Offset c, double r) => Path()
    ..moveTo(c.dx, c.dy - r)
    ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
    ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
    ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
    ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
    ..close();

  @override
  bool shouldRepaint(_FireworksPainter old) => old.t != t;
}
