import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/brand_mark.dart';
import '../widgets/loading_progress.dart';

/// Original branded startup surface driven by real app initialization work.
class SplashScreen extends StatelessWidget {
  const SplashScreen({
    super.key,
    required this.progress,
    required this.status,
    this.error,
    this.onRetry,
  });

  final double progress;
  final String status;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.45),
                radius: 1.25,
                colors: [Color(0xFF211A48), AppColors.bg],
              ),
            ),
          ),
          const Positioned(
            left: -160,
            top: 80,
            child: _AmbientOrb(color: AppColors.neonCyan, size: 310),
          ),
          const Positioned(
            right: -180,
            bottom: 120,
            child: _AmbientOrb(color: AppColors.neonPink, size: 360),
          ),
          const Positioned.fill(child: IgnorePointer(child: _StageGrid())),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  const BrandMark(size: 116),
                  const SizedBox(height: AppSpace.lg),
                  ShaderMask(
                    shaderCallback: AppGradients.aurora.createShader,
                    child: const Text(
                      'PIANO RHYTHM',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 29,
                        height: 1,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'MASTER',
                    style: TextStyle(
                      color: AppColors.textHi,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    'Turn every tap into light.',
                    style: AppTextStyles.bodyMuted.copyWith(
                      color: AppColors.textMid,
                    ),
                  ),
                  const Spacer(flex: 2),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: AnimatedSwitcher(
                      duration: AppMotion.state,
                      child: error == null
                          ? LoadingProgress(
                              key: const ValueKey('progress'),
                              value: progress,
                              status: status,
                            )
                          : _StartupError(
                              key: const ValueKey('error'),
                              message: error!,
                              onRetry: onRetry,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.miss,
            size: 30,
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: AppSpace.md),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 160,
              spreadRadius: 12,
            ),
          ],
        ),
      ),
    );
  }
}

class _StageGrid extends StatelessWidget {
  const _StageGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _StageGridPainter());
  }
}

class _StageGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.neonPurple.withValues(alpha: 0.075)
      ..strokeWidth = 1;
    final horizon = size.height * 0.62;
    for (var i = 0; i <= 8; i++) {
      final x = size.width * i / 8;
      canvas.drawLine(
        Offset(size.width / 2, horizon),
        Offset(x, size.height),
        paint,
      );
    }
    for (var i = 0; i < 6; i++) {
      final t = i / 5;
      final y = horizon + (size.height - horizon) * t * t;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
