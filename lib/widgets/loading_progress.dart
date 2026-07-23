import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppLinearProgress extends StatelessWidget {
  const AppLinearProgress({super.key, required this.value, this.height = 7});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final target = value.clamp(0.0, 1.0);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: target),
      duration: reduceMotion ? Duration.zero : AppMotion.state,
      curve: AppMotion.standard,
      builder: (context, animatedValue, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: SizedBox(
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: AppColors.interactive),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: animatedValue,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(gradient: AppGradients.aurora),
                  ),
                ),
                if (animatedValue > 0.02 && animatedValue < 0.995)
                  Align(
                    alignment: Alignment(animatedValue * 2 - 1, 0),
                    child: Container(
                      width: height,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: glow(
                          AppColors.neonCyan,
                          blur: 12,
                          opacity: 0.9,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Branded, accessible progress block used by startup and future song loading.
class LoadingProgress extends StatefulWidget {
  const LoadingProgress({
    super.key,
    required this.value,
    required this.status,
    this.supportingText = 'Headphones reveal every detail.',
  });

  final double value;
  final String status;
  final String supportingText;

  @override
  State<LoadingProgress> createState() => _LoadingProgressState();
}

class _LoadingProgressState extends State<LoadingProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _equalizer;

  @override
  void initState() {
    super.initState();
    _equalizer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _equalizer.stop();
      _equalizer.value = 0.45;
    } else if (!_equalizer.isAnimating) {
      _equalizer.repeat();
    }
  }

  @override
  void dispose() {
    _equalizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percent = (widget.value.clamp(0.0, 1.0) * 100).round();
    return Semantics(
      liveRegion: true,
      label: '${widget.status}, $percent percent',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppMotion.state,
                  child: Text(
                    widget.status,
                    key: ValueKey(widget.status),
                    style: AppTextStyles.bodyMuted.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(end: widget.value.clamp(0.0, 1.0)),
                duration: AppMotion.state,
                builder: (context, value, _) => Text(
                  '${(value * 100).round()}%',
                  style: AppTextStyles.cardTitle.copyWith(
                    color: AppColors.neonCyan,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          AppLinearProgress(value: widget.value),
          const SizedBox(height: AppSpace.lg),
          SizedBox(
            height: 26,
            child: AnimatedBuilder(
              animation: _equalizer,
              builder: (context, _) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) {
                  final wave = math.sin(
                    _equalizer.value * math.pi * 2 + index * 0.9,
                  );
                  final height = 7 + ((wave + 1) / 2) * 17;
                  return Container(
                    width: 4,
                    height: height,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                      color: kLaneColors[index % kLaneColors.length].withValues(
                        alpha: 0.85,
                      ),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            widget.supportingText,
            textAlign: TextAlign.center,
            style: AppTextStyles.label,
          ),
        ],
      ),
    );
  }
}
