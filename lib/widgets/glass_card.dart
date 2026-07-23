import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Elevated product surface. Accent borders and glow are opt-in.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.md),
    this.radius = AppRadii.lg,
    this.borderGradient = AppGradients.surfaceBorder,
    this.glowColor,
    this.blur = 14,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Gradient borderGradient;
  final Color? glowColor;
  final double blur;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: borderGradient,
        boxShadow: glowColor == null
            ? null
            : glow(glowColor!, blur: 24, opacity: 0.35),
      ),
      padding: const EdgeInsets.all(1.3), // gradient border thickness
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius - 1),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.panelHi.withValues(alpha: 0.82),
                  AppColors.panel.withValues(alpha: 0.92),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap == null) return content;
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: content,
        ),
      ),
    );
  }
}
