import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../data/game_repository.dart';
import '../models/song.dart';
import '../state/profile_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';
import '../widgets/gradient_text.dart';
import '../widgets/song_card.dart';
import 'create_song_screen.dart';
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
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _songsFuture = context.read<GameRepository>().fetchSongs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _songsFuture = context.read<GameRepository>().fetchSongs();
    });
  }

  Future<void> _openCreate() async {
    await Navigator.of(
      context,
    ).push(AppRoutes.fadeSlide(const CreateSongScreen()));
    if (mounted) _refresh(); // show any newly generated song
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _filter = _Filter.all;
    });
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('YOUR MUSIC', style: AppTextStyles.label),
                          SizedBox(height: 4),
                          GradientText(
                            'Find your rhythm',
                            gradient: AppGradients.aurora,
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Pick a track and make it yours.',
                            style: AppTextStyles.bodyMuted,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _createButton(),
                  ],
                ),
              ),
              _searchField(),
              _filterRow(),
              Expanded(
                child: FutureBuilder<List<Song>>(
                  future: _songsFuture,
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const _SongListSkeleton();
                    }
                    final songs = snap.data!
                        .where((s) => _matches(s, profile))
                        .toList();
                    if (songs.isEmpty) {
                      return _EmptyState(onClear: _clearFilters);
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
                      itemCount: songs.length + 1,
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Text(
                                  '${songs.length} ${songs.length == 1 ? 'song' : 'songs'}',
                                  style: AppTextStyles.cardTitle,
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: AppColors.neonCyan,
                                  size: 15,
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  'Recommended',
                                  style: AppTextStyles.label,
                                ),
                              ],
                            ),
                          );
                        }
                        final s = songs[i - 1];
                        return SongCard(
                              song: s,
                              bestScore: profile.bestScore(s.id),
                              isFavorite: profile.isFavorite(s.id),
                              onToggleFavorite: () =>
                                  profile.toggleFavorite(s.id),
                              onPlay: () => Navigator.of(
                                context,
                              ).push(AppRoutes.fadeSlide(GameScreen(song: s))),
                            )
                            .animate(delay: (35 * (i - 1)).ms)
                            .fadeIn(duration: 280.ms)
                            .slideY(begin: 0.025, end: 0);
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

  Widget _createButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openCreate,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: Colors.white24),
            boxShadow: glow(AppColors.neonPurple, blur: 14, opacity: 0.36),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
              SizedBox(width: 6),
              Text(
                'Create',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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
        controller: _searchController,
        onChanged: (v) => setState(() => _query = v),
        style: const TextStyle(color: AppColors.textHi),
        decoration: InputDecoration(
          hintText: 'Search songs or artists',
          hintStyle: const TextStyle(color: AppColors.textLow),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textLow,
          ),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
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
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _filter = f),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  child: AnimatedContainer(
                    duration: AppMotion.state,
                    curve: AppMotion.standard,
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
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: AppColors.neonPurple.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.music_off_rounded,
              color: AppColors.neonPurple,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          const Text('No rhythm found', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 6),
          const Text(
            'Try another search or reset your filters.',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reset filters'),
          ),
        ],
      ),
    );
  }
}

class _SongListSkeleton extends StatelessWidget {
  const _SongListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      itemCount: 5,
      itemBuilder: (context, index) =>
          Container(
                height: 112,
                margin: const EdgeInsets.only(bottom: AppSpace.sm),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.all(color: AppColors.stroke),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                duration: 1300.ms,
                color: Colors.white.withValues(alpha: 0.07),
              ),
    );
  }
}
