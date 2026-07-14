import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Large touch-friendly piano lane button with press animation, glossy sheen,
/// gradient fill and neon glow. Fires [onPressed] on pointer-down for
/// low-latency rhythm input.
class PianoButton extends StatefulWidget {
  const PianoButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
    this.flash = 0,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  /// External glow pulse (0..1) driven by a successful hit on this lane.
  final double flash;

  @override
  State<PianoButton> createState() => _PianoButtonState();
}

class _PianoButtonState extends State<PianoButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final active = _down || widget.flash > 0.01;
    final intensity = (_down ? 1.0 : widget.flash).clamp(0.0, 1.0);

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _down = true);
        widget.onPressed();
      },
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: active
                ? [
                    Color.lerp(widget.color, Colors.white, 0.35)!,
                    widget.color,
                  ]
                : [AppColors.panelHi, AppColors.panel],
          ),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: widget.color.withValues(alpha: active ? 1.0 : 0.45),
            width: 1.6,
          ),
          boxShadow: active
              ? glow(widget.color, blur: 12 + 26 * intensity, opacity: 0.7)
              : glow(widget.color, blur: 6, opacity: 0.15),
        ),
        child: Stack(
          children: [
            // top glossy sheen
            Positioned(
              left: 6,
              right: 6,
              top: 5,
              child: Container(
                height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: active ? 0.5 : 0.12),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: active ? Colors.white : widget.color,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  shadows: active
                      ? [Shadow(color: widget.color, blurRadius: 12)]
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
