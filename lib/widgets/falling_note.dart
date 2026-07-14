import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Visual for a single falling note — a glowing gem-like bar with a comet
/// trail fading upward and a bright leading edge. Pure presentation.
class FallingNote extends StatelessWidget {
  const FallingNote({
    super.key,
    required this.color,
    required this.width,
    required this.height,
  });

  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // comet trail extending upward
          Positioned(
            left: width * 0.28,
            right: width * 0.28,
            bottom: height * 0.4,
            top: -height * 1.1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.sm),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withValues(alpha: 0), color.withValues(alpha: 0.4)],
                ),
              ),
            ),
          ),
          // note head
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(color, Colors.white, 0.45)!,
                  color,
                  Color.lerp(color, Colors.black, 0.15)!,
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.2),
              boxShadow: glow(color, blur: 18, opacity: 0.85),
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.fromLTRB(5, 3, 5, 0),
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
