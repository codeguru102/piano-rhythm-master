import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A short, arcade-style timing callout with a three-stage motion:
/// impact, readable hold, then an upward dissolve.
class JudgmentBurst extends StatefulWidget {
  const JudgmentBurst({
    super.key,
    required this.label,
    required this.subtitle,
    required this.color,
    this.isMiss = false,
  });

  final String label;
  final String subtitle;
  final Color color;
  final bool isMiss;

  @override
  State<JudgmentBurst> createState() => _JudgmentBurstState();
}

class _JudgmentBurstState extends State<JudgmentBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 330,
      height: 112,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final enter = Curves.elasticOut.transform((t / 0.38).clamp(0, 1));
          final exit = Curves.easeInCubic.transform(
            ((t - 0.68) / 0.32).clamp(0, 1),
          );
          final opacity = (1 - exit).clamp(0.0, 1.0);
          final shake = widget.isMiss
              ? math.sin(t * math.pi * 12) * 8 * (1 - t)
              : math.sin(t * math.pi * 2.5) * 1.5 * (1 - t);
          final scale = 0.42 + 0.58 * enter;
          final angle = (widget.isMiss ? -0.055 : 0.035) * (1 - enter);

          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(shake, -20 * exit),
              child: Transform.rotate(
                angle: angle,
                child: Transform.scale(
                  scale: scale,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(310, 100),
                        painter: _AccentPainter(
                          progress: t,
                          color: widget.color,
                          isMiss: widget.isMiss,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(
                                widget.label,
                                style: TextStyle(
                                  fontSize: 40,
                                  height: 0.98,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: 1.5 + 3.5 * exit,
                                  foreground: Paint()
                                    ..style = PaintingStyle.stroke
                                    ..strokeWidth = 6
                                    ..color = const Color(0xFF090615),
                                ),
                              ),
                              ShaderMask(
                                blendMode: BlendMode.srcIn,
                                shaderCallback: (bounds) => LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white,
                                    Color.lerp(
                                      Colors.white,
                                      widget.color,
                                      0.35,
                                    )!,
                                    widget.color,
                                  ],
                                  stops: const [0, 0.34, 1],
                                ).createShader(bounds),
                                child: Text(
                                  widget.label,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 40,
                                    height: 0.98,
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                    letterSpacing: 1.5 + 3.5 * exit,
                                    shadows: [
                                      Shadow(
                                        color: widget.color.withValues(
                                          alpha: 0.9,
                                        ),
                                        blurRadius: 18 + 10 * enter,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 5,
                                child: Text(
                                  widget.label,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.58),
                                    fontSize: 40,
                                    height: 0.98,
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                    letterSpacing: 1.5 + 3.5 * exit,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xCC090615),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: widget.color.withValues(alpha: 0.65),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.color.withValues(alpha: 0.25),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: Text(
                              widget.subtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 9,
                                height: 1,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AccentPainter extends CustomPainter {
  const _AccentPainter({
    required this.progress,
    required this.color,
    required this.isMiss,
  });

  final double progress;
  final Color color;
  final bool isMiss;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.43);
    final burst = Curves.easeOutCubic.transform((progress / 0.45).clamp(0, 1));
    final fade = (1 - ((progress - 0.5) / 0.5).clamp(0, 1)).toDouble();
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.plus;

    for (var i = 0; i < 12; i++) {
      final angle = i / 12 * math.pi * 2 + (isMiss ? 0.15 : -0.08);
      final inner = 108.0 + (i.isEven ? 4 : 0);
      final outer = inner + (18 + (i % 3) * 7) * burst;
      final direction = Offset(math.cos(angle), math.sin(angle));
      paint
        ..color = (i.isEven ? Colors.white : color).withValues(
          alpha: 0.55 * fade,
        )
        ..strokeWidth = i.isEven ? 2.2 : 3.2;
      canvas.drawLine(
        center + direction * inner,
        center + direction * outer,
        paint,
      );
    }

    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * fade
      ..color = color.withValues(alpha: 0.65 * fade);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 235 * burst, height: 66 * burst),
      paint,
    );
  }

  @override
  bool shouldRepaint(_AccentPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
