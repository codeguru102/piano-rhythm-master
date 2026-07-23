import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../data/seed_songs.dart';
import '../models/song.dart';
import '../models/user_profile.dart';
import '../state/profile_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/difficulty_badge.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_button.dart';
import '../widgets/gradient_background.dart';
import '../widgets/gradient_text.dart';
import 'game_screen.dart';
import 'ranking_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onGoTab});

  final ValueChanged<int> onGoTab;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    final featured = kSeedSongs.first;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 124),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopBar(profile: profile, onProfile: () => onGoTab(2)),
                const SizedBox(height: AppSpace.lg),
                _LevelProgress(profile: profile),
                const SizedBox(height: AppSpace.lg),
                _FeaturedSession(
                  song: featured,
                  onPlay: () => Navigator.of(
                    context,
                  ).push(AppRoutes.fadeSlide(GameScreen(song: featured))),
                  onBrowse: () => onGoTab(1),
                ),
                const SizedBox(height: AppSpace.xl),
                const _SectionHeader(
                  title: 'Keep your rhythm',
                  eyebrow: 'YOUR SPACE',
                ),
                const SizedBox(height: AppSpace.md),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.library_music_rounded,
                        label: 'Song library',
                        detail: '${kSeedSongs.length} tracks',
                        color: AppColors.neonCyan,
                        onTap: () => onGoTab(1),
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.leaderboard_rounded,
                        label: 'Your ranking',
                        detail: 'Local board',
                        color: AppColors.neonPink,
                        onTap: () => Navigator.of(
                          context,
                        ).push(AppRoutes.fadeSlide(const RankingScreen())),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.lg),
                _MomentumCard(profile: profile),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.profile, required this.onProfile});

  final UserProfile profile;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Semantics(
          button: true,
          label: 'Open profile',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onProfile,
              customBorder: const CircleBorder(),
              child: Ink(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppGradients.cool,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                  boxShadow: glow(AppColors.neonBlue, blur: 18, opacity: 0.32),
                ),
                child: Center(
                  child: Text(
                    profile.avatar,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('WELCOME BACK', style: AppTextStyles.label),
              const SizedBox(height: 2),
              Text(
                profile.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sectionTitle,
              ),
            ],
          ),
        ),
        _StatChip(
          icon: Icons.stars_rounded,
          label: '${profile.coins}',
          color: AppColors.gold,
          semantics: '${profile.coins} coins',
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.semantics,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String semantics;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semantics,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: color.withValues(alpha: 0.38)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelProgress extends StatelessWidget {
  const _LevelProgress({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final remaining = profile.xpForNextLevel - profile.xpIntoLevel;
    return Semantics(
      label:
          'Level ${profile.level}, ${(profile.levelProgress * 100).round()} percent complete',
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.panel.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                gradient: AppGradients.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${profile.level}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Level progress',
                        style: AppTextStyles.cardTitle,
                      ),
                      const Spacer(),
                      Text('$remaining XP to go', style: AppTextStyles.label),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: profile.levelProgress),
                      duration: AppMotion.reward,
                      curve: AppMotion.standard,
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        backgroundColor: AppColors.interactive,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.neonCyan,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedSession extends StatelessWidget {
  const _FeaturedSession({
    required this.song,
    required this.onPlay,
    required this.onBrowse,
  });

  final Song song;
  final VoidCallback onPlay;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final cover = AppGradients.cover(song.coverSeed);
    final minutes = song.duration ~/ 60;
    final seconds = (song.duration % 60).round().toString().padLeft(2, '0');

    return GlassCard(
      padding: EdgeInsets.zero,
      glowColor: cover.colors.last,
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          cover.colors.first.withValues(alpha: 0.7),
          AppColors.stroke,
          cover.colors.last.withValues(alpha: 0.45),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -52,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    cover.colors.last.withValues(alpha: 0.24),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('QUICK SESSION', style: AppTextStyles.label),
                const SizedBox(height: AppSpace.md),
                Row(
                  children: [
                    _AlbumCover(gradient: cover),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GradientText(
                            song.title,
                            gradient: cover,
                            style: const TextStyle(
                              fontSize: 23,
                              height: 1.1,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(song.artist, style: AppTextStyles.bodyMuted),
                          const SizedBox(height: AppSpace.sm),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              DifficultyBadge(
                                difficulty: song.difficulty,
                                compact: true,
                              ),
                              _Meta(
                                icon: Icons.speed_rounded,
                                text: '${song.bpm} BPM',
                              ),
                              _Meta(
                                icon: Icons.schedule_rounded,
                                text: '$minutes:$seconds',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.lg),
                GlowButton(
                  label: 'Play now',
                  icon: Icons.play_arrow_rounded,
                  height: 58,
                  gradient: cover,
                  glowColor: cover.colors.last,
                  onPressed: onPlay,
                ),
                Center(
                  child: TextButton.icon(
                    onPressed: onBrowse,
                    icon: const Icon(Icons.queue_music_rounded, size: 18),
                    label: const Text('Browse all songs'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 420.ms).slideY(begin: 0.04, end: 0);
  }
}

class _AlbumCover extends StatelessWidget {
  const _AlbumCover({required this.gradient});

  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: Colors.white24),
        boxShadow: glow(gradient.colors.last, blur: 24, opacity: 0.34),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 10,
            right: 10,
            top: 8,
            child: Container(
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.sm),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.38),
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
              size: 42,
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textLow),
        const SizedBox(width: 3),
        Text(text, style: AppTextStyles.label),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.eyebrow});

  final String title;
  final String eyebrow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow, style: AppTextStyles.label),
        const SizedBox(height: 4),
        Text(title, style: AppTextStyles.sectionTitle),
      ],
    );
  }
}

class _ActionCard extends StatefulWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.detail,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String detail;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: AppMotion.touch,
      child: Material(
        color: AppColors.panel.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (value) => setState(() => _pressed = value),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: AppColors.stroke),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 23),
                ),
                const SizedBox(height: AppSpace.md),
                Text(widget.label, style: AppTextStyles.cardTitle),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Expanded(
                      child: Text(widget.detail, style: AppTextStyles.label),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: widget.color,
                      size: 17,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MomentumCard extends StatelessWidget {
  const _MomentumCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your momentum', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              _MomentumStat(
                value: '${profile.totalSongsPlayed}',
                label: 'Songs',
                color: AppColors.neonCyan,
              ),
              _MomentumStat(
                value: '${profile.highestCombo}',
                label: 'Best combo',
                color: AppColors.neonPink,
              ),
              _MomentumStat(
                value: '${profile.bestAccuracy.toStringAsFixed(0)}%',
                label: 'Accuracy',
                color: AppColors.gold,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MomentumStat extends StatelessWidget {
  const _MomentumStat({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 21,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(label, textAlign: TextAlign.center, style: AppTextStyles.label),
        ],
      ),
    );
  }
}
