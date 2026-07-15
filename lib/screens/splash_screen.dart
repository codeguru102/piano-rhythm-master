import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../app.dart';
import '../data/seed_songs.dart';
import '../models/score_result.dart';
import '../theme/app_theme.dart';
import 'game_screen.dart';
import 'main_shell.dart';
import 'result_screen.dart';

/// Brand intro: full-bleed hero artwork with a slow zoom, then Home.
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
    Future.delayed(const Duration(milliseconds: 2800), () {
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
      backgroundColor: AppColors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Hero artwork, filling the screen with a slow "Ken Burns" zoom.
          Image.asset(
            'assets/images/splash.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          )
              .animate()
              .fadeIn(duration: 700.ms)
              .scale(
                begin: const Offset(1.08, 1.08),
                end: const Offset(1, 1),
                duration: 2800.ms,
                curve: Curves.easeOut,
              ),

          // Bottom scrim so the loader reads over the bright art.
          const Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 240,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC07060D)],
                  ),
                ),
              ),
            ),
          ),

          // Loading indicator near the bottom.
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 44),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 150, child: _LoadingBar()),
                  const SizedBox(height: 12),
                  Text(
                    'Loading your studio…',
                    style: TextStyle(
                      color: AppColors.textHi,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 900.ms, duration: 600.ms),
        ],
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
        color: Colors.white.withValues(alpha: 0.22),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 46,
            decoration: const BoxDecoration(gradient: AppGradients.cool),
          )
              .animate(onPlay: (c) => c.repeat())
              .slideX(
                  begin: -1.2, end: 3.5, duration: 1200.ms, curve: Curves.easeInOut),
        ),
      ),
    );
  }
}
