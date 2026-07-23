import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../data/game_repository.dart';
import '../models/achievement.dart';
import '../models/score_result.dart';
import '../models/song.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_button.dart';
import '../widgets/gradient_background.dart';
import '../widgets/gradient_text.dart';
import 'game_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.song,
    required this.result,
    this.unlocked = const [],
    this.gameOver = false,
  });

  final Song song;
  final ScoreResult result;
  final List<Achievement> unlocked;

  /// True when a classic run ended on a mistake (shows a Game Over banner,
  /// skips the celebration confetti).
  final bool gameOver;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    if (!widget.gameOver) _confetti.play();
    if (widget.unlocked.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showAchievements());
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  void _showAchievements() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        title: const Text(
          'Achievement Unlocked!',
          style: TextStyle(color: AppColors.textHi, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final a in widget.unlocked)
              ListTile(
                leading: Icon(a.icon, color: a.color, size: 30),
                title: Text(
                  a.title,
                  style: const TextStyle(color: AppColors.textHi),
                ),
                subtitle: Text(
                  a.description,
                  style: const TextStyle(color: AppColors.textMid),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Nice!',
              style: TextStyle(color: AppColors.neonPurple),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _nextSong() async {
    final songs = await context.read<GameRepository>().fetchSongs();
    final idx = songs.indexWhere((s) => s.id == widget.song.id);
    final next = songs[(idx + 1) % songs.length];
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(AppRoutes.fadeSlide(GameScreen(song: next)));
  }

  void _retry() {
    Navigator.of(
      context,
    ).pushReplacement(AppRoutes.fadeSlide(GameScreen(song: widget.song)));
  }

  void _share() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.panelHi,
        content: Text(
          'Shared: ${widget.result.score} pts on ${widget.song.title}! 🎹',
          style: const TextStyle(color: AppColors.textHi),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Column(
                  children: [
                    if (widget.gameOver) ...[
                      const GradientText(
                        'GAME OVER',
                        gradient: AppGradients.royal,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      widget.song.title,
                      style: const TextStyle(
                        color: AppColors.textMid,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _rankBadge(r.rank),
                    const SizedBox(height: AppSpace.md),
                    _stars(r.stars),
                    const SizedBox(height: AppSpace.md),
                    const Text(
                      'SCORE',
                      style: TextStyle(
                        color: AppColors.textLow,
                        fontSize: 13,
                        letterSpacing: 2,
                      ),
                    ),
                    _animatedScore(r.score),
                    const SizedBox(height: AppSpace.lg),
                    _statsCard(r),
                    const SizedBox(height: AppSpace.lg),
                    Row(
                      children: [
                        Expanded(
                          child: GlowButton(
                            label: 'Retry',
                            icon: Icons.refresh_rounded,
                            gradient: AppGradients.cool,
                            onPressed: _retry,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GlowButton(
                            label: 'Next Song',
                            icon: Icons.skip_next_rounded,
                            onPressed: _nextSong,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _outlineButton(
                            Icons.share_rounded,
                            'Share',
                            _share,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _outlineButton(Icons.home_rounded, 'Home', () {
                            Navigator.of(context).popUntil((r) => r.isFirst);
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirection: math.pi / 2,
                  emissionFrequency: 0.05,
                  numberOfParticles: 20,
                  maxBlastForce: 22,
                  minBlastForce: 8,
                  gravity: 0.25,
                  colors: const [
                    AppColors.neonPurple,
                    AppColors.neonPink,
                    AppColors.neonBlue,
                    AppColors.neonCyan,
                    AppColors.good,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rankBadge(String rank) {
    return Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            gradient: AppGradients.gold,
            shape: BoxShape.circle,
            boxShadow: glow(AppColors.gold, blur: 40, opacity: 0.7),
          ),
          alignment: Alignment.center,
          child: Text(
            rank,
            style: const TextStyle(
              color: Color(0xFF3A2A00),
              fontSize: 50,
              fontWeight: FontWeight.w600,
            ),
          ),
        )
        .animate()
        .scale(
          duration: 600.ms,
          curve: Curves.easeOutBack,
          begin: const Offset(0.3, 0.3),
          end: const Offset(1, 1),
        )
        .fadeIn();
  }

  Widget _stars(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < 3; i++)
          Icon(
            i < count ? Icons.star_rounded : Icons.star_outline_rounded,
            color: i < count ? AppColors.gold : AppColors.textLow,
            size: 42,
            shadows: i < count
                ? [const Shadow(color: AppColors.gold, blurRadius: 16)]
                : null,
          ).animate().scale(
            delay: (300 + i * 180).ms,
            duration: 420.ms,
            curve: Curves.easeOutBack,
            begin: const Offset(0.2, 0.2),
            end: const Offset(1, 1),
          ),
      ],
    );
  }

  Widget _animatedScore(int score) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score.toDouble()),
      duration: const Duration(milliseconds: 1300),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => GradientText(
        _format(value.round()),
        gradient: AppGradients.aurora,
        style: const TextStyle(
          fontSize: 54,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _statsCard(ScoreResult r) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpace.lg),
      glowColor: AppColors.neonPurple,
      child: Column(
        children: [
          _statRow(
            'Accuracy',
            '${r.accuracy.toStringAsFixed(1)}%',
            AppColors.neonCyan,
          ),
          _statRow('Max Combo', '${r.maxCombo}', AppColors.neonPink),
          const Divider(color: AppColors.stroke, height: 24),
          _statRow('Perfect', '${r.perfect}', AppColors.perfect),
          _statRow('Great', '${r.great}', AppColors.great),
          _statRow('Good', '${r.good}', AppColors.good),
          _statRow('Miss', '${r.miss}', AppColors.miss),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textMid, fontSize: 15),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _outlineButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textHi, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textHi,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _format(int score) {
    final s = score.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
