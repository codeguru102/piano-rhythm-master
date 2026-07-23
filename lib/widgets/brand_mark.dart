import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Original four-key mark used for Piano Rhythm Master's product identity.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 112, this.showGlow = true});

  final double size;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Piano Rhythm Master',
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1D2443), Color(0xFF0C1020)],
            ),
            border: Border.all(color: AppColors.strokeStrong),
            boxShadow: showGlow
                ? [
                    BoxShadow(
                      color: AppColors.neonPurple.withValues(alpha: 0.3),
                      blurRadius: size * 0.5,
                      spreadRadius: -size * 0.14,
                    ),
                    BoxShadow(
                      color: AppColors.neonCyan.withValues(alpha: 0.18),
                      blurRadius: size * 0.4,
                      spreadRadius: -size * 0.12,
                    ),
                  ]
                : null,
          ),
          child: CustomPaint(painter: _BrandMarkPainter()),
        ),
      ),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = size.width * 0.18;
    final available = size.width - inset * 2;
    final gap = size.width * 0.045;
    final keyWidth = (available - gap * 3) / 4;
    final floor = size.height * 0.78;
    const heights = [0.46, 0.66, 0.82, 0.56];
    const colors = kLaneColors;

    for (var i = 0; i < 4; i++) {
      final left = inset + i * (keyWidth + gap);
      final top = floor - size.height * heights[i];
      final keyRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(left, top, left + keyWidth, floor),
        Radius.circular(keyWidth * 0.34),
      );
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors[i].withValues(alpha: 0.95),
            colors[i].withValues(alpha: 0.45),
          ],
        ).createShader(rect);
      canvas.drawRRect(keyRect, paint);

      final highlight = Paint()..color = Colors.white.withValues(alpha: 0.72);
      canvas.drawCircle(
        Offset(left + keyWidth / 2, top + keyWidth * 0.52),
        math.max(1.4, size.width * 0.018),
        highlight,
      );
    }

    final baseline = Paint()
      ..shader = AppGradients.aurora.createShader(rect)
      ..strokeWidth = math.max(2, size.width * 0.025)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(inset, floor + size.height * 0.07),
      Offset(size.width - inset, floor + size.height * 0.07),
      baseline,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
