import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/achievement.dart';
import '../models/user_profile.dart';
import '../state/profile_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';
import '../widgets/gradient_text.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _avatars = ['🎧', '🎹', '🎸', '🎤', '🥁', '🎺', '🦊', '🐼', '👾', '⭐'];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final p = provider.profile;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headerCard(context, provider, p),
                const SizedBox(height: AppSpace.lg),
                const _SectionTitle('Statistics'),
                const SizedBox(height: AppSpace.md),
                _statsGrid(p),
                const SizedBox(height: AppSpace.lg),
                const _SectionTitle('Achievements'),
                const SizedBox(height: AppSpace.md),
                _achievements(p),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerCard(
      BuildContext context, ProfileProvider provider, UserProfile p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        gradient: AppGradients.panel,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _pickAvatar(context, provider),
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                shape: BoxShape.circle,
                boxShadow: glow(AppColors.neonPurple, blur: 28, opacity: 0.55),
              ),
              alignment: Alignment.center,
              child: Text(p.avatar, style: const TextStyle(fontSize: 44)),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          GestureDetector(
            onTap: () => _editName(context, provider, p),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  p.username,
                  style: const TextStyle(
                      color: AppColors.textHi,
                      fontSize: 22,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.edit_rounded,
                    color: AppColors.textLow, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text('Level ${p.level}  •  ${p.experience} XP',
              style: const TextStyle(color: AppColors.textMid, fontSize: 14)),
          const SizedBox(height: AppSpace.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              value: p.levelProgress,
              minHeight: 8,
              backgroundColor: AppColors.bg,
              valueColor: const AlwaysStoppedAnimation(AppColors.neonPink),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${p.xpIntoLevel} / ${p.xpForNextLevel} XP to Level ${p.level + 1}',
            style: const TextStyle(color: AppColors.textLow, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _statsGrid(UserProfile p) {
    final stats = [
      (Icons.queue_music_rounded, 'Songs Played', '${p.totalSongsPlayed}',
          AppColors.neonBlue),
      (Icons.emoji_events_rounded, 'Highest Score', '${p.highestScore}',
          AppColors.good),
      (Icons.bolt_rounded, 'Best Combo', '${p.highestCombo}',
          AppColors.neonPink),
      (Icons.percent_rounded, 'Best Accuracy',
          '${p.bestAccuracy.toStringAsFixed(1)}%', AppColors.neonCyan),
      (Icons.favorite_rounded, 'Favorites', '${p.favorites.length}',
          AppColors.neonPurple),
      (Icons.stars_rounded, 'Coins', '${p.coins}', AppColors.expert),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpace.md,
      crossAxisSpacing: AppSpace.md,
      childAspectRatio: 1.9,
      children: [
        for (final s in stats)
          Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              gradient: AppGradients.panel,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.stroke),
            ),
            child: Row(
              children: [
                Icon(s.$1, color: s.$4, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(s.$3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textHi,
                              fontSize: 17,
                              fontWeight: FontWeight.w600)),
                      Text(s.$2,
                          style: const TextStyle(
                              color: AppColors.textMid, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _achievements(UserProfile p) {
    return Column(
      children: [
        for (final a in kAchievements)
          _achievementTile(a, p.achievements.contains(a.id)),
      ],
    );
  }

  Widget _achievementTile(Achievement a, bool unlocked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
            color: unlocked ? a.color.withValues(alpha: 0.5) : AppColors.stroke),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: unlocked
                  ? a.color.withValues(alpha: 0.18)
                  : AppColors.panelHi,
              shape: BoxShape.circle,
            ),
            child: Icon(unlocked ? a.icon : Icons.lock_rounded,
                color: unlocked ? a.color : AppColors.textLow, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title,
                    style: TextStyle(
                        color: unlocked ? AppColors.textHi : AppColors.textMid,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                Text(a.description,
                    style: const TextStyle(
                        color: AppColors.textLow, fontSize: 12)),
              ],
            ),
          ),
          if (unlocked)
            const Icon(Icons.check_circle_rounded,
                color: AppColors.easy, size: 22),
        ],
      ),
    );
  }

  void _pickAvatar(BuildContext context, ProfileProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final emoji in _avatars)
              GestureDetector(
                onTap: () {
                  provider.updateIdentity(avatar: emoji);
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.panelHi,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.stroke),
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _editName(
      BuildContext context, ProfileProvider provider, UserProfile p) {
    final controller = TextEditingController(text: p.username);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.panel,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg)),
        title: const Text('Edit Username',
            style: TextStyle(color: AppColors.textHi, fontSize: 18)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textHi),
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.stroke)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.neonPurple)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMid)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) provider.updateIdentity(username: name);
              Navigator.of(context).pop();
            },
            child: const Text('Save',
                style: TextStyle(color: AppColors.neonPurple)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return GradientText(text,
        gradient: AppGradients.aurora,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600));
  }
}
