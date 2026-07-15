import '../models/note_event.dart';
import '../models/song.dart';

/// Number of tile columns: C D E G.
const int kLaneCount = 4;

/// Lane index -> piano tone asset (see assets/sounds/).
const List<String> kLaneSounds = [
  'sounds/note_c4.wav',
  'sounds/note_d4.wav',
  'sounds/note_e4.wav',
  'sounds/note_g4.wav',
];

const List<String> kLaneLabels = ['C', 'D', 'E', 'G'];

/// Maps legacy 5-lane hand-authored patterns onto the 4 columns.
const List<int> _remap5to4 = [0, 1, 2, 3, 3];

const double _leadIn = 2.6;
const double _tail = 2.4;

/// Builds a beat map by looping [pattern] (lane index, or -1 for a rest)
/// at [stepsPerBeat] subdivisions until roughly [targetSeconds] of play.
List<NoteEvent> _gen({
  required int bpm,
  required List<int> pattern,
  required int stepsPerBeat,
  required double targetSeconds,
}) {
  final secondsPerBeat = 60.0 / bpm;
  final stepDur = secondsPerBeat / stepsPerBeat;
  // Keep the tile rate human-playable — never place notes closer than this.
  const minGap = 0.16;
  final notes = <NoteEvent>[];
  double t = _leadIn;
  double lastAdded = -999;
  int i = 0;
  while (t < _leadIn + targetSeconds) {
    final raw = pattern[i % pattern.length];
    if (raw >= 0 && t - lastAdded >= minGap) {
      final lane = raw < kLaneCount ? raw : _remap5to4[raw.clamp(0, 4)];
      notes.add(NoteEvent(double.parse(t.toStringAsFixed(3)), lane));
      lastAdded = t;
    }
    t += stepDur;
    i++;
  }
  return notes;
}

double _durationOf(List<NoteEvent> notes) =>
    (notes.isEmpty ? _leadIn : notes.last.time) + _tail;

Song _song({
  required String id,
  required String title,
  required String artist,
  required int coverSeed,
  required Difficulty difficulty,
  required int bpm,
  required int stepsPerBeat,
  required List<int> pattern,
  required double targetSeconds,
}) {
  final beatMap = _gen(
    bpm: bpm,
    pattern: pattern,
    stepsPerBeat: stepsPerBeat,
    targetSeconds: targetSeconds,
  );
  return Song(
    id: id,
    title: title,
    artist: artist,
    coverSeed: coverSeed,
    difficulty: difficulty,
    duration: _durationOf(beatMap),
    bpm: bpm,
    beatMap: beatMap,
  );
}

/// Original demo tracks with procedurally generated, melodic beat maps.
/// Swap this list for a Firestore query to go online — same [Song] model.
final List<Song> kSeedSongs = [
  _song(
    id: 'neon_sunrise',
    title: 'Neon Sunrise',
    artist: 'Aurora Synth',
    coverSeed: 0,
    difficulty: Difficulty.easy,
    bpm: 92,
    stepsPerBeat: 1,
    pattern: [0, 2, 4, 2, 1, 3, 1, -1, 0, 2, 4, -1, 3, 2, 0, -1],
    targetSeconds: 46,
  ),
  _song(
    id: 'midnight_keys',
    title: 'Midnight Keys',
    artist: 'Lumen',
    coverSeed: 1,
    difficulty: Difficulty.normal,
    bpm: 110,
    stepsPerBeat: 2,
    pattern: [0, -1, 2, 4, 3, -1, 2, 1, 0, 1, 2, -1, 4, 3, 2, 0],
    targetSeconds: 48,
  ),
  _song(
    id: 'crystal_waves',
    title: 'Crystal Waves',
    artist: 'Nova Tide',
    coverSeed: 3,
    difficulty: Difficulty.normal,
    bpm: 120,
    stepsPerBeat: 2,
    pattern: [4, 2, 0, 2, 4, 3, 1, 3, 0, 2, 4, 2, 1, 3, 2, 1],
    targetSeconds: 50,
  ),
  _song(
    id: 'electric_pulse',
    title: 'Electric Pulse',
    artist: 'Volt',
    coverSeed: 2,
    difficulty: Difficulty.hard,
    bpm: 140,
    stepsPerBeat: 2,
    pattern: [0, 1, 2, 3, 4, 3, 2, 1, 0, 2, 4, 2, 1, 3, 0, 4, 2, 0, 3, 1, 4, 2, 0, 1],
    targetSeconds: 52,
  ),
  _song(
    id: 'starlight_serenade',
    title: 'Starlight Serenade',
    artist: 'Aria Bloom',
    coverSeed: 4,
    difficulty: Difficulty.easy,
    bpm: 84,
    stepsPerBeat: 1,
    pattern: [2, 4, 3, 1, 0, 2, 1, -1, 3, 1, 2, 4, 0, -1, 2, -1],
    targetSeconds: 44,
  ),
  _song(
    id: 'bass_cascade',
    title: 'Bass Cascade',
    artist: 'Deep Circuit',
    coverSeed: 5,
    difficulty: Difficulty.expert,
    bpm: 160,
    stepsPerBeat: 4,
    pattern: [0, 4, 2, 4, 1, 3, 0, 2, 4, 2, 3, 1, 0, 2, 4, 3, 1, 3, 2, 0, 4, 2, 1, 0],
    targetSeconds: 55,
  ),
  _song(
    id: 'velvet_dawn',
    title: 'Velvet Dawn',
    artist: 'Aurora Synth',
    coverSeed: 6,
    difficulty: Difficulty.easy,
    bpm: 88,
    stepsPerBeat: 1,
    pattern: [1, 3, 2, 0, 4, 2, 3, -1, 0, 2, 4, 3, 1, 2, 0, -1],
    targetSeconds: 45,
  ),
  _song(
    id: 'prismatic',
    title: 'Prismatic',
    artist: 'Lumen',
    coverSeed: 7,
    difficulty: Difficulty.normal,
    bpm: 118,
    stepsPerBeat: 2,
    pattern: [0, 2, 1, 3, 4, 2, 3, 1, 2, 4, 3, 1, 0, 2, 4, 2, 1, 3, 2, 0, 3, 1, 2, 4],
    targetSeconds: 50,
  ),
  _song(
    id: 'thunder_run',
    title: 'Thunder Run',
    artist: 'Volt',
    coverSeed: 8,
    difficulty: Difficulty.hard,
    bpm: 148,
    stepsPerBeat: 2,
    pattern: [4, 3, 2, 1, 0, 1, 2, 3, 4, 2, 0, 2, 4, 1, 3, 0, 2, 4, 3, 1, 0, 2, 1, 4],
    targetSeconds: 52,
  ),
  _song(
    id: 'aurora_borealis',
    title: 'Aurora Borealis',
    artist: 'Nova Tide',
    coverSeed: 9,
    difficulty: Difficulty.normal,
    bpm: 126,
    stepsPerBeat: 2,
    pattern: [2, 4, 3, 1, 0, 2, 4, 2, 1, 3, 0, 2, 4, 3, 2, 0, 1, 3, 4, 2, 0, 2, 3, 1],
    targetSeconds: 50,
  ),
  _song(
    id: 'supernova',
    title: 'Supernova',
    artist: 'Deep Circuit',
    coverSeed: 10,
    difficulty: Difficulty.expert,
    bpm: 172,
    stepsPerBeat: 4,
    pattern: [0, 2, 4, 3, 1, 3, 2, 4, 0, 1, 2, 3, 4, 3, 2, 1, 0, 2, 4, 2, 1, 3, 0, 4],
    targetSeconds: 56,
  ),
];
