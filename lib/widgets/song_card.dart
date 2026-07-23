import 'package:flutter/material.dart';

import '../models/song.dart';
import '../theme/app_theme.dart';
import 'difficulty_badge.dart';

/// Product song card with clear metadata and responsive touch/hover states.
class SongCard extends StatefulWidget {
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
  State<SongCard> createState() => _SongCardState();
}

class _SongCardState extends State<SongCard> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    final cover = AppGradients.cover(song.coverSeed);
    final accent = cover.colors.last;

    return Semantics(
      button: true,
      label: 'Play ${song.title} by ${song.artist}',
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: AppMotion.touch,
        curve: AppMotion.standard,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPlay,
              onHighlightChanged: (value) => setState(() => _pressed = value),
              borderRadius: BorderRadius.circular(AppRadii.lg),
              child: AnimatedContainer(
                duration: AppMotion.state,
                curve: AppMotion.standard,
                margin: const EdgeInsets.only(bottom: AppSpace.sm),
                padding: const EdgeInsets.all(1.2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cover.colors.first.withValues(
                        alpha: _hovered ? 0.78 : 0.5,
                      ),
                      AppColors.stroke,
                      accent.withValues(alpha: _hovered ? 0.6 : 0.32),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  boxShadow: glow(
                    accent,
                    blur: _hovered ? 26 : 16,
                    opacity: _hovered ? 0.24 : 0.12,
                  ),
                ),
                child: Ink(
                  padding: const EdgeInsets.all(AppSpace.sm),
                  decoration: BoxDecoration(
                    color: AppColors.panel.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(AppRadii.lg - 1),
                  ),
                  child: Row(
                    children: [
                      _Cover(gradient: cover),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: _Info(song: song, bestScore: widget.bestScore),
                      ),
                      const SizedBox(width: AppSpace.xs),
                      _Controls(
                        isFavorite: widget.isFavorite,
                        accent: accent,
                        onFavorite: widget.onToggleFavorite,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.gradient});

  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 86,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: Colors.white24),
        boxShadow: glow(gradient.colors.last, blur: 18, opacity: 0.32),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 7,
            right: 7,
            top: 6,
            child: Container(
              height: 25,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.sm),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.36),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          const Center(
            child: Icon(
              Icons.graphic_eq_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.song, required this.bestScore});

  final Song song;
  final int bestScore;

  @override
  Widget build(BuildContext context) {
    final minutes = song.duration ~/ 60;
    final seconds = (song.duration % 60).round().toString().padLeft(2, '0');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.cardTitle,
        ),
        const SizedBox(height: 3),
        Text(
          song.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyMuted,
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 7,
          runSpacing: 5,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DifficultyBadge(difficulty: song.difficulty, compact: true),
            _TinyMeta(icon: Icons.speed_rounded, label: '${song.bpm}'),
            _TinyMeta(icon: Icons.schedule_rounded, label: '$minutes:$seconds'),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Icon(
              bestScore > 0 ? Icons.emoji_events_rounded : Icons.auto_awesome,
              color: bestScore > 0 ? AppColors.gold : AppColors.textLow,
              size: 14,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                bestScore > 0 ? 'Best $bestScore' : 'New challenge',
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TinyMeta extends StatelessWidget {
  const _TinyMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textLow, size: 13),
        const SizedBox(width: 2),
        Text(label, style: AppTextStyles.label),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.isFavorite,
    required this.accent,
    required this.onFavorite,
  });

  final bool isFavorite;
  final Color accent;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: isFavorite ? 'Remove from favorites' : 'Add to favorites',
          child: IconButton(
            onPressed: onFavorite,
            visualDensity: VisualDensity.compact,
            icon: AnimatedSwitcher(
              duration: AppMotion.state,
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                key: ValueKey(isFavorite),
                color: isFavorite ? AppColors.neonPink : AppColors.textLow,
                size: 21,
              ),
            ),
          ),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: AppGradients.royal,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
            boxShadow: glow(accent, blur: 17, opacity: 0.42),
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ],
    );
  }
}
