import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/db_init.dart';
import 'data/sqlite_game_repository.dart';
import 'services/audio_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  final audio = AudioService();
  await audio.init();

  // Real on-device database (SQLite via sqflite) for profile / scores / songs.
  await initDatabaseFactory();
  final repo = SqliteGameRepository();
  await repo.init();

  runApp(PianoRhythmApp(prefs: prefs, audio: audio, repo: repo));
}
