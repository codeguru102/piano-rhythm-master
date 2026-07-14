import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../data/game_repository.dart';
import '../models/song.dart';
import '../state/profile_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';
import '../widgets/gradient_text.dart';
import '../widgets/song_card.dart';
import 'game_screen.dart';

/// "Choose Your Song" — search, category filters, and song cards.
class SongSelectionScreen extends StatefulWidget {
  const SongSelectionScreen({super.key});

  @override
  State<SongSelectionScreen> createState() => _SongSelectionScreenState();
}

enum _Filter { all, favorites, easy, normal, hard, expert }

extension on _Filter {
  String get label => switch (this) {
        _Filter.all => 'All',
        _Filter.favorites => 'Favorites',
        _Filter.easy => 'Easy',
        _Filter.normal => 'Normal',
        _Filter.hard => 'Hard',
        _Filter.expert => 'Expert',
      };
}

class _SongSelectionScreenState extends State<SongSelectionScreen> {
  String _query = '';
  _Filter _filter = _Filter.all;
  late Future<List<Song>> _songsFuture;

  @override
  void initState() {
    super.initState();
    _songsFuture = context.read<GameRepository>().fetchSongs();
  }

  bool _matches(Song s, ProfileProvider profile) {
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      if (!s.title.toLowerCase().contains(q) &&
          !s.artist.toLowerCase().contains(q)) {
        return false;
      }
    }
    switch (_filter) {
      case _Filter.all:
        return true;
      case _Filter.favorites:
        return profile.isFavorite(s.id);
      case _Filter.easy:
        return s.difficulty == Difficulty.easy;
      case _Filter.normal:
        return s.difficulty == Difficulty.normal;
      case _Filter.hard:
        return s.difficulty == Difficulty.hard;
      case _Filter.expert:
        return s.difficulty == Difficulty.expert;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GradientText(
                    'Choose Your Song',
                    gradient: AppGradients.aurora,
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              _searchField(),
              _filterRow(),
              Expanded(
                child: FutureBuilder<List<Song>>(
                  future: _songsFuture,
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.neonPurple),
                      );
                    }
                    final songs =
                        snap.data!.where((s) => _matches(s, profile)).toList();
                    if (songs.isEmpty) {
                      return const _EmptyState();
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                      itemCount: songs.length,
                      itemBuilder: (context, i) {
                        final s = songs[i];
                        return SongCard(
                          song: s,
                          bestScore: profile.bestScore(s.id),
                          isFavorite: profile.isFavorite(s.id),
                          onToggleFavorite: () => profile.toggleFavorite(s.id),
                          onPlay: () => Navigator.of(context)
                              .push(AppRoutes.fadeSlide(GameScreen(song: s))),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: TextField(
        onChanged: (v) => setState(() => _query = v),
        style: const TextStyle(color: AppColors.textHi),
        decoration: InputDecoration(
          hintText: 'Search songs or artists',
          hintStyle: const TextStyle(color: AppColors.textLow),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textLow),
          filled: true,
          fillColor: AppColors.panel,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
            borderSide: const BorderSide(color: AppColors.stroke),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
            borderSide: const BorderSide(color: AppColors.neonPurple),
          ),
        ),
      ),
    );
  }

  Widget _filterRow() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          for (final f in _Filter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: _filter == f ? AppGradients.primary : null,
                    color: _filter == f ? null : AppColors.panel,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    border: Border.all(color: AppColors.stroke),
                  ),
                  child: Text(
                    f.label,
                    style: TextStyle(
                      color: _filter == f ? Colors.white : AppColors.textMid,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, color: AppColors.textLow, size: 48),
          SizedBox(height: 12),
          Text('No songs found',
              style: TextStyle(color: AppColors.textMid, fontSize: 15)),
        ],
      ),
    );
  }
}
