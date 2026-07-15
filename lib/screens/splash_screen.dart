import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../app.dart';
import '../data/seed_songs.dart';
import '../models/score_result.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';
import '../widgets/gradient_text.dart';
import '../widgets/piano_muse.dart';
import 'game_screen.dart';
import 'main_shell.dart';
import 'result_screen.dart';

/// Brand intro: animated glowing logo, app name, loading, then Home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Deep-link used to capture screenshots of individual screens headlessly.
    final shot = Uri.base.queryParameters['shot'];
    if (shot != null && shot != 'splash') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _routeForShot(shot));
      return;
    }
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      Navigator.of(context)
          .pushReplacement(AppRoutes.scaleFade(const MainShell()));
    });
  }

  void _routeForShot(String shot) {
    if (!mounted) return;
    final nav = Navigator.of(context);
    int tab = switch (shot) {
      'library' => 1,
      'profile' => 2,
      'settings' => 3,
      _ => 0,
    };
    nav.pushReplacement(AppRoutes.scaleFade(MainShell(initialIndex: tab)));

    final song = kSeedSongs.first;
    if (shot == 'game') {
      nav.push(AppRoutes.fadeSlide(GameScreen(song: song, autoPlay: true)));
    } else if (shot == 'result') {
      final demo = ScoreResult(
        songId: song.id,
        score: 95420,
        accuracy: 96.4,
        maxCombo: 128,
        perfect: 210,
        great: 34,
        good: 9,
        miss: 3,
        totalNotes: 256,
        timestamp: DateTime.now(),
      );
      nav.push(AppRoutes.scaleFade(ResultScreen(song: song, result: demo)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PianoMuse(size: 208)
                  .animate()
                  .scale(
                    duration: 800.ms,
                    curve: Curves.easeOutBack,
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1, 1),
                  )
                  .fadeIn(duration: 600.ms),
              const SizedBox(height: AppSpace.md),
              const GradientText(
                'Piano Rhythm Master',
                textAlign: TextAlign.center,
                gradient: AppGradients.aurora,
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 700.ms)
                  .slideY(begin: 0.4, end: 0, curve: Curves.easeOut)
                  .then()
                  .shimmer(duration: 1600.ms, color: Colors.white),
              const SizedBox(height: 6),
              const Text(
                'Tap. Time. Triumph.',
                style: TextStyle(color: AppColors.textMid, fontSize: 14),
              ).animate().fadeIn(delay: 800.ms, duration: 700.ms),
              const SizedBox(height: AppSpace.xl),
              const SizedBox(
                width: 130,
                child: _LoadingBar(),
              ).animate().fadeIn(delay: 900.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingBar extends StatelessWidget {
  const _LoadingBar();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Container(
        height: 5,
        color: AppColors.panelHi,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 40,
            decoration: const BoxDecoration(gradient: AppGradients.cool),
          )
              .animate(onPlay: (c) => c.repeat())
              .slideX(begin: -1.2, end: 3.5, duration: 1200.ms, curve: Curves.easeInOut),
        ),
      ),
    );
  }
}
