import 'package:flutter/material.dart';

/// A falling piano tile with a glowing "comet" motion tail above it.
///
/// The tail is a soft color→transparent gradient (plus a brighter centre
/// streak) — it reads as a blurred motion trail but uses only cheap gradient
/// fills (NO per-frame MaskFilter.blur, which caused jank on software GPUs).
/// The body is a glossy dark tile with a neon edge glow and a hot leading edge.
/// [intensity] (0..1) brightens the glow as the tile nears the bottom.
class PianoTile extends StatelessWidget {
  const PianoTile({
    super.key,
    required this.color,
    required this.bodyHeight,
    this.tailHeight = 0,
    this.intensity = 1,
    this.radius = 13,
  });

  final Color color;
  final double bodyHeight;
  final double tailHeight;
  final double intensity;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (tailHeight > 0)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: tailHeight + radius,
            child: _tail(),
          ),
        Positioned(
          left: 0,
          right: 0,
          top: tailHeight,
          height: bodyHeight,
          child: _body(),
        ),
      ],
    );
  }

  Widget _tail() {
    final a = 0.16 + 0.12 * intensity;
    return Stack(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, color.withValues(alpha: a)],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            widthFactor: 0.5,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    color.withValues(alpha: 0.45 + 0.25 * intensity),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _body() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(color, const Color(0xFF181430), 0.32 - 0.12 * intensity)!,
            const Color(0xFF0B0917),
          ],
        ),
        border: Border.all(
          color: color.withValues(alpha: 0.6 + 0.4 * intensity),
          width: 1.6 + 0.6 * intensity,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3 + 0.4 * intensity),
            blurRadius: 10 + 16 * intensity,
            spreadRadius: -3 + 2 * intensity,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                widthFactor: 1,
                heightFactor: 0.5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: FractionallySizedBox(
                widthFactor: 0.55,
                heightFactor: 0.55,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color.withValues(alpha: 0.35 + 0.35 * intensity),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55 + 0.4 * intensity),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
