import 'package:flutter/material.dart';

import '../models/song.dart';
import '../theme/app_theme.dart';
import 'difficulty_badge.dart';
import 'gradient_text.dart';

/// Reusable song list card: gradient-bordered glass panel with a glowing cover,
/// title, artist, difficulty, best score, favorite and play controls.
class SongCard extends StatelessWidget {
  const SongCard({
    super.key,
    required this.song,
    required this.bestScore,
    required this.isFavorite,
    required this.onPlay,
    required this.onToggleFavorite,
  });

  final Song song;
  final int bestScore;
  final bool isFavorite;
  final VoidCallback onPlay;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final coverGrad = AppGradients.cover(song.coverSeed);
    return GestureDetector(
      onTap: onPlay,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpace.md),
        padding: const EdgeInsets.all(1.4), // gradient border
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              coverGrad.colors.first.withValues(alpha: 0.7),
              coverGrad.colors.last.withValues(alpha: 0.4),
              AppColors.stroke,
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          boxShadow: glow(coverGrad.colors.last, blur: 16, opacity: 0.18),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpace.sm + 2),
          decoration: BoxDecoration(
            gradient: AppGradients.panel,
            borderRadius: BorderRadius.circular(AppRadii.lg - 1),
          ),
          child: Row(
            children: [
              _cover(coverGrad),
              const SizedBox(width: AppSpace.md),
              Expanded(child: _info(coverGrad)),
              _controls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cover(LinearGradient coverGrad) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        gradient: coverGrad,
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: glow(coverGrad.colors.last, blur: 18, opacity: 0.5),
      ),
      child: Stack(
        children: [
          // glossy shine
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
                    Colors.white.withValues(alpha: 0.4),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          const Center(
            child: Icon(Icons.music_note_rounded, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _info(LinearGradient coverGrad) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GradientText(
          song.title,
          gradient: coverGrad,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          song.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textMid, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            DifficultyBadge(difficulty: song.difficulty, compact: true),
            const SizedBox(width: 8),
            if (bestScore > 0) ...[
              const Icon(Icons.star_rounded, color: AppColors.gold, size: 14),
              const SizedBox(width: 2),
              Text('$bestScore',
                  style: const TextStyle(
                      color: AppColors.textMid,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ] else
              const Text('No score yet',
                  style: TextStyle(color: AppColors.textLow, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _controls() {
    return Column(
      children: [
        GestureDetector(
          onTap: onToggleFavorite,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFavorite ? AppColors.neonPink : AppColors.textLow,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: AppGradients.royal,
            shape: BoxShape.circle,
            boxShadow: glow(AppColors.neonPink, blur: 16, opacity: 0.6),
          ),
          child: const Icon(Icons.play_arrow_rounded,
              color: Colors.white, size: 26),
        ),
      ],
    );
  }
}
