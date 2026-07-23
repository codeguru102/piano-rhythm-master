import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/note_event.dart';
import '../models/score_result.dart';
import '../models/song.dart';
import '../services/audio_service.dart';

enum GameStatus { playing, paused, finished }

/// Song mode: play the whole track, misses just break combo.
/// Classic: one miss or wrong tap ends the run; speed ramps up.
enum GameMode { song, classic }

enum Judgment { perfect, great, good, miss }

extension JudgmentX on Judgment {
  String get label => switch (this) {
    Judgment.perfect => 'PERFECT!',
    Judgment.great => 'GREAT!',
    Judgment.good => 'GOOD',
    Judgment.miss => 'MISS',
  };

  int get baseScore => switch (this) {
    Judgment.perfect => 100,
    Judgment.great => 70,
    Judgment.good => 40,
    Judgment.miss => 0,
  };
}

/// A note currently on screen.
enum ActiveNoteState { pending, holding, resolved }

class ActiveNote {
  final NoteEvent event;
  final int id;
  ActiveNoteState state = ActiveNoteState.pending;
  Judgment? pressJudgment;

  ActiveNote(this.event, this.id);

  bool get hit => state == ActiveNoteState.resolved;
  bool get isHolding => state == ActiveNoteState.holding;

  double holdProgress(double currentTime) {
    if (!event.isHold) return 0;
    return ((currentTime - event.time) / event.duration).clamp(0.0, 1.0);
  }
}

/// Timing windows (seconds).
const double kPerfectWindow = 0.05; // ±50ms
const double kGreatWindow = 0.10; // ±100ms
const double kGoodWindow = 0.20; // ±200ms

/// Real-time gameplay engine. Driven each frame by the game screen's Ticker
/// via [tick]. Notifies listeners once per frame so the play area repaints.
class GameController extends ChangeNotifier {
  GameController(this._audio);

  final AudioService _audio;

  late Song _song;
  Song get song => _song;

  double _approach = 1.5; // seconds for a note to fall to the hit line
  double get approach => _approach;

  double _currentTime = 0;
  double get currentTime => _currentTime;

  GameStatus _status = GameStatus.playing;
  GameStatus get status => _status;
  bool get isPlaying => _status == GameStatus.playing;

  GameMode _mode = GameMode.song;
  GameMode get mode => _mode;

  /// Time-scale that ramps up in classic mode (tiles fall faster over time).
  double _speed = 1.0;
  double get speed => _speed;

  /// True when a classic run ended on a mistake (vs. finishing the song).
  bool failed = false;

  /// Fraction (0 = top of board, 1 = bottom) of the last tile hit — used as
  /// the on-screen origin for the explosion effect.
  double lastHitFraction = 0;

  int _score = 0;
  int _combo = 0;
  int _maxCombo = 0;
  int _perfect = 0, _great = 0, _good = 0, _miss = 0;

  int get score => _score;
  int get combo => _combo;
  int get maxCombo => _maxCombo;
  int get perfect => _perfect;
  int get great => _great;
  int get good => _good;
  int get miss => _miss;

  int get _judged => _perfect + _great + _good + _miss;

  double get accuracy {
    if (_judged == 0) return 100;
    final weighted = _perfect * 1.0 + _great * 0.7 + _good * 0.4;
    return (weighted / _judged * 100).clamp(0, 100);
  }

  double get progress =>
      _song.duration == 0 ? 0 : (_currentTime / _song.duration).clamp(0.0, 1.0);

  /// Time until the first note reaches the hit line — drives the intro countdown.
  double get leadInRemaining =>
      _song.beatMap.isEmpty ? 0 : (_song.beatMap.first.time - _currentTime);

  // last judgment feedback (for the pop animation)
  Judgment? _lastJudgment;
  int _feedbackTick = 0;
  int? _lastHitLane;
  Judgment? get lastJudgment => _lastJudgment;
  int get feedbackTick => _feedbackTick;
  int? get lastHitLane => _lastHitLane;

  final List<ActiveNote> _active = [];
  List<ActiveNote> get activeNotes => _active;
  int _spawnIndex = 0;
  int _nextId = 0;

  // hit-line flash per lane
  final List<double> laneFlash = List.filled(8, 0);
  final List<bool> laneHeld = List.filled(8, false);

  void configure({
    required Song song,
    required double noteSpeed,
    GameMode mode = GameMode.song,
  }) {
    _song = song;
    _mode = mode;
    _speed = 1.0;
    failed = false;
    _approach = (song.difficulty.baseApproach / noteSpeed).clamp(0.4, 3.4);
    _currentTime = 0;
    _score = 0;
    _combo = 0;
    _maxCombo = 0;
    _perfect = _great = _good = _miss = 0;
    _active.clear();
    _spawnIndex = 0;
    _nextId = 0;
    _lastJudgment = null;
    _feedbackTick = 0;
    _status = GameStatus.playing;
    for (var i = 0; i < laneFlash.length; i++) {
      laneFlash[i] = 0;
      laneHeld[i] = false;
    }
  }

  void tick(double dt) {
    if (_status != GameStatus.playing) return;
    // Classic mode accelerates as more tiles are cleared.
    if (_mode == GameMode.classic) {
      _speed = (1.0 + _judged * 0.02).clamp(1.0, 2.6);
    }
    _currentTime += dt * _speed;

    // spawn notes entering the approach window
    while (_spawnIndex < _song.beatMap.length &&
        _song.beatMap[_spawnIndex].time - _currentTime <= _approach) {
      _active.add(ActiveNote(_song.beatMap[_spawnIndex], _nextId++));
      _spawnIndex++;
    }

    // Resolve completed sustains, and miss notes that fell off untapped.
    for (final n in _active) {
      if (n.isHolding && _currentTime >= n.event.time + n.event.duration) {
        n.state = ActiveNoteState.resolved;
        laneHeld[n.event.lane] = false;
        _lastHitLane = n.event.lane;
        lastHitFraction = 1;
        _registerHit(n.pressJudgment ?? Judgment.good, holdBonus: true);
      } else if (n.state == ActiveNoteState.pending && _frac(n) > 1.08) {
        n.state = ActiveNoteState.resolved;
        _lastHitLane = n.event.lane;
        lastHitFraction = 1;
        _registerMiss();
        if (_mode == GameMode.classic) {
          _fail();
          break;
        }
      }
    }
    _active.removeWhere((n) => n.hit && _frac(n) > 1.3);

    // Decay tap flashes. Held lanes keep a living glow until release.
    for (var i = 0; i < laneFlash.length; i++) {
      if (laneHeld[i]) {
        laneFlash[i] = 0.72 + 0.16 * math.sin(_currentTime * 10);
      } else if (laneFlash[i] > 0) {
        laneFlash[i] = math.max(0, laneFlash[i] - dt * 4);
      }
    }

    // finish
    if (_spawnIndex >= _song.beatMap.length &&
        _active.isEmpty &&
        _currentTime >= _song.duration - 0.1) {
      _status = GameStatus.finished;
    }

    notifyListeners();
  }

  /// Player pressed a lane. Always plays the piano tone; judges the nearest
  /// hittable note in that lane if one is within the good window.
  void onLanePress(int lane, {bool playSound = true}) {
    if (playSound) _audio.playLane(lane);
    if (lane < laneFlash.length) laneFlash[lane] = 1.0;
    if (_status != GameStatus.playing) {
      notifyListeners();
      return;
    }

    if (_mode == GameMode.classic) {
      _classicPress(lane);
      notifyListeners();
      return;
    }

    // Song mode: tap explodes the lowest (furthest-fallen) tile in this lane,
    // wherever it is on screen. A tap on an empty column does nothing.
    ActiveNote? best;
    double bestF = -1e9;
    for (final n in _active) {
      if (n.hit || n.event.lane != lane) continue;
      final f = _frac(n);
      if (f < -0.05 || f > 1.08) continue;
      if (f > bestF) {
        bestF = f;
        best = n;
      }
    }

    if (best != null) {
      _lastHitLane = lane;
      lastHitFraction = bestF.clamp(0.0, 1.0);
      final judgment = _grade(bestF);
      if (best.event.isHold) {
        best.state = ActiveNoteState.holding;
        best.pressJudgment = judgment;
        laneHeld[lane] = true;
        _setFeedback(judgment);
      } else {
        best.state = ActiveNoteState.resolved;
        _registerHit(judgment);
      }
    }
    notifyListeners();
  }

  /// Compatibility entry point for callers that only need a quick tap.
  void onLaneTap(int lane, {bool playSound = true}) {
    onLanePress(lane, playSound: playSound);
    onLaneRelease(lane);
  }

  /// Releases an active sustain. Releasing near or after its tail succeeds;
  /// letting go early breaks the note and the combo.
  void onLaneRelease(int lane) {
    if (lane < laneHeld.length) laneHeld[lane] = false;
    if (_status != GameStatus.playing) return;

    ActiveNote? held;
    for (final note in _active) {
      if (note.event.lane == lane && note.isHolding) {
        held = note;
        break;
      }
    }
    if (held == null) {
      notifyListeners();
      return;
    }

    final end = held.event.time + held.event.duration;
    held.state = ActiveNoteState.resolved;
    _lastHitLane = lane;
    lastHitFraction = 1;
    if (_currentTime >= end - 0.12) {
      _registerHit(held.pressJudgment ?? Judgment.good, holdBonus: true);
    } else {
      _registerMiss();
      if (_mode == GameMode.classic) _fail();
    }
    notifyListeners();
  }

  /// Classic Piano Tiles: you must tap the lowest un-hit tile's column, in
  /// order. Tapping the wrong column (or with nothing on screen) ends the run.
  void _classicPress(int lane) {
    if (leadInRemaining > 0) return; // ignore taps during the countdown
    final pending = _active.where((n) => !n.hit && _frac(n) <= 1.08).toList()
      ..sort((a, b) => _frac(b).compareTo(_frac(a))); // lowest tile first
    if (pending.isEmpty) {
      _lastHitLane = lane;
      lastHitFraction = 1;
      _registerMiss();
      _fail();
      return;
    }
    final next = pending.first;
    if (next.event.lane != lane) {
      _lastHitLane = lane;
      lastHitFraction = 1;
      _registerMiss();
      _fail();
      return;
    }
    final f = _frac(next);
    _lastHitLane = lane;
    lastHitFraction = f.clamp(0.0, 1.0);
    final judgment = _grade(f);
    if (next.event.isHold) {
      next.state = ActiveNoteState.holding;
      next.pressJudgment = judgment;
      laneHeld[lane] = true;
      _setFeedback(judgment);
    } else {
      next.state = ActiveNoteState.resolved;
      _registerHit(judgment);
    }
  }

  void _fail() {
    if (_status == GameStatus.finished) return;
    failed = true;
    _status = GameStatus.finished;
  }

  /// How far a tile has fallen: 0 at the top of the board, 1 at the bottom.
  double _frac(ActiveNote n) => 1 - (n.event.time - _currentTime) / _approach;

  /// Grade a hit by how far the tile had fallen — reward tapping promptly.
  Judgment _grade(double f) {
    if (f <= 0.72) return Judgment.perfect;
    if (f <= 0.9) return Judgment.great;
    return Judgment.good;
  }

  void _registerHit(Judgment j, {bool holdBonus = false}) {
    switch (j) {
      case Judgment.perfect:
        _perfect++;
        break;
      case Judgment.great:
        _great++;
        break;
      case Judgment.good:
        _good++;
        break;
      case Judgment.miss:
        break;
    }

    _combo++;
    _maxCombo = math.max(_maxCombo, _combo);
    final points = j.baseScore + (holdBonus ? 60 : 0);
    _score += (points * comboMultiplier).round();
    _setFeedback(j);
  }

  void _registerMiss() {
    _miss++;
    _combo = 0;
    _setFeedback(Judgment.miss);
  }

  double get comboMultiplier {
    if (_combo >= 100) return 2.0;
    if (_combo >= 50) return 1.5;
    if (_combo >= 10) return 1.2;
    return 1.0;
  }

  void _setFeedback(Judgment j) {
    _lastJudgment = j;
    _feedbackTick++;
  }

  void pause() {
    if (_status == GameStatus.playing) {
      _status = GameStatus.paused;
      notifyListeners();
    }
  }

  void resume() {
    if (_status == GameStatus.paused) {
      _status = GameStatus.playing;
      notifyListeners();
    }
  }

  ScoreResult buildResult() => ScoreResult(
    songId: _song.id,
    score: _score,
    accuracy: accuracy,
    maxCombo: _maxCombo,
    perfect: _perfect,
    great: _great,
    good: _good,
    miss: _miss,
    totalNotes: _song.noteCount,
    timestamp: DateTime.now(),
  );
}
