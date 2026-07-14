import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/game_repository.dart';
import 'services/audio_service.dart';
import 'state/game_controller.dart';
import 'state/profile_provider.dart';
import 'state/settings_provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

class PianoRhythmApp extends StatelessWidget {
  const PianoRhythmApp({
    super.key,
    required this.prefs,
    required this.audio,
    required this.repo,
  });

  final SharedPreferences prefs;
  final AudioService audio;
  final GameRepository repo;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AudioService>.value(value: audio),
        Provider<GameRepository>.value(value: repo),
        ChangeNotifierProvider(create: (_) => SettingsProvider(prefs, audio)),
        ChangeNotifierProvider(create: (_) => ProfileProvider(repo)..load()),
        ChangeNotifierProvider(create: (_) => GameController(audio)),
      ],
      child: MaterialApp(
        title: 'Piano Rhythm Master',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const SplashScreen(),
      ),
    );
  }
}

/// Page-transition helpers used across the app (fade / slide / scale).
class AppRoutes {
  static Route<T> fadeSlide<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  static Route<T> scaleFade<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
