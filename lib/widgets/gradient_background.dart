import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Animated dark stage backdrop: slowly drifting neon aurora blobs plus a field
/// of floating, glowing note particles rising behind the content.
class GradientBackground extends StatefulWidget {
  const GradientBackground({
    super.key,
    required this.child,
    this.particleCount = 12,
  });

  final Widget child;
  final int particleCount;

  @override
  State<GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<GradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Particle> _particles;

  static const _palette = [
    AppColors.neonPurple,
    AppColors.neonPink,
    AppColors.neonBlue,
    AppColors.neonCyan,
    AppColors.gold,
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
    final rnd = math.Random(7);
    _particles = List.generate(widget.particleCount, (i) {
      return _Particle(
        x: rnd.nextDouble(),
        phase: rnd.nextDouble(),
        speed: 0.4 + rnd.nextDouble() * 0.9,
        size: 2.0 + rnd.nextDouble() * 4.5,
        sway: 0.02 + rnd.nextDouble() * 0.06,
        color: _palette[i % _palette.length],
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _ctrl.stop();
      _ctrl.value = 0.2;
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.stage),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value * 2 * math.pi;
          return Stack(
            children: [
              _blob(
                AppColors.neonPurple.withValues(alpha: 0.14),
                260,
                Alignment(
                  -0.8 + 0.25 * math.sin(t),
                  -0.75 + 0.18 * math.cos(t),
                ),
              ),
              _blob(
                AppColors.neonBlue.withValues(alpha: 0.12),
                320,
                Alignment(
                  0.85 + 0.2 * math.cos(t * 0.8),
                  0.8 + 0.16 * math.sin(t),
                ),
              ),
              _blob(
                AppColors.neonPink.withValues(alpha: 0.09),
                240,
                Alignment(0.2 * math.sin(t * 1.3), 0.1 * math.cos(t)),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ParticlePainter(_particles, _ctrl.value),
                  ),
                ),
              ),
              Positioned.fill(child: widget.child),
            ],
          );
        },
      ),
    );
  }

  Widget _blob(Color color, double size, Alignment align) {
    return Align(
      alignment: align,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color, blurRadius: 170, spreadRadius: 50),
            ],
          ),
        ),
      ),
    );
  }
}

class _Particle {
  final double x, phase, speed, size, sway;
  final Color color;
  const _Particle({
    required this.x,
    required this.phase,
    required this.speed,
    required this.size,
    required this.sway,
    required this.color,
  });
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.particles, this.t);

  final List<_Particle> particles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final prog = (p.phase + t * p.speed) % 1.0;
      final y = size.height * (1.0 - prog);
      final x = size.width * (p.x + p.sway * math.sin(prog * 2 * math.pi * 2));
      final fade = math.sin(prog * math.pi); // fade in/out at edges
      final paint = Paint()
        ..color = p.color.withValues(alpha: 0.35 * fade)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 1.6);
      canvas.drawCircle(Offset(x, y), p.size, paint);
      canvas.drawCircle(
        Offset(x, y),
        p.size * 0.5,
        Paint()..color = p.color.withValues(alpha: 0.55 * fade),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}
