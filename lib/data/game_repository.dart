import '../models/score_result.dart';
import '../models/song.dart';
import '../models/user_profile.dart';

/// Storage abstraction for songs, profile and scores.
///
/// The app talks only to this interface, so the local implementation used
/// today can be swapped for a Firebase/Firestore-backed one with no changes
/// to the UI or game logic. Method shapes map 1:1 onto the collections
/// described in the spec (Users / Songs / Scores).
abstract class GameRepository {
  Future<void> init();

  // Songs collection
  Future<List<Song>> fetchSongs();

  // Users collection
  Future<UserProfile> loadProfile();
  Future<void> saveProfile(UserProfile profile);

  // Scores collection
  Future<void> saveScore(ScoreResult result);
  Future<List<ScoreResult>> fetchScores({String? songId});
}
