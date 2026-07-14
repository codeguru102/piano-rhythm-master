import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/score_result.dart';
import '../models/song.dart';
import '../models/user_profile.dart';
import 'game_repository.dart';
import 'seed_songs.dart';

/// On-device implementation backed by SharedPreferences. Songs come from the
/// bundled seed set; profile and scores persist as JSON.
class LocalGameRepository implements GameRepository {
  static const _kProfile = 'prm_profile';
  static const _kScores = 'prm_scores';

  late final SharedPreferences _prefs;

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<List<Song>> fetchSongs() async => kSeedSongs;

  @override
  Future<UserProfile> loadProfile() async {
    final raw = _prefs.getString(_kProfile);
    if (raw == null) {
      final initial = UserProfile.initial();
      await saveProfile(initial);
      return initial;
    }
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return UserProfile.initial();
    }
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await _prefs.setString(_kProfile, jsonEncode(profile.toJson()));
  }

  @override
  Future<void> saveScore(ScoreResult result) async {
    final list = await fetchScores();
    list.add(result);
    // keep newest 200
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final trimmed = list.take(200).toList();
    await _prefs.setString(
      _kScores,
      jsonEncode(trimmed.map((e) => e.toJson()).toList()),
    );
  }

  @override
  Future<List<ScoreResult>> fetchScores({String? songId}) async {
    final raw = _prefs.getString(_kScores);
    if (raw == null) return [];
    final decoded = (jsonDecode(raw) as List)
        .map((e) => ScoreResult.fromJson(e as Map<String, dynamic>))
        .toList();
    if (songId != null) {
      return decoded.where((e) => e.songId == songId).toList();
    }
    return decoded;
  }
}
