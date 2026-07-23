import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Gameplay HUD: score, combo and accuracy. Custom reusable component.
class ScoreDisplay extends StatelessWidget {
  const ScoreDisplay({
    super.key,
    required this.score,
    required this.combo,
    required this.accuracy,
    required this.multiplier,
  });

  final int score;
  final int combo;
  final double accuracy;
  final double multiplier;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _formatScore(score),
          style: const TextStyle(
            color: AppColors.textHi,
            fontSize: 40,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _chip(
              Icons.percent_rounded,
              '${accuracy.toStringAsFixed(1)}%',
              AppColors.neonCyan,
            ),
            const SizedBox(width: 12),
            _combo(),
          ],
        ),
      ],
    );
  }

  Widget _combo() {
    final on = combo > 1;
    return AnimatedScale(
      scale: on ? 1.0 : 0.9,
      duration: const Duration(milliseconds: 150),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bolt_rounded,
            color: on ? AppColors.neonPink : AppColors.textLow,
            size: 18,
          ),
          const SizedBox(width: 2),
          Text(
            on ? '$combo combo' : '—',
            style: TextStyle(
              color: on ? AppColors.neonPink : AppColors.textLow,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (multiplier > 1) ...[
            const SizedBox(width: 6),
            Text(
              '×${multiplier.toStringAsFixed(1)}',
              style: const TextStyle(
                color: AppColors.good,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  static String _formatScore(int score) {
    final s = score.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
