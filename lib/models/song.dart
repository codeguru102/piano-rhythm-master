import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'note_event.dart';

enum Difficulty { easy, normal, hard, expert }

extension DifficultyX on Difficulty {
  String get label => switch (this) {
    Difficulty.easy => 'Easy',
    Difficulty.normal => 'Normal',
    Difficulty.hard => 'Hard',
    Difficulty.expert => 'Expert',
  };

  Color get color => switch (this) {
    Difficulty.easy => AppColors.easy,
    Difficulty.normal => AppColors.normal,
    Difficulty.hard => AppColors.hard,
    Difficulty.expert => AppColors.expert,
  };

  /// Seconds a note takes to travel from spawn to the hit line.
  /// Lower = faster/harder. Adjusted further by the user's note-speed setting.
  double get baseApproach => switch (this) {
    Difficulty.easy => 2.1,
    Difficulty.normal => 1.6,
    Difficulty.hard => 1.2,
    Difficulty.expert => 0.9,
  };

  static Difficulty fromName(String name) => Difficulty.values.firstWhere(
    (d) => d.name == name,
    orElse: () => Difficulty.normal,
  );
}

/// A playable song. Mirrors the Firebase `Songs` collection so a remote
/// implementation can deserialize into the same model.
class Song {
  final String id;
  final String title;
  final String artist;
  final int
  coverSeed; // deterministic gradient cover (stands in for cover_image)
  final String? audioFile; // reserved for real backing tracks
  final Difficulty difficulty;
  final double duration; // seconds
  final int bpm;
  final List<NoteEvent> beatMap;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.coverSeed,
    required this.difficulty,
    required this.duration,
    required this.bpm,
    required this.beatMap,
    this.audioFile,
  });

  int get noteCount => beatMap.length;

  factory Song.fromJson(Map<String, dynamic> json) => Song(
    id: json['song_id'] as String,
    title: json['title'] as String,
    artist: json['artist'] as String,
    coverSeed: json['cover_seed'] as int? ?? 0,
    audioFile: json['audio_file'] as String?,
    difficulty: DifficultyX.fromName(json['difficulty'] as String),
    duration: (json['duration'] as num).toDouble(),
    bpm: json['bpm'] as int? ?? 120,
    beatMap: (json['beat_map'] as List)
        .map((e) => NoteEvent.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'song_id': id,
    'title': title,
    'artist': artist,
    'cover_seed': coverSeed,
    'audio_file': audioFile,
    'difficulty': difficulty.name,
    'duration': duration,
    'bpm': bpm,
    'beat_map': beatMap.map((e) => e.toJson()).toList(),
  };
}
