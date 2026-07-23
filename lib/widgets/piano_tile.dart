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
    this.sustainHeight = 0,
    this.holdProgress = 0,
    this.isHolding = false,
    this.intensity = 1,
    this.radius = 13,
  });

  final Color color;
  final double bodyHeight;
  final double tailHeight;
  final double sustainHeight;
  final double holdProgress;
  final bool isHolding;
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
            height: tailHeight + sustainHeight + radius,
            child: _tail(),
          ),
        if (sustainHeight > 0)
          Positioned(
            left: 5,
            right: 5,
            top: tailHeight,
            height: sustainHeight + radius,
            child: _sustain(),
          ),
        Positioned(
          left: 0,
          right: 0,
          top: tailHeight + sustainHeight,
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
              colors: [
                Colors.transparent,
                color.withValues(alpha: a),
              ],
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

  Widget _sustain() {
    final pulse = isHolding ? 0.92 : 0.64;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius * 0.7)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.3 + 0.28 * pulse),
          ],
        ),
        border: Border.symmetric(
          vertical: BorderSide(
            color: color.withValues(alpha: 0.5 + 0.35 * pulse),
            width: 1.4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22 + 0.2 * pulse),
            blurRadius: isHolding ? 24 : 14,
            spreadRadius: isHolding ? 2 : -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius * 0.7)),
        child: Stack(
          children: [
            Positioned.fill(
              child: FractionallySizedBox(
                widthFactor: 0.28,
                alignment: Alignment.center,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.05),
                        Colors.white.withValues(alpha: 0.75 * pulse),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.6 * pulse),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            for (var i = 0; i < 4; i++)
              Positioned(
                left: 10,
                right: 10,
                bottom: 12.0 + i * 25,
                child: Center(
                  child: Transform.rotate(
                    angle: 0.785,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: Colors.white.withValues(alpha: 0.34 * pulse),
                            width: 1.4,
                          ),
                          bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.34 * pulse),
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (isHolding)
              Positioned(
                left: 4,
                right: 4,
                bottom: 0,
                height: 7,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: color, blurRadius: 16, spreadRadius: 2),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    return Transform.scale(
      scale: isHolding ? 1.035 : 1,
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(
                color,
                const Color(0xFF181430),
                0.32 - 0.12 * intensity,
              )!,
              isHolding ? const Color(0xFF15102B) : const Color(0xFF0B0917),
            ],
          ),
          border: Border.all(
            color: isHolding
                ? Colors.white.withValues(alpha: 0.9)
                : color.withValues(alpha: 0.6 + 0.4 * intensity),
            width: isHolding ? 2.6 : 1.6 + 0.6 * intensity,
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
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(
                              alpha: isHolding ? 0.5 : 0.14 + 0.2 * intensity,
                            ),
                            color.withValues(alpha: 0.3 + 0.34 * intensity),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    if (sustainHeight > 0)
                      Icon(
                        isHolding
                            ? Icons.keyboard_double_arrow_down_rounded
                            : Icons.touch_app_rounded,
                        color: Colors.white.withValues(alpha: 0.92),
                        size: 23,
                      )
                    else
                      Transform.rotate(
                        angle: 0.785,
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.78),
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(color: color, blurRadius: 12),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: 0.55 + 0.4 * intensity,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
