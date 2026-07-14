import 'dart:math' as math;

/// Player profile. Mirrors the Firebase `Users` collection, plus locally
/// tracked progression stats.
class UserProfile {
  final String userId;
  final String username;
  final String avatar; // emoji stand-in for an avatar image
  final int experience;
  final int coins;
  final DateTime createdTime;

  // progression stats
  final int totalSongsPlayed;
  final int highestScore;
  final int highestCombo;
  final double bestAccuracy;
  final Map<String, int> bestScores; // songId -> best score
  final Set<String> favorites; // favorite songIds
  final Set<String> achievements; // unlocked achievement ids

  const UserProfile({
    required this.userId,
    required this.username,
    required this.avatar,
    required this.experience,
    required this.coins,
    required this.createdTime,
    this.totalSongsPlayed = 0,
    this.highestScore = 0,
    this.highestCombo = 0,
    this.bestAccuracy = 0,
    this.bestScores = const {},
    this.favorites = const {},
    this.achievements = const {},
  });

  factory UserProfile.initial() => UserProfile(
        userId: 'local-player',
        username: 'Player One',
        avatar: '🎧',
        experience: 0,
        coins: 250,
        createdTime: DateTime(2024, 1, 1),
      );

  /// XP required to have reached the start of [level].
  static int xpForLevel(int level) => 300 * (level - 1) * (level - 1);

  int get level => 1 + math.sqrt(experience / 300).floor();

  int get xpIntoLevel => experience - xpForLevel(level);
  int get xpForNextLevel => xpForLevel(level + 1) - xpForLevel(level);
  double get levelProgress =>
      xpForNextLevel == 0 ? 0 : (xpIntoLevel / xpForNextLevel).clamp(0.0, 1.0);

  UserProfile copyWith({
    String? username,
    String? avatar,
    int? experience,
    int? coins,
    int? totalSongsPlayed,
    int? highestScore,
    int? highestCombo,
    double? bestAccuracy,
    Map<String, int>? bestScores,
    Set<String>? favorites,
    Set<String>? achievements,
  }) {
    return UserProfile(
      userId: userId,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      experience: experience ?? this.experience,
      coins: coins ?? this.coins,
      createdTime: createdTime,
      totalSongsPlayed: totalSongsPlayed ?? this.totalSongsPlayed,
      highestScore: highestScore ?? this.highestScore,
      highestCombo: highestCombo ?? this.highestCombo,
      bestAccuracy: bestAccuracy ?? this.bestAccuracy,
      bestScores: bestScores ?? this.bestScores,
      favorites: favorites ?? this.favorites,
      achievements: achievements ?? this.achievements,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        userId: json['user_id'] as String,
        username: json['username'] as String,
        avatar: json['avatar'] as String? ?? '🎧',
        experience: json['experience'] as int? ?? 0,
        coins: json['coins'] as int? ?? 0,
        createdTime:
            DateTime.fromMillisecondsSinceEpoch(json['created_time'] as int),
        totalSongsPlayed: json['total_songs_played'] as int? ?? 0,
        highestScore: json['highest_score'] as int? ?? 0,
        highestCombo: json['highest_combo'] as int? ?? 0,
        bestAccuracy: (json['best_accuracy'] as num?)?.toDouble() ?? 0,
        bestScores: (json['best_scores'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v as int)),
        favorites:
            ((json['favorites'] as List?) ?? []).map((e) => e as String).toSet(),
        achievements: ((json['achievements'] as List?) ?? [])
            .map((e) => e as String)
            .toSet(),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'username': username,
        'avatar': avatar,
        'level': level,
        'experience': experience,
        'coins': coins,
        'created_time': createdTime.millisecondsSinceEpoch,
        'total_songs_played': totalSongsPlayed,
        'highest_score': highestScore,
        'highest_combo': highestCombo,
        'best_accuracy': bestAccuracy,
        'best_scores': bestScores,
        'favorites': favorites.toList(),
        'achievements': achievements.toList(),
      };
}
