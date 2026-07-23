import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../data/seed_songs.dart';

/// Low-latency, polyphonic playback for piano notes and UI blips.
///
/// Uses a small round-robin pool of players so rapidly tapped / overlapping
/// notes don't cut each other off. Works on web and mobile.
class AudioService {
  static const int _poolSize = 12;
  final List<AudioPlayer> _pool = [];
  int _idx = 0;

  bool sfxEnabled = true;
  double sfxVolume = 0.9;

  Future<void> init() async {
    for (var i = 0; i < _poolSize; i++) {
      final p = AudioPlayer(playerId: 'sfx_$i');
      await p.setReleaseMode(ReleaseMode.stop);
      _pool.add(p);
    }
  }

  void _play(String asset, double volume) {
    if (!sfxEnabled || _pool.isEmpty) return;
    final p = _pool[_idx];
    _idx = (_idx + 1) % _pool.length;
    unawaited(_playSafely(p, asset, volume));
  }

  Future<void> _playSafely(
    AudioPlayer player,
    String asset,
    double volume,
  ) async {
    try {
      // Keep stop/source/play ordered. Starting both futures together can race
      // on the first note while the native player is still being prepared.
      await player.stop();
      await player.play(
        AssetSource(asset),
        volume: (volume * sfxVolume).clamp(0.0, 1.0),
      );
    } catch (error) {
      // Audio is supporting feedback. A device/audio-session problem should
      // never interrupt scoring or take the player out of the game.
      debugPrint('Unable to play $asset: $error');
    }
  }

  void playLane(int lane) {
    if (lane < 0 || lane >= kLaneSounds.length) return;
    _play(kLaneSounds[lane], 1.0);
  }

  void playTap() => _play('sounds/ui_tap.wav', 0.5);

  Future<void> dispose() async {
    for (final p in _pool) {
      await p.dispose();
    }
    _pool.clear();
  }
}
