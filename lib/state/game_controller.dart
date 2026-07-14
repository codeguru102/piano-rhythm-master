import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/note_event.dart';
import '../models/score_result.dart';
import '../models/song.dart';
import '../services/audio_service.dart';

enum GameStatus { playing, paused, finished }

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
class ActiveNote {
  final NoteEvent event;
  final int id;
  bool hit = false;
  ActiveNote(this.event, this.id);
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

  void configure({required Song song, required double noteSpeed}) {
    _song = song;
    _approach = (song.difficulty.baseApproach / noteSpeed).clamp(0.6, 2.6);
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
    }
  }

  void tick(double dt) {
    if (_status != GameStatus.playing) return;
    _currentTime += dt;

    // spawn notes entering the approach window
    while (_spawnIndex < _song.beatMap.length &&
        _song.beatMap[_spawnIndex].time - _currentTime <= _approach) {
      _active.add(ActiveNote(_song.beatMap[_spawnIndex], _nextId++));
      _spawnIndex++;
    }

    // miss notes that fell past the good window
    for (final n in _active) {
      if (!n.hit && _currentTime - n.event.time > kGoodWindow) {
        n.hit = true;
        _registerMiss();
      }
    }
    _active.removeWhere(
        (n) => n.hit && _currentTime - n.event.time > kGoodWindow + 0.15);

    // decay lane flashes
    for (var i = 0; i < laneFlash.length; i++) {
      if (laneFlash[i] > 0) laneFlash[i] = math.max(0, laneFlash[i] - dt * 4);
    }

    // finish
    if (_spawnIndex >= _song.beatMap.length &&
        _active.isEmpty &&
        _currentTime >= _song.duration - 0.1) {
      _status = GameStatus.finished;
    }

    notifyListeners();
  }

  /// Player tapped a lane. Always plays the piano tone; judges the nearest
  /// hittable note in that lane if one is within the good window.
  void onLaneTap(int lane) {
    _audio.playLane(lane);
    if (lane < laneFlash.length) laneFlash[lane] = 1.0;
    if (_status != GameStatus.playing) {
      notifyListeners();
      return;
    }

    ActiveNote? best;
    double bestDelta = double.infinity;
    for (final n in _active) {
      if (n.hit || n.event.lane != lane) continue;
      final delta = (n.event.time - _currentTime).abs();
      if (delta < bestDelta) {
        bestDelta = delta;
        best = n;
      }
    }

    if (best != null && bestDelta <= kGoodWindow) {
      best.hit = true;
      _lastHitLane = lane;
      _registerHit(bestDelta);
    }
    notifyListeners();
  }

  void _registerHit(double delta) {
    final Judgment j = delta <= kPerfectWindow
        ? Judgment.perfect
        : delta <= kGreatWindow
            ? Judgment.great
            : Judgment.good;

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
    _score += (j.baseScore * comboMultiplier).round();
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
