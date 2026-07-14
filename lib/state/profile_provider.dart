import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../data/game_repository.dart';
import '../models/achievement.dart';
import '../models/score_result.dart';
import '../models/user_profile.dart';

/// Holds the player profile and applies progression after each play.
class ProfileProvider extends ChangeNotifier {
  ProfileProvider(this._repo);

  final GameRepository _repo;

  UserProfile _profile = UserProfile.initial();
  UserProfile get profile => _profile;

  bool _loggedIn = true;
  bool get loggedIn => _loggedIn;

  Future<void> load() async {
    _profile = await _repo.loadProfile();
    notifyListeners();
  }

  bool isFavorite(String songId) => _profile.favorites.contains(songId);

  int bestScore(String songId) => _profile.bestScores[songId] ?? 0;

  Future<void> toggleFavorite(String songId) async {
    final favs = Set<String>.from(_profile.favorites);
    if (!favs.add(songId)) favs.remove(songId);
    _profile = _profile.copyWith(favorites: favs);
    await _repo.saveProfile(_profile);
    notifyListeners();
  }

  Future<void> updateIdentity({String? username, String? avatar}) async {
    _profile = _profile.copyWith(username: username, avatar: avatar);
    await _repo.saveProfile(_profile);
    notifyListeners();
  }

  /// Applies a finished game's result: XP, coins, records, achievements.
  /// Returns any achievements unlocked by this result (for the popup).
  Future<List<Achievement>> applyResult(ScoreResult result) async {
    final before = _profile.achievements;

    final newBest = Map<String, int>.from(_profile.bestScores);
    newBest[result.songId] =
        math.max(newBest[result.songId] ?? 0, result.score);

    final xpGain = (result.score / 8).round() + result.perfect;
    final coinGain = result.stars * 25 + result.hits ~/ 4;

    var updated = _profile.copyWith(
      experience: _profile.experience + xpGain,
      coins: _profile.coins + coinGain,
      totalSongsPlayed: _profile.totalSongsPlayed + 1,
      highestScore: math.max(_profile.highestScore, result.score),
      highestCombo: math.max(_profile.highestCombo, result.maxCombo),
      bestAccuracy: math.max(_profile.bestAccuracy, result.accuracy),
      bestScores: newBest,
    );

    final unlocked = _evaluateAchievements(updated);
    if (unlocked.isNotEmpty) {
      updated = updated.copyWith(
        achievements: {...updated.achievements, ...unlocked.map((a) => a.id)},
      );
    }

    _profile = updated;
    await _repo.saveProfile(_profile);
    notifyListeners();

    return unlocked.where((a) => !before.contains(a.id)).toList();
  }

  List<Achievement> _evaluateAchievements(UserProfile p) {
    bool test(String id) {
      switch (id) {
        case 'first_song':
          return p.totalSongsPlayed >= 1;
        case 'combo_50':
          return p.highestCombo >= 50;
        case 'combo_100':
          return p.highestCombo >= 100;
        case 'accuracy_95':
          return p.bestAccuracy >= 95;
        case 'score_50k':
          return p.highestScore >= 50000;
        case 'level_5':
          return p.level >= 5;
      }
      return false;
    }

    return kAchievements
        .where((a) => !p.achievements.contains(a.id) && test(a.id))
        .toList();
  }

  void logout() {
    _loggedIn = false;
    notifyListeners();
  }

  void login() {
    _loggedIn = true;
    notifyListeners();
  }
}
