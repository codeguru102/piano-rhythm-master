import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';

/// Primary product action with accessible focus, keyboard, and press states.
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
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final glowColor = widget.glowColor ?? widget.gradient.colors.last;

    Widget surface = Container(
      height: widget.height,
      width: widget.expand ? double.infinity : null,
      padding: widget.expand
          ? null
          : const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      decoration: BoxDecoration(
        gradient: enabled ? widget.gradient : null,
        color: enabled ? null : AppColors.interactive,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: enabled
              ? Colors.white.withValues(alpha: 0.22)
              : AppColors.stroke,
        ),
        boxShadow: enabled
            ? glow(
                glowColor,
                blur: _pressed ? 12 : 22,
                opacity: _pressed ? 0.18 : 0.34,
              )
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, color: Colors.white, size: widget.fontSize + 4),
            const SizedBox(width: AppSpace.xs),
          ],
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: enabled ? Colors.white : AppColors.textLow,
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.25,
              ),
            ),
          ),
        ],
      ),
    );

    // A single entrance sweep adds polish without permanent visual noise.
    if (widget.shine && enabled && !reduceMotion) {
      surface = surface.animate().shimmer(
        delay: 480.ms,
        duration: 850.ms,
        color: Colors.white.withValues(alpha: 0.3),
      );
    }

    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: widget.label,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            canRequestFocus: enabled,
            borderRadius: BorderRadius.circular(AppRadii.md),
            onHighlightChanged: (highlighted) {
              if (_pressed == highlighted) return;
              setState(() => _pressed = highlighted);
            },
            child: AnimatedScale(
              scale: _pressed ? 0.97 : 1,
              duration: reduceMotion ? Duration.zero : AppMotion.touch,
              curve: AppMotion.standard,
              child: AnimatedOpacity(
                opacity: enabled ? 1 : 0.55,
                duration: AppMotion.state,
                child: surface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
