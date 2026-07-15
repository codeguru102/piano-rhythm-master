import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:piano_rhythm_master/services/midi_parser.dart';

/// A hand-built format-0 SMF: 120 BPM, 480 ticks/quarter, three quarter-note
/// note-ons (C4, E4, G4) at ticks 0, 480, 960.
Uint8List _sampleMidi() {
  return Uint8List.fromList([
    // MThd
    0x4D, 0x54, 0x68, 0x64, // "MThd"
    0x00, 0x00, 0x00, 0x06, // header length 6
    0x00, 0x00, // format 0
    0x00, 0x01, // 1 track
    0x01, 0xE0, // division = 480 ticks/quarter
    // MTrk
    0x4D, 0x54, 0x72, 0x6B, // "MTrk"
    0x00, 0x00, 0x00, 0x1D, // track length = 29 bytes
    // events
    0x00, 0xFF, 0x51, 0x03, 0x07, 0xA1, 0x20, // tempo 500000us (120 BPM)
    0x00, 0x90, 0x3C, 0x64, // note on C4 (60) @ tick 0
    0x83, 0x60, 0x90, 0x40, 0x64, // +480: note on E4 (64)
    0x83, 0x60, 0x90, 0x43, 0x64, // +480: note on G4 (67)
    0x00, 0x80, 0x43, 0x00, // note off G4
    0x00, 0xFF, 0x2F, 0x00, // end of track
  ]);
}

void main() {
  test('parses tempo, timing and pitches from a MIDI file', () {
    final parsed = MidiParser.parse(_sampleMidi());

    expect(parsed.bpm, 120);
    expect(parsed.notes.length, 3);

    expect(parsed.notes[0].pitch, 60);
    expect(parsed.notes[1].pitch, 64);
    expect(parsed.notes[2].pitch, 67);

    // At 120 BPM a quarter note = 0.5s.
    expect(parsed.notes[0].time, closeTo(0.0, 1e-6));
    expect(parsed.notes[1].time, closeTo(0.5, 1e-6));
    expect(parsed.notes[2].time, closeTo(1.0, 1e-6));
  });

  test('rejects non-MIDI input', () {
    expect(
      () => MidiParser.parse(Uint8List.fromList([1, 2, 3, 4])),
      throwsA(isA<MidiParseException>()),
    );
  });
}
