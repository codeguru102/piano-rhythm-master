import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The "Piano Muse" — a hand-drawn (vector) cartoon woman mascot for the
/// splash / brand moment. Fully offline: no image assets, just Canvas paths
/// in the app's neon palette, with a gentle idle animation (bob, blink,
/// floating notes, twinkling sparkles).
class PianoMuse extends StatefulWidget {
  const PianoMuse({super.key, this.size = 190});

  final double size;

  @override
  State<PianoMuse> createState() => _PianoMuseState();
}

class _PianoMuseState extends State<PianoMuse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Virtual canvas is 220 x 250 -> keep that aspect ratio.
    return SizedBox(
      width: widget.size,
      height: widget.size * (250 / 220),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          painter: PianoMusePainter(_c.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

/// Paints the muse in a virtual 220x250 space, scaled to fit.
class PianoMusePainter extends CustomPainter {
  PianoMusePainter(this.t);

  /// Animation phase, 0..1 looping.
  final double t;

  // Design palette
  static const _skin = Color(0xFFF8C9A6);
  static const _skinShade = Color(0xFFE9AE86);
  static const _dark = Color(0xFF2A1B3D); // lashes / brows
  static const _bandLight = Color(0xFFE7ECFF);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 220.0;
    canvas.save();
    canvas.scale(s);

    // Gentle vertical bob for the whole figure.
    final bob = math.sin(t * 2 * math.pi) * 3.2;
    canvas.translate(0, bob);

    _backGlow(canvas);
    _backHair(canvas);
    _neck(canvas);
    _body(canvas);
    _face(canvas);
    _bangs(canvas);
    _features(canvas);
    _headphones(canvas);
    _pendant(canvas);

    canvas.restore();

    // Floating notes + sparkles use their own vertical motion (not the bob).
    canvas.save();
    canvas.scale(s);
    _floatingNotes(canvas);
    _sparkles(canvas);
    canvas.restore();
  }

  // ---- layers ----------------------------------------------------------

  void _backGlow(Canvas canvas) {
    final rect = Rect.fromCircle(center: const Offset(110, 120), radius: 118);
    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x559B5CFF), Color(0x00000000)],
      ).createShader(rect);
    canvas.drawCircle(const Offset(110, 120), 118, paint);
  }

  void _backHair(Canvas canvas) {
    final hair = Path()
      ..moveTo(28, 244)
      ..quadraticBezierTo(2, 150, 22, 92)
      ..quadraticBezierTo(44, 20, 110, 12)
      ..quadraticBezierTo(176, 20, 198, 92)
      ..quadraticBezierTo(218, 150, 192, 244)
      ..quadraticBezierTo(150, 214, 110, 224)
      ..quadraticBezierTo(70, 214, 28, 244)
      ..close();

    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.neonPurple, AppColors.neonPink],
      ).createShader(const Rect.fromLTWH(10, 10, 200, 240));
    canvas.drawPath(hair, paint);

    // soft highlight strands
    final hi = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(56, 40)
        ..quadraticBezierTo(30, 120, 44, 210),
      hi,
    );
    canvas.drawPath(
      Path()
        ..moveTo(168, 44)
        ..quadraticBezierTo(192, 120, 176, 208),
      hi,
    );
  }

  void _neck(Canvas canvas) {
    final r = RRect.fromRectAndRadius(
      const Rect.fromLTWH(93, 168, 34, 34),
      const Radius.circular(14),
    );
    canvas.drawRRect(r, Paint()..color = _skinShade);
  }

  void _body(Canvas canvas) {
    final body = Path()
      ..moveTo(40, 250)
      ..quadraticBezierTo(48, 198, 110, 190)
      ..quadraticBezierTo(172, 198, 180, 250)
      ..close();
    final paint = Paint()
      ..shader = AppGradients.primary.createShader(
        const Rect.fromLTWH(40, 188, 140, 62),
      );
    canvas.drawPath(body, paint);

    // collar V
    final collar = Path()
      ..moveTo(96, 196)
      ..lineTo(110, 214)
      ..lineTo(124, 196);
    canvas.drawPath(
      collar,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  void _face(Canvas canvas) {
    final faceRect = Rect.fromCenter(
      center: const Offset(110, 112),
      width: 116,
      height: 132,
    );
    canvas.drawOval(faceRect, Paint()..color = _skin);
    // soft cheek/jaw shading
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(110, 150), width: 96, height: 70),
      Paint()..color = _skinShade.withValues(alpha: 0.35),
    );
    // ears
    for (final ex in [54.0, 166.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(ex, 120), width: 18, height: 26),
        Paint()..color = _skin,
      );
    }
  }

  void _bangs(Canvas canvas) {
    final bangs = Path()
      ..moveTo(48, 104)
      ..quadraticBezierTo(40, 48, 98, 42)
      ..quadraticBezierTo(156, 38, 174, 96)
      ..quadraticBezierTo(150, 100, 140, 122)
      ..quadraticBezierTo(132, 92, 112, 112)
      ..quadraticBezierTo(96, 90, 80, 120)
      ..quadraticBezierTo(70, 96, 48, 104)
      ..close();
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFB07BFF), AppColors.neonPurple],
      ).createShader(const Rect.fromLTWH(40, 38, 140, 90));
    canvas.drawPath(bangs, paint);

    // side framing locks
    final lock = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.neonPurple, AppColors.neonPink],
      ).createShader(const Rect.fromLTWH(30, 60, 160, 150));
    canvas.drawPath(
      Path()
        ..moveTo(50, 96)
        ..quadraticBezierTo(36, 150, 52, 196)
        ..quadraticBezierTo(60, 150, 62, 118)
        ..close(),
      lock,
    );
    canvas.drawPath(
      Path()
        ..moveTo(170, 96)
        ..quadraticBezierTo(184, 150, 168, 196)
        ..quadraticBezierTo(160, 150, 158, 118)
        ..close(),
      lock,
    );
  }

  void _features(Canvas canvas) {
    // blink: single quick blink per loop near phase 0.72
    final d = (t - 0.72).abs();
    final open = d < 0.045 ? (d / 0.045).clamp(0.12, 1.0) : 1.0;

    const eyeY = 120.0;
    const eyes = [Offset(86, eyeY), Offset(134, eyeY)];

    // brows
    final brow = Paint()
      ..color = _dark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(70, 96)
        ..quadraticBezierTo(86, 88, 102, 94),
      brow,
    );
    canvas.drawPath(
      Path()
        ..moveTo(118, 94)
        ..quadraticBezierTo(134, 88, 150, 96),
      brow,
    );

    for (final e in eyes) {
      final h = 34.0 * open;
      // white
      canvas.drawOval(
        Rect.fromCenter(center: e, width: 30, height: h),
        Paint()..color = Colors.white,
      );
      // iris
      canvas.save();
      canvas.clipRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: e, width: 30, height: h),
          const Radius.circular(16),
        ),
      );
      canvas.drawCircle(e, 11, Paint()..color = AppColors.neonCyan);
      canvas.drawCircle(
        e,
        11,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0x000000FF), Color(0x553D8BFF)],
          ).createShader(Rect.fromCircle(center: e, radius: 11)),
      );
      canvas.drawCircle(e, 6.2, Paint()..color = _dark);
      canvas.drawCircle(
        Offset(e.dx - 3.5, e.dy - 4),
        3.4,
        Paint()..color = Colors.white.withValues(alpha: 0.95),
      );
      canvas.drawCircle(
        Offset(e.dx + 4, e.dy + 3),
        1.7,
        Paint()..color = Colors.white.withValues(alpha: 0.8),
      );
      canvas.restore();

      // upper lash line
      final lash = Paint()
        ..color = _dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCenter(center: e, width: 32, height: 34),
        math.pi * 1.05,
        math.pi * 0.9,
        false,
        lash,
      );
      // outer lash flick
      canvas.drawPath(
        Path()
          ..moveTo(e.dx + 14, e.dy - 4)
          ..lineTo(e.dx + 22, e.dy - 8)
          ..lineTo(e.dx + 15, e.dy + 1)
          ..close(),
        Paint()..color = _dark,
      );
    }

    // nose
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(110, 138), width: 12, height: 10),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      Paint()
        ..color = _skinShade
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    // blush
    final blush = Paint()..color = AppColors.neonPink.withValues(alpha: 0.35);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(72, 150), width: 26, height: 14),
      blush,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(148, 150), width: 26, height: 14),
      blush,
    );

    // smile
    final mouth = Path()
      ..moveTo(96, 156)
      ..quadraticBezierTo(110, 172, 124, 156)
      ..quadraticBezierTo(110, 164, 96, 156)
      ..close();
    canvas.drawPath(mouth, Paint()..color = const Color(0xFFC7476F));
    canvas.drawPath(
      Path()
        ..moveTo(99, 157)
        ..quadraticBezierTo(110, 162, 121, 157),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _headphones(Canvas canvas) {
    // band over the top of the hair
    final band = Path()
      ..moveTo(46, 118)
      ..quadraticBezierTo(110, -6, 174, 118);
    canvas.drawPath(
      band,
      Paint()
        ..color = _bandLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      band,
      Paint()
        ..color = AppColors.neonCyan.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round,
    );

    // ear cups
    for (final cx in [44.0, 176.0]) {
      final center = Offset(cx, 122);
      canvas.drawCircle(
        center,
        24,
        Paint()..color = AppColors.neonCyan.withValues(alpha: 0.25),
      );
      final cup = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 34, height: 46),
        const Radius.circular(15),
      );
      canvas.drawRRect(
        cup,
        Paint()
          ..shader = AppGradients.cool.createShader(
            Rect.fromCenter(center: center, width: 34, height: 46),
          ),
      );
      canvas.drawCircle(
        center,
        8,
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
      canvas.drawCircle(
        center,
        8,
        Paint()
          ..color = AppColors.neonBlue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _pendant(Canvas canvas) {
    // little gold music-note charm at the collar
    const c = Offset(110, 222);
    canvas.drawCircle(
      c,
      9,
      Paint()
        ..shader = AppGradients.gold.createShader(
          Rect.fromCircle(center: c, radius: 9),
        ),
    );
    final note = Paint()..color = const Color(0xFF3A2A00);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(107, 225), width: 6, height: 4.5),
      note,
    );
    canvas.drawRect(const Rect.fromLTWH(109, 216, 2, 9), note);
  }

  void _floatingNotes(Canvas canvas) {
    const spots = [
      (Offset(30, 150), 0.0, AppColors.neonCyan),
      (Offset(192, 130), 0.4, AppColors.neonPink),
      (Offset(18, 96), 0.7, AppColors.neonMint),
    ];
    for (final (base, phase, color) in spots) {
      final p = (t + phase) % 1.0;
      final y = base.dy - p * 46;
      final alpha = (math.sin(p * math.pi)).clamp(0.0, 1.0);
      final paint = Paint()..color = color.withValues(alpha: alpha * 0.9);
      final head = Offset(base.dx, y);
      canvas.drawOval(
        Rect.fromCenter(center: head, width: 9, height: 7),
        paint,
      );
      canvas.drawRect(Rect.fromLTWH(head.dx + 3.5, y - 14, 2.2, 15), paint);
      canvas.drawPath(
        Path()
          ..moveTo(head.dx + 5.7, y - 14)
          ..quadraticBezierTo(head.dx + 13, y - 11, head.dx + 6, y - 5),
        Paint()
          ..color = color.withValues(alpha: alpha * 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _sparkles(Canvas canvas) {
    const spots = [
      (Offset(48, 60), 0.0),
      (Offset(176, 66), 0.33),
      (Offset(150, 30), 0.66),
      (Offset(70, 26), 0.5),
    ];
    for (final (c, phase) in spots) {
      final tw = (math.sin((t + phase) * 2 * math.pi) * 0.5 + 0.5);
      final r = 4 + tw * 5;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.4 + tw * 0.6);
      final star = Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
        ..close();
      canvas.drawPath(star, paint);
    }
  }

  @override
  bool shouldRepaint(covariant PianoMusePainter old) => old.t != t;
}
