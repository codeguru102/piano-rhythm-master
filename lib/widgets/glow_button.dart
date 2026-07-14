import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';

/// A glowing, gradient, press-animated button with a periodic shine sweep —
/// the app's primary dazzling CTA style.
class GlowButton extends StatefulWidget {
  const GlowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.gradient = AppGradients.royal,
    this.icon,
    this.height = 58,
    this.expand = true,
    this.fontSize = 17,
    this.glowColor,
    this.shine = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final LinearGradient gradient;
  final IconData? icon;
  final double height;
  final bool expand;
  final double fontSize;
  final Color? glowColor;
  final bool shine;

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final glowClr = widget.glowColor ?? widget.gradient.colors[1];

    Widget container = Container(
      height: widget.height,
      width: widget.expand ? double.infinity : null,
      padding:
          widget.expand ? null : const EdgeInsets.symmetric(horizontal: 26),
      decoration: BoxDecoration(
        gradient: widget.gradient,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        boxShadow: enabled
            ? glow(glowClr, blur: _down ? 14 : 30, opacity: 0.6)
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, color: Colors.white, size: widget.fontSize + 5),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              widget.label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                shadows: const [Shadow(color: Colors.black26, blurRadius: 4)],
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.shine && enabled) {
      container = container
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            duration: 2400.ms,
            delay: 1200.ms,
            color: Colors.white.withValues(alpha: 0.35),
          );
    }

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _down = false);
              widget.onPressed!();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.5,
          duration: const Duration(milliseconds: 150),
          child: container,
        ),
      ),
    );
  }
}
