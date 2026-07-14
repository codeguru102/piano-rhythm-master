import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../models/user_profile.dart';
import '../state/profile_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_button.dart';
import '../widgets/gradient_background.dart';
import '../widgets/gradient_text.dart';
import 'ranking_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onGoTab});

  /// Switch the shell's active tab (0 Home, 1 Library, 2 Profile, 3 Settings).
  final ValueChanged<int> onGoTab;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopBar(profile: profile, onProfile: () => onGoTab(2)),
                const SizedBox(height: AppSpace.xl),
                _HeroCard(onStart: () => onGoTab(1)),
                const SizedBox(height: AppSpace.xl),
                const GradientText(
                  'Quick Play',
                  gradient: AppGradients.aurora,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpace.md),
                _QuickGrid(onGoTab: onGoTab),
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
        GestureDetector(
          onTap: onProfile,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: AppGradients.cool,
              shape: BoxShape.circle,
              boxShadow: glow(AppColors.neonBlue, blur: 14, opacity: 0.5),
            ),
            alignment: Alignment.center,
            child: Text(profile.avatar, style: const TextStyle(fontSize: 24)),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back',
                style: TextStyle(color: AppColors.textMid, fontSize: 12)),
            Text(
              profile.username,
              style: const TextStyle(
                color: AppColors.textHi,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const Spacer(),
        _StatChip(
          icon: Icons.military_tech_rounded,
          label: 'Lv ${profile.level}',
          color: AppColors.neonPurple,
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.stars_rounded,
          label: '${profile.coins}',
          color: AppColors.good,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpace.lg),
      glowColor: AppColors.neonPurple,
      child: Column(
        children: [
          SizedBox(
            width: 132,
            height: 132,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // rotating gradient ring
                Container(
                  width: 132,
                  height: 132,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(colors: [
                      AppColors.neonCyan,
                      AppColors.neonBlue,
                      AppColors.neonPurple,
                      AppColors.neonPink,
                      AppColors.neonCyan,
                    ]),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .rotate(duration: 6000.ms),
                Container(
                  width: 116,
                  height: 116,
                  decoration:
                      const BoxDecoration(shape: BoxShape.circle, color: AppColors.bgElevated),
                ),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: AppGradients.royal,
                    shape: BoxShape.circle,
                    boxShadow: glow(AppColors.neonPink, blur: 36, opacity: 0.6),
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 54),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      duration: 1200.ms,
                      begin: const Offset(1, 1),
                      end: const Offset(1.07, 1.07),
                      curve: Curves.easeInOut,
                    ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
          const _Equalizer(),
          const SizedBox(height: AppSpace.md),
          const Text('Ready to play?',
              style: TextStyle(color: AppColors.textMid, fontSize: 14)),
          const SizedBox(height: AppSpace.md),
          GlowButton(
            label: 'START GAME',
            icon: Icons.music_note_rounded,
            fontSize: 18,
            height: 60,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

/// Decorative animated music equalizer bars.
class _Equalizer extends StatelessWidget {
  const _Equalizer();

  @override
  Widget build(BuildContext context) {
    const colors = kLaneColors;
    final durations = [520, 380, 640, 300, 460, 560, 340];
    return SizedBox(
      height: 34,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < durations.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                width: 7,
                height: 34,
                decoration: BoxDecoration(
                  color: colors[i % colors.length],
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: glow(colors[i % colors.length],
                      blur: 8, opacity: 0.5),
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleY(
                    begin: 0.25,
                    end: 1.0,
                    alignment: Alignment.bottomCenter,
                    duration: durations[i].ms,
                    curve: Curves.easeInOut,
                  ),
            ),
        ],
      ),
    );
  }
}

class _QuickGrid extends StatelessWidget {
  const _QuickGrid({required this.onGoTab});

  final ValueChanged<int> onGoTab;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      (
        Icons.library_music_rounded,
        'Songs',
        AppGradients.cool,
        () => onGoTab(1)
      ),
      (
        Icons.leaderboard_rounded,
        'Ranking',
        AppGradients.primary,
        () => Navigator.of(context).push(AppRoutes.fadeSlide(const RankingScreen()))
      ),
      (Icons.person_rounded, 'Profile', AppGradients.cool, () => onGoTab(2)),
      (Icons.settings_rounded, 'Settings', AppGradients.primary, () => onGoTab(3)),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpace.md,
      crossAxisSpacing: AppSpace.md,
      childAspectRatio: 1.7,
      children: [
        for (final t in tiles)
          _QuickTile(icon: t.$1, label: t.$2, gradient: t.$3, onTap: t.$4),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
          gradient: AppGradients.panel,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textHi,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
