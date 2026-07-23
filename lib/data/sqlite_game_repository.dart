import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/score_result.dart';
import '../models/song.dart';
import '../models/user_profile.dart';
import 'game_repository.dart';
import 'seed_songs.dart';

/// SQLite-backed implementation of [GameRepository] (via sqflite).
///
/// Schema:
///  - profile(user_id PK, ... scalar columns ..., best_scores/favorites/
///    achievements as JSON text)  — one row, the local player
///  - scores(id PK, song_id, score, accuracy, combo, perfect, great, good,
///    miss, total_notes, timestamp)  — one row per completed play
///  - custom_songs(song_id PK, created_at, data)  — generated songs (JSON)
class SqliteGameRepository implements GameRepository {
  static const _dbName = 'piano_rhythm.db';
  static const _dbVersion = 1;

  late final Database _db;

  @override
  Future<void> init() async {
    final path = kIsWeb ? _dbName : p.join(await getDatabasesPath(), _dbName);
    _db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(version: _dbVersion, onCreate: _onCreate),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE profile (
        user_id TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        avatar TEXT NOT NULL,
        experience INTEGER NOT NULL,
        coins INTEGER NOT NULL,
        created_time INTEGER NOT NULL,
        total_songs_played INTEGER NOT NULL,
        highest_score INTEGER NOT NULL,
        highest_combo INTEGER NOT NULL,
        best_accuracy REAL NOT NULL,
        best_scores TEXT NOT NULL,
        favorites TEXT NOT NULL,
        achievements TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE scores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        song_id TEXT NOT NULL,
        score INTEGER NOT NULL,
        accuracy REAL NOT NULL,
        combo INTEGER NOT NULL,
        perfect INTEGER NOT NULL,
        great INTEGER NOT NULL,
        good INTEGER NOT NULL,
        miss INTEGER NOT NULL,
        total_notes INTEGER NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_scores_song ON scores(song_id)');
    await db.execute('''
      CREATE TABLE custom_songs (
        song_id TEXT PRIMARY KEY,
        created_at INTEGER NOT NULL,
        data TEXT NOT NULL
      )
    ''');
  }

  // ---- Songs -----------------------------------------------------------

  @override
  Future<List<Song>> fetchSongs() async {
    final rows = await _db.query('custom_songs', orderBy: 'created_at DESC');
    final custom = rows
        .map(
          (r) => Song.fromJson(
            jsonDecode(r['data'] as String) as Map<String, dynamic>,
          ),
        )
        .toList();
    return [...custom, ...kSeedSongs];
  }

  @override
  Future<void> saveCustomSong(Song song) async {
    await _db.insert('custom_songs', {
      'song_id': song.id,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'data': jsonEncode(song.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    // Keep only the newest 50 generated songs.
    await _db.execute('''
      DELETE FROM custom_songs WHERE song_id NOT IN (
        SELECT song_id FROM custom_songs ORDER BY created_at DESC LIMIT 50
      )
    ''');
  }

  // ---- Profile ---------------------------------------------------------

  @override
  Future<UserProfile> loadProfile() async {
    final rows = await _db.query('profile', limit: 1);
    if (rows.isEmpty) {
      final initial = UserProfile.initial();
      await saveProfile(initial);
      return initial;
    }
    final r = rows.first;
    return UserProfile.fromJson({
      'user_id': r['user_id'],
      'username': r['username'],
      'avatar': r['avatar'],
      'experience': r['experience'],
      'coins': r['coins'],
      'created_time': r['created_time'],
      'total_songs_played': r['total_songs_played'],
      'highest_score': r['highest_score'],
      'highest_combo': r['highest_combo'],
      'best_accuracy': r['best_accuracy'],
      'best_scores': jsonDecode(r['best_scores'] as String),
      'favorites': jsonDecode(r['favorites'] as String),
      'achievements': jsonDecode(r['achievements'] as String),
    });
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await _db.insert('profile', {
      'user_id': profile.userId,
      'username': profile.username,
      'avatar': profile.avatar,
      'experience': profile.experience,
      'coins': profile.coins,
      'created_time': profile.createdTime.millisecondsSinceEpoch,
      'total_songs_played': profile.totalSongsPlayed,
      'highest_score': profile.highestScore,
      'highest_combo': profile.highestCombo,
      'best_accuracy': profile.bestAccuracy,
      'best_scores': jsonEncode(profile.bestScores),
      'favorites': jsonEncode(profile.favorites.toList()),
      'achievements': jsonEncode(profile.achievements.toList()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ---- Scores ----------------------------------------------------------

  @override
  Future<void> saveScore(ScoreResult result) async {
    await _db.insert('scores', {
      'song_id': result.songId,
      'score': result.score,
      'accuracy': result.accuracy,
      'combo': result.maxCombo,
      'perfect': result.perfect,
      'great': result.great,
      'good': result.good,
      'miss': result.miss,
      'total_notes': result.totalNotes,
      'timestamp': result.timestamp.millisecondsSinceEpoch,
    });
    // Trim history to the newest 200.
    await _db.execute('''
      DELETE FROM scores WHERE id NOT IN (
        SELECT id FROM scores ORDER BY timestamp DESC LIMIT 200
      )
    ''');
  }

  @override
  Future<List<ScoreResult>> fetchScores({String? songId}) async {
    final rows = await _db.query(
      'scores',
      where: songId != null ? 'song_id = ?' : null,
      whereArgs: songId != null ? [songId] : null,
      orderBy: 'timestamp DESC',
    );
    return rows
        .map(
          (r) => ScoreResult.fromJson({
            'song_id': r['song_id'],
            'score': r['score'],
            'accuracy': r['accuracy'],
            'combo': r['combo'],
            'perfect': r['perfect'],
            'great': r['great'],
            'good': r['good'],
            'miss': r['miss'],
            'total_notes': r['total_notes'],
            'timestamp': r['timestamp'],
          }),
        )
        .toList();
  }
}
