import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../data/seed_songs.dart';
import '../models/song.dart';
import '../services/audio_service.dart';
import '../state/game_controller.dart';
import '../state/profile_provider.dart';
import '../state/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/piano_button.dart';
import '../widgets/falling_note.dart';
import '../widgets/gradient_background.dart';
import '../widgets/hit_burst.dart';
import '../widgets/score_display.dart';
import 'result_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.song, this.autoPlay = false});

  final Song song;

  /// Auto-hits notes on time — used to capture a lively gameplay screenshot.
  final bool autoPlay;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final GameController _ctrl;
  late final SettingsProvider _settings;
  double _last = 0;
  bool _navigated = false;
  bool _leftHand = false;
  int _lastBurstTick = 0;
  int _burstSeq = 0;
  final List<_Burst> _bursts = [];

  @override
  void initState() {
    super.initState();
    _ctrl = context.read<GameController>();
    _settings = context.read<SettingsProvider>();
    _leftHand = _settings.leftHandMode;
    _ctrl.configure(song: widget.song, noteSpeed: _settings.noteSpeed);
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final now = elapsed.inMicroseconds / 1e6;
    var dt = now - _last;
    _last = now;
    if (dt < 0) dt = 0;
    if (dt > 0.05) dt = 0.05; // clamp after a stall
    if (_ctrl.isPlaying) _ctrl.tick(dt);
    if (widget.autoPlay && _ctrl.isPlaying) {
      for (final n in List.of(_ctrl.activeNotes)) {
        if (!n.hit && n.event.time <= _ctrl.currentTime) _tapLane(n.event.lane);
      }
    }
    if (_ctrl.status == GameStatus.finished && !_navigated) _finish();
  }

  Future<void> _finish() async {
    _navigated = true;
    _ticker.stop();
    final result = _ctrl.buildResult();
    final unlocked =
        await context.read<ProfileProvider>().applyResult(result);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      AppRoutes.scaleFade(ResultScreen(
        song: widget.song,
        result: result,
        unlocked: unlocked,
      )),
    );
  }

  void _tapLane(int lane) {
    _ctrl.onLaneTap(lane);
    if (_ctrl.feedbackTick != _lastBurstTick) {
      _lastBurstTick = _ctrl.feedbackTick;
      final j = _ctrl.lastJudgment;
      if (j != null && j != Judgment.miss && _ctrl.lastHitLane != null) {
        final color = switch (j) {
          Judgment.perfect => AppColors.perfect,
          Judgment.great => AppColors.great,
          Judgment.good => AppColors.good,
          Judgment.miss => AppColors.miss,
        };
        _bursts.add(_Burst(_burstSeq++, _ctrl.lastHitLane!, color));
        if (_settings.vibration) HapticFeedback.selectionClick();
      }
    }
  }

  void _removeBurst(int id) {
    if (!mounted) return;
    setState(() => _bursts.removeWhere((b) => b.id == id));
  }

  void _restart() {
    setState(() {
      _navigated = false;
      _last = 0;
      _ctrl.configure(song: widget.song, noteSpeed: _settings.noteSpeed);
    });
    if (!_ticker.isActive) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        body: GradientBackground(
          particleCount: 10,
          child: SafeArea(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                return Stack(
                  children: [
                    Column(
                      children: [
                        _header(),
                        Expanded(child: _noteArea()),
                        _pianoRow(),
                      ],
                    ),
                    _feedback(),
                    if (_ctrl.leadInRemaining > 0 && _ctrl.isPlaying)
                      _countdown(),
                    if (_ctrl.status == GameStatus.paused) _pauseMenu(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 44),
              Expanded(
                child: ScoreDisplay(
                  score: _ctrl.score,
                  combo: _ctrl.combo,
                  accuracy: _ctrl.accuracy,
                  multiplier: _ctrl.comboMultiplier,
                ),
              ),
              _iconButton(Icons.pause_rounded, _ctrl.pause),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              value: _ctrl.progress,
              minHeight: 5,
              backgroundColor: AppColors.panelHi,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.neonPurple),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.panel,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.stroke),
        ),
        child: Icon(icon, color: AppColors.textHi, size: 24),
      ),
    );
  }

  int _col(int lane) => _leftHand ? (kLaneCount - 1 - lane) : lane;

  Widget _noteArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;
        final laneW = w / kLaneCount;
        final hitY = h - 8;
        const noteH = 30.0;

        final notes = <Widget>[];
        for (final n in _ctrl.activeNotes) {
          final f = 1 - (n.event.time - _ctrl.currentTime) / _ctrl.approach;
          if (f < -0.05 || n.hit) continue;
          final col = _col(n.event.lane);
          final top = f * hitY - noteH;
          notes.add(Positioned(
            left: col * laneW + 6,
            top: top,
            child: FallingNote(
              color: kLaneColors[n.event.lane],
              width: laneW - 12,
              height: noteH,
            ),
          ));
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // lane dividers
            for (int i = 1; i < kLaneCount; i++)
              Positioned(
                left: i * laneW,
                top: 0,
                bottom: 0,
                child: Container(width: 1, color: AppColors.stroke),
              ),
            // lane light columns (glow up the lane on hit/press)
            for (int lane = 0; lane < kLaneCount; lane++)
              if (_ctrl.laneFlash[lane] > 0.01)
                Positioned(
                  left: _col(lane) * laneW,
                  top: 0,
                  bottom: 0,
                  width: laneW,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            kLaneColors[lane]
                                .withValues(alpha: 0.28 * _ctrl.laneFlash[lane]),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            // hit line + targets
            Positioned(
              left: 0,
              right: 0,
              top: hitY - 3,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  boxShadow: glow(AppColors.neonCyan, blur: 10, opacity: 0.5),
                ),
              ),
            ),
            for (int lane = 0; lane < kLaneCount; lane++)
              Positioned(
                left: _col(lane) * laneW + laneW / 2 - 16,
                top: hitY - 18,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: kLaneColors[lane].withValues(alpha: 0.7),
                        width: 2),
                    color: kLaneColors[lane]
                        .withValues(alpha: 0.12 + 0.5 * _ctrl.laneFlash[lane]),
                  ),
                ),
              ),
            ...notes,
            // hit bursts
            for (final b in _bursts)
              Positioned(
                left: _col(b.lane) * laneW + laneW / 2 - 40,
                top: hitY - 40,
                width: 80,
                height: 80,
                child: HitBurst(
                  key: ValueKey(b.id),
                  color: b.color,
                  onDone: () => _removeBurst(b.id),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _pianoRow() {
    return Container(
      height: 150,
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 10),
      child: Row(
        children: [
          for (int col = 0; col < kLaneCount; col++)
            Expanded(
              child: Builder(builder: (_) {
                final lane = _leftHand ? (kLaneCount - 1 - col) : col;
                return PianoButton(
                  label: kLaneLabels[lane],
                  color: kLaneColors[lane],
                  flash: _ctrl.laneFlash[lane],
                  onPressed: () => _tapLane(lane),
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _feedback() {
    final j = _ctrl.lastJudgment;
    if (j == null) return const SizedBox.shrink();
    final color = switch (j) {
      Judgment.perfect => AppColors.perfect,
      Judgment.great => AppColors.great,
      Judgment.good => AppColors.good,
      Judgment.miss => AppColors.miss,
    };
    return Positioned(
      left: 0,
      right: 0,
      bottom: 220,
      child: IgnorePointer(
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: Tween(begin: 1.3, end: 1.0).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Text(
              j.label,
              key: ValueKey(_ctrl.feedbackTick),
              style: TextStyle(
                color: color,
                fontSize: 30,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                shadows: [Shadow(color: color, blurRadius: 18)],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _countdown() {
    final r = _ctrl.leadInRemaining;
    final text = r > 0.6 ? r.ceil().toString() : 'GO';
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 96,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(color: AppColors.neonPink, blurRadius: 40)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pauseMenu() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.72),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Paused',
                style: TextStyle(
                    color: AppColors.textHi,
                    fontSize: 30,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpace.lg),
              _menuButton(Icons.play_arrow_rounded, 'Resume', _ctrl.resume),
              _menuButton(Icons.refresh_rounded, 'Restart', _restart),
              _menuButton(Icons.home_rounded, 'Quit', () {
                Navigator.of(context).pop();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuButton(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          context.read<AudioService>().playTap();
          onTap();
        },
        child: Container(
          width: 220,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: AppGradients.panel,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: AppColors.stroke),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.textHi),
              const SizedBox(width: 10),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textHi,
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Burst {
  final int id;
  final int lane;
  final Color color;
  const _Burst(this.id, this.lane, this.color);
}
