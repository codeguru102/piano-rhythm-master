import 'package:flutter/material.dart';

import '../models/song.dart';
import '../theme/app_theme.dart';

/// Colored difficulty pill (Easy/Normal/Hard/Expert).
class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({super.key, required this.difficulty, this.compact = false});

  final Difficulty difficulty;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = difficulty.color;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 11, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: c.withValues(alpha: 0.6)),
      ),
      child: Text(
        difficulty.label.toUpperCase(),
        style: TextStyle(
          color: c,
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
