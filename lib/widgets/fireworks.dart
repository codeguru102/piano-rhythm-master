import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Played once at the tap position when a tile is hit correctly: the tile
/// bursts into shards and a colorful fireworks spray.
///
/// Performance: this is drawn every frame while tiles are falling, so it uses
/// only cheap additive solid fills (NO MaskFilter.blur, which is expensive and
/// caused jank on software GPUs). Glow is faked with layered translucent
/// circles. Calls [onDone] when finished so the host can remove it.
class Fireworks extends StatefulWidget {
  const Fireworks({super.key, required this.color, required this.onDone});

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
        vsync: this, duration: const Duration(milliseconds: 640))
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
    // RepaintBoundary keeps this burst on its own raster layer so it doesn't
    // force the falling-tiles board to re-rasterize (and vice versa).
    return RepaintBoundary(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) =>
              CustomPaint(painter: _FireworksPainter(_c.value, widget.color)),
        ),
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

    final eo = 1 - math.pow(1 - t, 1.9).toDouble();
    final fade = math.pow(1 - t, 1.3).toDouble().clamp(0.0, 1.0);
    final gravity = maxR * 0.8 * t * t;
    final palette = [Colors.white, color, _gold, _pink, _cyan];
    final add = BlendMode.plus;

    // 1) soft bloom — two layered translucent circles (cheap, no blur)
    final bloomR = maxR * (0.30 + 0.5 * eo);
    canvas.drawCircle(c, bloomR,
        Paint()..color = color.withValues(alpha: 0.14 * fade)..blendMode = add);
    canvas.drawCircle(c, bloomR * 0.6,
        Paint()..color = color.withValues(alpha: 0.18 * fade)..blendMode = add);

    // 2) twin shockwave rings (solid strokes)
    for (var k = 0; k < 2; k++) {
      final rt = (t / (k == 0 ? 0.5 : 0.8)).clamp(0.0, 1.0);
      final rFade = (1 - rt).clamp(0.0, 1.0);
      if (rFade <= 0) continue;
      canvas.drawCircle(
        c,
        maxR * (0.15 + 0.85 * rt),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (k == 0 ? 3.5 : 2) * rFade
          ..color = (k == 0 ? Colors.white : color).withValues(alpha: 0.7 * rFade)
          ..blendMode = add,
      );
    }

    // 3) tile shards flying out (the tile breaking apart)
    const shards = 7;
    final shardFill = Paint()
      ..color = Color.lerp(color, const Color(0xFF0B0917), 0.5)!
          .withValues(alpha: fade);
    final shardEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color.withValues(alpha: fade);
    for (var j = 0; j < shards; j++) {
      final a = (j / shards) * 2 * math.pi + 0.5;
      final dir = Offset(math.cos(a), math.sin(a));
      final d = maxR * (0.26 + _r(j, 5) * 0.32) * eo;
      final pos = c + dir * d + Offset(0, gravity * 0.75);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(a + t * 5);
      final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: 15 * fade, height: 10 * fade),
          const Radius.circular(3));
      canvas.drawRRect(rect, shardFill);
      canvas.drawRRect(rect, shardEdge);
      canvas.restore();
    }

    // 4) sparks: a tapered trail + a layered glow head (all solid, additive)
    const sparks = 22;
    for (var i = 0; i < sparks; i++) {
      final a = (i / sparks) * 2 * math.pi + (_r(i, 2) - 0.5) * 0.4;
      final dir = Offset(math.cos(a), math.sin(a));
      final sp = 0.45 + _r(i, 1) * 0.6;
      final pos = c + dir * (maxR * sp * eo) + Offset(0, gravity);
      final col = palette[i % palette.length];
      final tw = 0.7 + 0.3 * math.sin(t * 30 + i.toDouble());
      final alpha = (fade * tw).clamp(0.0, 1.0);
      final headR = (1.6 + _r(i, 3) * 2.2) * fade;

      canvas.drawLine(
        pos - dir * (maxR * 0.14 * sp * eo),
        pos,
        Paint()
          ..color = col.withValues(alpha: 0.4 * alpha)
          ..strokeWidth = headR * 0.8
          ..strokeCap = StrokeCap.round
          ..blendMode = add,
      );
      // layered glow head (outer faint -> inner bright), no blur
      canvas.drawCircle(pos, headR * 2.1,
          Paint()..color = col.withValues(alpha: 0.16 * alpha)..blendMode = add);
      canvas.drawCircle(pos, headR * 1.3,
          Paint()..color = col.withValues(alpha: 0.4 * alpha)..blendMode = add);
      canvas.drawCircle(pos, headR,
          Paint()..color = col.withValues(alpha: alpha)..blendMode = add);
      if (i.isEven) {
        canvas.drawCircle(pos, headR * 0.5,
            Paint()..color = Colors.white.withValues(alpha: alpha));
      }
    }

    // 5) white-hot core flash (layered solid circles)
    final flash = (1 - t * 3).clamp(0.0, 1.0);
    if (flash > 0) {
      canvas.drawCircle(c, maxR * 0.34 * flash + 6,
          Paint()..color = color.withValues(alpha: 0.5 * flash)..blendMode = add);
      canvas.drawCircle(c, maxR * 0.2 * flash + 3,
          Paint()..color = Colors.white.withValues(alpha: 0.95 * flash)..blendMode = add);
    }

    // 6) a few sparkle stars for shimmer (solid paths)
    const stars = 4;
    for (var s = 0; s < stars; s++) {
      final a = _r(s, 7) * 2 * math.pi;
      final d = maxR * (0.45 + _r(s, 8) * 0.4) * eo;
      final p =
          c + Offset(math.cos(a), math.sin(a)) * d + Offset(0, gravity * 0.6);
      final tw = (math.sin(t * 20 + s * 2) * 0.5 + 0.5) * fade;
      if (tw <= 0.06) continue;
      final rr = 3.0 + tw * 4;
      canvas.drawPath(
          _star4(p, rr),
          Paint()
            ..color = Colors.white.withValues(alpha: tw)
            ..blendMode = add);
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
