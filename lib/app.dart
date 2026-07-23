import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/db_init.dart';
import 'data/game_repository.dart';
import 'data/local_game_repository.dart';
import 'data/seed_songs.dart';
import 'data/sqlite_game_repository.dart';
import 'models/score_result.dart';
import 'screens/game_screen.dart';
import 'screens/main_shell.dart';
import 'screens/result_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'state/game_controller.dart';
import 'state/profile_provider.dart';
import 'state/settings_provider.dart';
import 'theme/app_theme.dart';

class PianoRhythmApp extends StatefulWidget {
  const PianoRhythmApp({super.key});

  @override
  State<PianoRhythmApp> createState() => _PianoRhythmAppState();
}

class _PianoRhythmAppState extends State<PianoRhythmApp> {
  _AppDependencies? _dependencies;
  double _progress = 0;
  String _status = 'Warming up the stage';
  String? _error;
  bool _initializing = false;
  int _initializationRun = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    if (_initializing) return;
    _initializing = true;
    final run = ++_initializationRun;
    setState(() {
      _error = null;
      _progress = 0;
      _status = 'Warming up the stage';
    });
    AudioService? audio;

    try {
      final screenshotMode = Uri.base.queryParameters['shot'] != null;
      final timeline = screenshotMode
          ? Future<void>.value()
          : _runSplashTimeline(run);

      final prefs = await SharedPreferences.getInstance();

      audio = AudioService();
      await audio.init();

      final GameRepository repo;
      if (kIsWeb) {
        // The browser build remains local-first without requiring a separately
        // deployed SQLite WASM worker.
        repo = LocalGameRepository();
      } else {
        await initDatabaseFactory();
        repo = SqliteGameRepository();
      }
      await repo.init();

      final profile = ProfileProvider(repo);
      await profile.load();

      final settings = SettingsProvider(prefs, audio);
      final game = GameController(audio);

      await timeline;
      if (screenshotMode) _report(1, 'Your stage is ready');
      if (!screenshotMode) {
        await Future<void>.delayed(const Duration(milliseconds: 280));
      }
      if (!mounted || run != _initializationRun) return;
      setState(() {
        _dependencies = _AppDependencies(
          audio: audio!,
          repo: repo,
          settings: settings,
          profile: profile,
          game: game,
        );
      });
    } catch (error) {
      _initializationRun++;
      await audio?.dispose();
      if (!mounted) return;
      setState(() {
        _error =
            'We could not prepare your studio. Check your device and try again.';
        _status = 'Setup paused';
      });
    } finally {
      _initializing = false;
    }
  }

  Future<void> _runSplashTimeline(int run) async {
    const steps = <(double, String)>[
      (0.30, 'Loading your preferences'),
      (0.50, 'Tuning the piano'),
      (0.60, 'Opening your song library'),
      (0.80, 'Restoring your progress'),
      (1.00, 'Your stage is ready'),
    ];

    for (final step in steps) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted || run != _initializationRun || _error != null) return;
      _report(step.$1, step.$2);
    }
  }

  void _report(double progress, String status) {
    if (!mounted) return;
    setState(() {
      _progress = progress;
      _status = status;
    });
  }

  @override
  void dispose() {
    final dependencies = _dependencies;
    dependencies?.settings.dispose();
    dependencies?.profile.dispose();
    dependencies?.game.dispose();
    unawaited(dependencies?.audio.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = _dependencies;
    final screenshotMode = Uri.base.queryParameters['shot'] != null;
    final content = dependencies == null
        ? SplashScreen(
            key: const ValueKey('startup'),
            progress: _progress,
            status: _status,
            error: _error,
            onRetry: _error == null ? null : _initialize,
          )
        : _ProvidedApp(
            key: const ValueKey('product'),
            dependencies: dependencies,
          );
    return MaterialApp(
      title: 'Piano Rhythm Master',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: screenshotMode
          ? content
          : AnimatedSwitcher(
              duration: AppMotion.page,
              switchInCurve: AppMotion.standard,
              switchOutCurve: Curves.easeInCubic,
              child: content,
            ),
    );
  }
}

class _ProvidedApp extends StatelessWidget {
  const _ProvidedApp({super.key, required this.dependencies});

  final _AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AudioService>.value(value: dependencies.audio),
        Provider<GameRepository>.value(value: dependencies.repo),
        ChangeNotifierProvider<SettingsProvider>.value(
          value: dependencies.settings,
        ),
        ChangeNotifierProvider<ProfileProvider>.value(
          value: dependencies.profile,
        ),
        ChangeNotifierProvider<GameController>.value(value: dependencies.game),
      ],
      // This product Navigator lives inside the dependency scope, so every
      // pushed screen can read the same providers.
      child: Navigator(
        onGenerateRoute: (_) =>
            MaterialPageRoute<void>(builder: (_) => _initialPage()),
      ),
    );
  }

  Widget _initialPage() {
    final shot = Uri.base.queryParameters['shot'];
    final song = kSeedSongs.first;
    return switch (shot) {
      'library' => const MainShell(initialIndex: 1),
      'profile' => const MainShell(initialIndex: 2),
      'settings' => const SettingsScreen(),
      'game' => GameScreen(song: song, autoPlay: true),
      'result' => ResultScreen(
        song: song,
        result: ScoreResult(
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
        ),
      ),
      _ => const MainShell(),
    };
  }
}

class _AppDependencies {
  const _AppDependencies({
    required this.audio,
    required this.repo,
    required this.settings,
    required this.profile,
    required this.game,
  });

  final AudioService audio;
  final GameRepository repo;
  final SettingsProvider settings;
  final ProfileProvider profile;
  final GameController game;
}

/// Product page transitions. Motion is removed when the platform requests it.
class AppRoutes {
  static Route<T> fadeSlide<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: AppMotion.page,
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (context, animation, _, child) {
        if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
          return child;
        }
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppMotion.standard,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.035),
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
      transitionDuration: AppMotion.page,
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (context, animation, _, child) {
        if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
          return child;
        }
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppMotion.expressive,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: 0.96, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
