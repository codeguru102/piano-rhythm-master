import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/song.dart';
import '../services/audio_service.dart';
import 'game_controller.dart';

/// User-adjustable audio and gameplay preferences (Settings screen).
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._prefs, this._audio) {
    _load();
  }

  final SharedPreferences _prefs;
  final AudioService _audio;

  double _musicVolume = 0.7;
  double _sfxVolume = 0.9;
  bool _vibration = true;
  double _noteSpeed = 1.0; // multiplier: higher = faster falling notes
  bool _leftHandMode = false;
  Difficulty _preferredDifficulty = Difficulty.normal;
  GameMode _gameMode = GameMode.song;

  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;
  bool get vibration => _vibration;
  double get noteSpeed => _noteSpeed;
  bool get leftHandMode => _leftHandMode;
  Difficulty get preferredDifficulty => _preferredDifficulty;
  GameMode get gameMode => _gameMode;
  bool get classicMode => _gameMode == GameMode.classic;

  void _load() {
    _musicVolume = _prefs.getDouble('set_music') ?? 0.7;
    _sfxVolume = _prefs.getDouble('set_sfx') ?? 0.9;
    _vibration = _prefs.getBool('set_vibration') ?? true;
    _noteSpeed = _prefs.getDouble('set_note_speed') ?? 1.0;
    _leftHandMode = _prefs.getBool('set_left_hand') ?? false;
    _preferredDifficulty = DifficultyX.fromName(
        _prefs.getString('set_difficulty') ?? Difficulty.normal.name);
    _gameMode = (_prefs.getString('set_game_mode') == 'classic')
        ? GameMode.classic
        : GameMode.song;
    _syncAudio();
  }

  void _syncAudio() {
    _audio.sfxVolume = _sfxVolume;
    _audio.sfxEnabled = _sfxVolume > 0;
  }

  void setMusicVolume(double v) {
    _musicVolume = v;
    _prefs.setDouble('set_music', v);
    notifyListeners();
  }

  void setSfxVolume(double v) {
    _sfxVolume = v;
    _prefs.setDouble('set_sfx', v);
    _syncAudio();
    notifyListeners();
  }

  void setVibration(bool v) {
    _vibration = v;
    _prefs.setBool('set_vibration', v);
    notifyListeners();
  }

  void setNoteSpeed(double v) {
    _noteSpeed = v;
    _prefs.setDouble('set_note_speed', v);
    notifyListeners();
  }

  void setLeftHandMode(bool v) {
    _leftHandMode = v;
    _prefs.setBool('set_left_hand', v);
    notifyListeners();
  }

  void setPreferredDifficulty(Difficulty d) {
    _preferredDifficulty = d;
    _prefs.setString('set_difficulty', d.name);
    notifyListeners();
  }

  void setClassicMode(bool on) {
    _gameMode = on ? GameMode.classic : GameMode.song;
    _prefs.setString('set_game_mode', on ? 'classic' : 'song');
    notifyListeners();
  }
}
