import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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
import '../widgets/piano_tile.dart';
import '../widgets/gradient_background.dart';
import '../widgets/fireworks.dart';
import '../widgets/judgment_burst.dart';
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
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final GameController _ctrl;
  late final SettingsProvider _settings;
  double _last = 0;
  bool _navigated = false;
  bool _resetFrameClock = false;
  bool _leftHand = false;
  int _lastBurstTick = 0;
  int _burstSeq = 0;
  final List<_Burst> _bursts = [];
  final Map<int, int> _pointerLanes = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ctrl = context.read<GameController>();
    _settings = context.read<SettingsProvider>();
    _leftHand = _settings.leftHandMode;
    _ctrl.configure(
      song: widget.song,
      noteSpeed: _settings.noteSpeed,
      mode: _settings.gameMode,
    );
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final now = elapsed.inMicroseconds / 1e6;
    if (_resetFrameClock) {
      _last = now;
      _resetFrameClock = false;
    }
    var dt = now - _last;
    _last = now;
    if (dt < 0) dt = 0;
    if (dt > 0.05) dt = 0.05; // clamp after a stall
    if (_ctrl.isPlaying) _ctrl.tick(dt);
    if (widget.autoPlay && _ctrl.isPlaying) {
      for (final n in List.of(_ctrl.activeNotes)) {
        if (n.state == ActiveNoteState.pending &&
            n.event.time <= _ctrl.currentTime) {
          _pressLane(n.event.lane);
        }
      }
    }
    _syncBurst();
    if (_ctrl.status == GameStatus.finished && !_navigated) _finish();
  }

  Future<void> _finish() async {
    _navigated = true;
    _ticker.stop();
    final result = _ctrl.buildResult();
    final unlocked = await context.read<ProfileProvider>().applyResult(result);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      AppRoutes.scaleFade(
        ResultScreen(
          song: widget.song,
          result: result,
          unlocked: unlocked,
          gameOver: _ctrl.failed,
        ),
      ),
    );
  }

  void _pressLane(int lane) {
    _ctrl.onLanePress(lane, playSound: !widget.autoPlay);
    _syncBurst();
  }

  void _releaseLane(int lane) {
    _ctrl.onLaneRelease(lane);
    _syncBurst();
  }

  void _syncBurst() {
    if (_ctrl.feedbackTick != _lastBurstTick) {
      _lastBurstTick = _ctrl.feedbackTick;
      final j = _ctrl.lastJudgment;
      if (j != null && _ctrl.lastHitLane != null) {
        final color = switch (j) {
          Judgment.perfect => AppColors.perfect,
          Judgment.great => AppColors.great,
          Judgment.good => AppColors.good,
          Judgment.miss => AppColors.miss,
        };
        // Cap concurrent explosions so a fast run can't stack render cost.
        if (_bursts.length >= 6) _bursts.removeAt(0);
        _bursts.add(
          _Burst(
            _burstSeq++,
            _ctrl.lastHitLane!,
            color,
            _ctrl.lastHitFraction,
            switch (j) {
              Judgment.perfect => 1.3,
              Judgment.great => 1.1,
              Judgment.good => 0.9,
              Judgment.miss => 0.8,
            },
            j == Judgment.miss,
          ),
        );
        if (_settings.vibration && !kIsWeb && !widget.autoPlay) {
          switch (j) {
            case Judgment.perfect:
              HapticFeedback.mediumImpact();
            case Judgment.great:
              HapticFeedback.lightImpact();
            case Judgment.good:
              HapticFeedback.selectionClick();
            case Judgment.miss:
              HapticFeedback.heavyImpact();
          }
        }
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
      _ctrl.configure(
        song: widget.song,
        noteSpeed: _settings.noteSpeed,
        mode: _settings.gameMode,
      );
    });
    if (!_ticker.isActive) _ticker.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _resetFrameClock = true;
        _ctrl.pause();
        break;
      case AppLifecycleState.resumed:
        _resetFrameClock = true;
        break;
    }
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
              _modeBadge(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      Text(
                        widget.song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMid,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      ScoreDisplay(
                        score: _ctrl.score,
                        combo: _ctrl.combo,
                        accuracy: _ctrl.accuracy,
                        multiplier: _ctrl.comboMultiplier,
                      ),
                    ],
                  ),
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
              valueColor: const AlwaysStoppedAnimation(AppColors.neonPurple),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeBadge() {
    final classic = _ctrl.mode == GameMode.classic;
    final accent = classic ? AppColors.expert : AppColors.neonCyan;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(
          color: classic ? accent.withValues(alpha: 0.7) : AppColors.stroke,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            classic
                ? Icons.local_fire_department_rounded
                : Icons.music_note_rounded,
            size: 15,
            color: accent,
          ),
          const SizedBox(width: 4),
          Text(
            classic ? 'CLASSIC' : 'SONG',
            style: TextStyle(
              color: classic ? accent : AppColors.textMid,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
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
        final fall = math.max(0.0, h - 72); // land above the piano key targets
        const gap = 5.0;

        // Build falling tiles; each tile's height follows the rhythm gap to
        // the previous note so they read as a continuous stream of tiles.
        final tiles = <Widget>[];
        double prevTime = double.nan;
        for (final n in _ctrl.activeNotes) {
          final rhythmDuration = prevTime.isNaN
              ? 0.28
              : (n.event.time - prevTime).clamp(0.12, 0.5);
          prevTime = n.event.time;
          if (n.hit) continue;
          final f = 1 - (n.event.time - _ctrl.currentTime) / _ctrl.approach;
          if (f < -0.05 || (!n.isHolding && f > 1.08)) continue;
          final headFraction = n.isHolding ? 1.0 : f;
          final bottomY = headFraction * fall;
          final heightPx = n.event.isHold
              ? 64.0
              : ((rhythmDuration / _ctrl.approach) * fall).clamp(46.0, 190.0);
          final holdProgress = n.holdProgress(_ctrl.currentTime);
          final sustainH = n.event.isHold
              ? ((n.event.duration / _ctrl.approach) *
                        fall *
                        (n.isHolding ? 1 - holdProgress : 1))
                    .clamp(58.0, fall * 0.62)
              : 0.0;
          final col = _col(n.event.lane);
          final tailH = n.event.isHold
              ? 30.0
              : (heightPx * 0.7).clamp(34.0, 96.0);
          final totalH = heightPx + sustainH + tailH;
          tiles.add(
            Positioned(
              key: ValueKey('tile_${n.id}'),
              left: col * laneW + gap,
              top: bottomY - totalH,
              width: laneW - gap * 2,
              height: totalH,
              child: PianoTile(
                color: kLaneColors[n.event.lane],
                bodyHeight: heightPx,
                tailHeight: tailH,
                sustainHeight: sustainH,
                holdProgress: holdProgress,
                isHolding: n.isHolding,
                intensity: f.clamp(0.0, 1.0),
              ),
            ),
          );
        }

        // Whole board is the tap surface (multi-touch via Listener): a pointer
        // down anywhere in a column taps that column's tile.
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) {
            final col = (e.localPosition.dx / laneW).floor().clamp(
              0,
              kLaneCount - 1,
            );
            final lane = _leftHand ? (kLaneCount - 1 - col) : col;
            _pointerLanes[e.pointer] = lane;
            _pressLane(lane);
          },
          onPointerUp: (e) {
            final lane = _pointerLanes.remove(e.pointer);
            if (lane != null) _releaseLane(lane);
          },
          onPointerCancel: (e) {
            final lane = _pointerLanes.remove(e.pointer);
            if (lane != null) _releaseLane(lane);
          },
          child: ClipRect(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ambient pulsing lane beams (subtle depth)
                for (int lane = 0; lane < kLaneCount; lane++)
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
                              kLaneColors[lane].withValues(
                                alpha:
                                    0.04 +
                                    0.05 *
                                        (0.5 +
                                            0.5 *
                                                math.sin(
                                                  _ctrl.currentTime * 2.2 +
                                                      lane * 1.3,
                                                )),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                // gradient lane guide-lines
                for (int i = 1; i < kLaneCount; i++)
                  Positioned(
                    left: i * laneW,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        width: 1,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.stroke,
                              AppColors.stroke,
                              Colors.transparent,
                            ],
                            stops: [0.0, 0.18, 0.82, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                // base glow that grounds the board
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.neonPurple.withValues(alpha: 0.08),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: fall - 2,
                  child: IgnorePointer(
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.neonCyan,
                            AppColors.neonPurple,
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: glow(
                          AppColors.neonCyan,
                          blur: 14,
                          opacity: 0.38,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 6,
                  height: 56,
                  child: IgnorePointer(child: _laneTargets()),
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
                                kLaneColors[lane].withValues(
                                  alpha: 0.28 * _ctrl.laneFlash[lane],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ...tiles,
                // hit bursts
                for (final b in _bursts)
                  Positioned(
                    key: ValueKey('burst_${b.id}'),
                    left: _col(b.lane) * laneW + laneW / 2 - 135,
                    top: (b.fraction * fall) - 135,
                    width: 270,
                    height: 270,
                    child: Fireworks(
                      color: b.color,
                      intensity: b.intensity,
                      isMiss: b.isMiss,
                      onDone: () => _removeBurst(b.id),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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
    final subtitle = switch (j) {
      Judgment.perfect => 'FLAWLESS TIMING',
      Judgment.great => 'RIGHT ON THE BEAT',
      Judgment.good => 'KEEP THE FLOW',
      Judgment.miss => 'RESET & RISE',
    };
    return Positioned(
      left: 0,
      right: 0,
      bottom: 138,
      child: IgnorePointer(
        child: Center(
          child: JudgmentBurst(
            key: ValueKey(_ctrl.feedbackTick),
            label: j.label,
            subtitle: subtitle,
            color: color,
            isMiss: j == Judgment.miss,
          ),
        ),
      ),
    );
  }

  Widget _laneTargets() {
    return Row(
      children: [
        for (var displayLane = 0; displayLane < kLaneCount; displayLane++)
          _laneTarget(displayLane),
      ],
    );
  }

  Widget _laneTarget(int displayLane) {
    final lane = _leftHand ? kLaneCount - 1 - displayLane : displayLane;
    final color = kLaneColors[lane];
    final flash = _ctrl.laneFlash[lane];
    final held = _ctrl.laneHeld[lane];
    return Expanded(
      child: AnimatedScale(
        duration: AppMotion.touch,
        scale: held ? 0.94 : 1,
        child: AnimatedContainer(
          duration: AppMotion.touch,
          margin: EdgeInsets.fromLTRB(5, held ? 6 : 0, 5, 0),
          decoration: BoxDecoration(
            gradient: held
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white.withValues(alpha: 0.3), color],
                  )
                : null,
            color: held ? null : color.withValues(alpha: 0.08 + 0.22 * flash),
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(
              color: held
                  ? Colors.white.withValues(alpha: 0.95)
                  : color.withValues(alpha: 0.38 + 0.5 * flash),
              width: held ? 2 : 1,
            ),
            boxShadow: held
                ? [BoxShadow(color: color, blurRadius: 22, spreadRadius: 1)]
                : null,
          ),
          alignment: Alignment.center,
          child: held
              ? const Icon(
                  Icons.keyboard_double_arrow_down_rounded,
                  color: Colors.white,
                  size: 23,
                )
              : Text(
                  kLaneLabels[lane],
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 22),
            decoration: BoxDecoration(
              color: AppColors.bg.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: AppColors.strokeStrong),
              boxShadow: const [
                BoxShadow(color: Color(0x66000000), blurRadius: 30),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('GET READY', style: AppTextStyles.label),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: AppMotion.state,
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: CurvedAnimation(
                      parent: animation,
                      curve: AppMotion.expressive,
                    ),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Text(
                    text,
                    key: ValueKey(text),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 74,
                      height: 1,
                      fontWeight: FontWeight.w600,
                      shadows: const [
                        Shadow(color: AppColors.neonPink, blurRadius: 32),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap a key as the tile reaches the line',
                  style: AppTextStyles.bodyMuted,
                ),
              ],
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
                  fontWeight: FontWeight.w600,
                ),
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
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textHi,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
  final double fraction; // 0 = top of board, 1 = bottom
  final double intensity;
  final bool isMiss;
  const _Burst(
    this.id,
    this.lane,
    this.color,
    this.fraction,
    this.intensity,
    this.isMiss,
  );
}
