import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/note_event.dart';
import '../models/song.dart';
import 'midi_parser.dart';

/// Calls a user-hosted text2midi endpoint and turns the returned MIDI into a
/// playable [Song] for the 5-lane rhythm engine.
///
/// Endpoint contract:
/// ```
/// POST {baseUrl}
/// body:    {"prompt": "text", "difficulty": "normal"}
/// returns: raw MIDI  (Content-Type audio/midi, body = .mid bytes)
///      or  JSON       {"midi_base64": "base64 of .mid"}
/// ```
class TextToMidiClient {
  TextToMidiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Lane sound pitch classes: C, D, E, G (semitones within an octave).
  static const List<int> _lanePitchClasses = [0, 2, 4, 7];

  static const double _leadIn = 2.6; // matches seed songs' intro countdown
  static const double _tail = 2.4;
  static const double _clusterEps = 0.07; // merge near-simultaneous notes
  static const double _minGap = 0.16; // floor on spacing for playability

  Future<Song> generate({
    required String baseUrl,
    required String prompt,
    required Difficulty difficulty,
  }) async {
    final url = baseUrl.trim();
    if (url.isEmpty) {
      throw const TextToMidiException(
        'Generator endpoint not configured. Provide MIDI_API_URL via '
        '--dart-define (see config/app_config.example.json).',
      );
    }
    if (prompt.trim().isEmpty) {
      throw const TextToMidiException('Enter a description for your song.');
    }

    late final http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'prompt': prompt.trim(),
              'difficulty': difficulty.name,
            }),
          )
          .timeout(const Duration(seconds: 90));
    } catch (e) {
      throw TextToMidiException('Could not reach the generator: $e');
    }

    if (res.statusCode != 200) {
      throw TextToMidiException(
        'Generator returned ${res.statusCode}: ${_snippet(res.body)}',
      );
    }

    final midiBytes = _extractMidi(res);
    final parsed = _parse(midiBytes);
    if (parsed.notes.isEmpty) {
      throw const TextToMidiException(
        'The generated MIDI had no playable notes. Try a different prompt.',
      );
    }

    final beatMap = _toBeatMap(parsed);
    final title = _title(prompt);
    return Song(
      id: 'gen_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      artist: 'text2midi',
      coverSeed: prompt.hashCode & 0x7fffffff,
      difficulty: difficulty,
      duration:
          (beatMap.isEmpty
              ? _leadIn
              : beatMap
                    .map((note) => note.time + note.duration)
                    .reduce(math.max)) +
          _tail,
      bpm: parsed.bpm.clamp(40, 220),
      beatMap: beatMap,
    );
  }

  ParsedMidi _parse(Uint8List bytes) {
    try {
      return MidiParser.parse(bytes);
    } on MidiParseException catch (e) {
      throw TextToMidiException(e.message);
    } catch (e) {
      throw TextToMidiException('Failed to read MIDI: $e');
    }
  }

  /// Reduce parsed MIDI to a monophonic, evenly-playable 5-lane beat map.
  List<NoteEvent> _toBeatMap(ParsedMidi parsed) {
    // 1. Merge chords: within each time cluster keep the highest pitch (melody).
    final melody = <MidiNote>[];
    for (final n in parsed.notes) {
      if (melody.isNotEmpty && (n.time - melody.last.time) <= _clusterEps) {
        if (n.pitch > melody.last.pitch) melody[melody.length - 1] = n;
      } else {
        melody.add(n);
      }
    }

    // 2. Enforce a minimum spacing so runs stay tappable.
    final spaced = <MidiNote>[];
    for (final n in melody) {
      if (spaced.isEmpty || (n.time - spaced.last.time) >= _minGap) {
        spaced.add(n);
      }
    }

    // 3. Normalize so the first note lands after the lead-in countdown.
    final first = spaced.first.time;
    final events = <NoteEvent>[];
    for (var i = 0; i < spaced.length; i++) {
      final note = spaced[i];
      final lane = _laneForPitch(note.pitch);
      double nextSameLane = double.infinity;
      for (var next = i + 1; next < spaced.length; next++) {
        if (_laneForPitch(spaced[next].pitch) == lane) {
          nextSameLane = spaced[next].time;
          break;
        }
      }
      final available = nextSameLane - note.time - 0.16;
      final duration = note.duration >= 0.5 && available >= 0.42
          ? math.min(note.duration, available).clamp(0.42, 2.4)
          : 0.0;
      events.add(
        NoteEvent(
          double.parse((note.time - first + _leadIn).toStringAsFixed(3)),
          lane,
          duration: double.parse(duration.toStringAsFixed(3)),
        ),
      );
    }
    return events;
  }

  /// Quantize a MIDI pitch to the nearest of the 5 lane tones (C D E F G).
  int _laneForPitch(int pitch) {
    final pc = pitch % 12;
    var bestLane = 0;
    var bestDist = 99;
    for (var i = 0; i < _lanePitchClasses.length; i++) {
      final d = (pc - _lanePitchClasses[i]).abs();
      if (d < bestDist) {
        bestDist = d;
        bestLane = i;
      }
    }
    return bestLane;
  }

  Uint8List _extractMidi(http.Response res) {
    final body = res.bodyBytes;
    // Raw MIDI starts with the ASCII header "MThd".
    if (body.length >= 4 &&
        body[0] == 0x4D &&
        body[1] == 0x54 &&
        body[2] == 0x68 &&
        body[3] == 0x64) {
      return body;
    }
    // Otherwise expect JSON with a base64 payload.
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map) {
        final b64 =
            decoded['midi_base64'] ?? decoded['midi'] ?? decoded['data'];
        if (b64 is String && b64.isNotEmpty) {
          return base64Decode(b64.replaceAll(RegExp(r'\s'), ''));
        }
      }
    } catch (_) {
      // fall through to error below
    }
    throw TextToMidiException(
      'Unexpected response (not MIDI or {midi_base64}): ${_snippet(res.body)}',
    );
  }

  String _title(String prompt) {
    final clean = prompt.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.length <= 30) return clean;
    return '${clean.substring(0, 29)}…';
  }

  String _snippet(String body) =>
      body.length <= 120 ? body : '${body.substring(0, 120)}…';

  void dispose() => _client.close();
}

class TextToMidiException implements Exception {
  final String message;
  const TextToMidiException(this.message);
  @override
  String toString() => message;
}
