import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A milestone the player can unlock. Evaluated locally against profile stats.
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

const List<Achievement> kAchievements = [
  Achievement(
    id: 'first_song',
    title: 'First Notes',
    description: 'Complete your first song',
    icon: Icons.music_note_rounded,
    color: AppColors.neonBlue,
  ),
  Achievement(
    id: 'combo_50',
    title: 'On Fire',
    description: 'Reach a 50 combo',
    icon: Icons.local_fire_department_rounded,
    color: AppColors.neonPink,
  ),
  Achievement(
    id: 'combo_100',
    title: 'Unstoppable',
    description: 'Reach a 100 combo',
    icon: Icons.bolt_rounded,
    color: AppColors.good,
  ),
  Achievement(
    id: 'accuracy_95',
    title: 'Precision',
    description: 'Finish a song with 95% accuracy',
    icon: Icons.center_focus_strong_rounded,
    color: AppColors.perfect,
  ),
  Achievement(
    id: 'score_50k',
    title: 'High Roller',
    description: 'Score 50,000 in a single song',
    icon: Icons.emoji_events_rounded,
    color: AppColors.neonPurple,
  ),
  Achievement(
    id: 'level_5',
    title: 'Rising Star',
    description: 'Reach level 5',
    icon: Icons.star_rounded,
    color: AppColors.expert,
  ),
];
