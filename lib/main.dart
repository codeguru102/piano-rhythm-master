import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/local_game_repository.dart';
import 'services/audio_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  final audio = AudioService();
  await audio.init();

  final repo = LocalGameRepository();
  await repo.init();

  runApp(PianoRhythmApp(prefs: prefs, audio: audio, repo: repo));
}
