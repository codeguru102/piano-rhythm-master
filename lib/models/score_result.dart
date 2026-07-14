/// Result of one completed play. Mirrors the Firebase `Scores` collection.
class ScoreResult {
  final String songId;
  final int score;
  final double accuracy; // 0..100
  final int maxCombo;
  final int perfect;
  final int great;
  final int good;
  final int miss;
  final int totalNotes;
  final DateTime timestamp;

  const ScoreResult({
    required this.songId,
    required this.score,
    required this.accuracy,
    required this.maxCombo,
    required this.perfect,
    required this.great,
    required this.good,
    required this.miss,
    required this.totalNotes,
    required this.timestamp,
  });

  int get hits => perfect + great + good;

  /// Star rating 0..3 based on accuracy.
  int get stars {
    if (accuracy >= 95) return 3;
    if (accuracy >= 80) return 2;
    if (accuracy >= 60) return 1;
    return 0;
  }

  String get rank {
    if (accuracy >= 98) return 'S';
    if (accuracy >= 90) return 'A';
    if (accuracy >= 80) return 'B';
    if (accuracy >= 65) return 'C';
    return 'D';
  }

  factory ScoreResult.fromJson(Map<String, dynamic> json) => ScoreResult(
        songId: json['song_id'] as String,
        score: json['score'] as int,
        accuracy: (json['accuracy'] as num).toDouble(),
        maxCombo: json['combo'] as int,
        perfect: json['perfect'] as int? ?? 0,
        great: json['great'] as int? ?? 0,
        good: json['good'] as int? ?? 0,
        miss: json['miss'] as int? ?? 0,
        totalNotes: json['total_notes'] as int? ?? 0,
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      );

  Map<String, dynamic> toJson() => {
        'song_id': songId,
        'score': score,
        'accuracy': accuracy,
        'combo': maxCombo,
        'perfect': perfect,
        'great': great,
        'good': good,
        'miss': miss,
        'total_notes': totalNotes,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };
}
