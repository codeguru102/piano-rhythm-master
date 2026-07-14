import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/game_repository.dart';
import '../models/score_result.dart';
import '../models/song.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';

/// Local leaderboard of the player's best runs. The repository interface
/// already supports remote scores, so this becomes an online leaderboard by
/// swapping the repository implementation.
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  late final Future<(List<ScoreResult>, Map<String, Song>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(List<ScoreResult>, Map<String, Song>)> _load() async {
    final repo = context.read<GameRepository>();
    final scores = await repo.fetchScores();
    final songs = await repo.fetchSongs();
    scores.sort((a, b) => b.score.compareTo(a.score));
    return (scores.take(50).toList(), {for (final s in songs) s.id: s});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ranking')),
      body: GradientBackground(
        child: SafeArea(
          child: FutureBuilder<(List<ScoreResult>, Map<String, Song>)>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.neonPurple));
              }
              final (scores, songs) = snap.data!;
              if (scores.isEmpty) return const _Empty();
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                itemCount: scores.length,
                itemBuilder: (context, i) =>
                    _row(i + 1, scores[i], songs[scores[i].songId]),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _row(int rank, ScoreResult r, Song? song) {
    final medal = switch (rank) {
      1 => AppColors.good,
      2 => AppColors.textMid,
      3 => AppColors.expert,
      _ => AppColors.textLow,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        gradient: AppGradients.panel,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
            color: rank <= 3 ? medal.withValues(alpha: 0.5) : AppColors.stroke),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: rank <= 3
                ? Icon(Icons.emoji_events_rounded, color: medal, size: 26)
                : Text('#$rank',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textMid,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(song?.title ?? r.songId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textHi,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                Text('${r.accuracy.toStringAsFixed(1)}% • ${r.maxCombo}x combo',
                    style: const TextStyle(
                        color: AppColors.textMid, fontSize: 12)),
              ],
            ),
          ),
          Text(
            '${r.score}',
            style: const TextStyle(
                color: AppColors.good,
                fontSize: 17,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.leaderboard_rounded, color: AppColors.textLow, size: 48),
          SizedBox(height: 12),
          Text('No scores yet — play a song!',
              style: TextStyle(color: AppColors.textMid, fontSize: 15)),
        ],
      ),
    );
  }
}
