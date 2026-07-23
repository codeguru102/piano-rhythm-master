import 'dart:typed_data';

/// A single note onset extracted from a MIDI file.
class MidiNote {
  final double time; // seconds from start
  final int pitch; // MIDI note number (0..127)
  final double duration; // seconds until note-off, when available
  const MidiNote(this.time, this.pitch, {this.duration = 0});
}

/// Result of parsing a Standard MIDI File.
class ParsedMidi {
  final List<MidiNote> notes; // sorted by time
  final int bpm; // initial tempo, rounded
  const ParsedMidi(this.notes, this.bpm);
}

class MidiParseException implements Exception {
  final String message;
  MidiParseException(this.message);
  @override
  String toString() => 'MidiParseException: $message';
}

/// Minimal, dependency-free Standard MIDI File (SMF) parser.
///
/// Extracts note-on events (with tempo-correct timing) from all tracks —
/// enough to turn a text2midi-generated `.mid` into a rhythm-game beat map.
/// Handles running status, variable-length delta times, tempo meta events,
/// SysEx skipping, and both PPQ and SMPTE time divisions.
class MidiParser {
  static ParsedMidi parse(Uint8List bytes) {
    final r = _Reader(bytes);

    if (r.readString(4) != 'MThd') {
      throw MidiParseException('Not a MIDI file (missing MThd header).');
    }
    final headerLen = r.readUint32();
    r.readUint16(); // format (unused: we merge all tracks)
    final ntrks = r.readUint16();
    final division = r.readUint16();
    if (headerLen > 6) r.skip(headerLen - 6);

    final bool smpte = (division & 0x8000) != 0;
    double secondsPerTickSmpte = 0;
    int ticksPerQuarter = 480;
    if (smpte) {
      final fps = 256 - ((division >> 8) & 0xFF); // 24/25/29/30
      final tpf = division & 0xFF;
      final denom = fps * tpf;
      secondsPerTickSmpte = denom == 0 ? 0 : 1.0 / denom;
    } else {
      ticksPerQuarter = (division & 0x7FFF) == 0 ? 480 : (division & 0x7FFF);
    }

    // Tempo changes collected across all tracks (absoluteTick -> us/quarter).
    final tempoTicks = <int>[];
    final tempoUs = <int>[];
    final noteTicks = <int>[];
    final noteEndTicks = <int>[];
    final notePitches = <int>[];

    for (var t = 0; t < ntrks; t++) {
      if (r.remaining < 8) break;
      final id = r.readString(4);
      final len = r.readUint32();
      final end = (r.pos + len).clamp(0, bytes.length);
      if (id != 'MTrk') {
        r.pos = end;
        continue;
      }
      int abs = 0;
      int runningStatus = 0;
      final activeNotes = <int, List<int>>{};

      void endNote(int channel, int pitch) {
        final starts = activeNotes[channel * 128 + pitch];
        if (starts == null || starts.isEmpty) return;
        noteEndTicks[starts.removeAt(0)] = abs;
      }

      while (r.pos < end) {
        abs += r.readVarLen();
        int status = r.peek();
        if (status < 0x80) {
          status = runningStatus; // running status: reuse last
        } else {
          r.pos++;
          runningStatus = status;
        }
        final hi = status & 0xF0;
        if (status == 0xFF) {
          final type = r.readByte();
          final metaLen = r.readVarLen();
          if (type == 0x51 && metaLen == 3) {
            tempoTicks.add(abs);
            tempoUs.add(
              (r.readByte() << 16) | (r.readByte() << 8) | r.readByte(),
            );
          } else {
            r.skip(metaLen);
          }
        } else if (status == 0xF0 || status == 0xF7) {
          r.skip(r.readVarLen());
        } else if (hi == 0x90) {
          final pitch = r.readByte();
          final vel = r.readByte();
          if (vel > 0) {
            noteTicks.add(abs);
            noteEndTicks.add(abs);
            notePitches.add(pitch);
            final key = (status & 0x0F) * 128 + pitch;
            activeNotes.putIfAbsent(key, () => []).add(noteTicks.length - 1);
          } else {
            endNote(status & 0x0F, pitch);
          }
        } else if (hi == 0x80) {
          final pitch = r.readByte();
          r.readByte();
          endNote(status & 0x0F, pitch);
        } else if (hi == 0xA0 || hi == 0xB0 || hi == 0xE0) {
          r.readByte();
          r.readByte();
        } else if (hi == 0xC0 || hi == 0xD0) {
          r.readByte();
        } else {
          break; // unrecognized — bail out of this track safely
        }
      }
      r.pos = end;
    }

    // Sort tempo events and guarantee a tempo at tick 0.
    final order = List<int>.generate(tempoTicks.length, (i) => i)
      ..sort((a, b) => tempoTicks[a].compareTo(tempoTicks[b]));
    final segTicks = <int>[];
    final segUs = <int>[];
    for (final i in order) {
      segTicks.add(tempoTicks[i]);
      segUs.add(tempoUs[i]);
    }
    if (segTicks.isEmpty || segTicks.first != 0) {
      segTicks.insert(0, 0);
      segUs.insert(0, 500000); // 120 BPM default
    }

    // Cumulative seconds at each tempo boundary for fast tick->seconds.
    final cum = List<double>.filled(segTicks.length, 0);
    for (var i = 1; i < segTicks.length; i++) {
      final secPerTick = (segUs[i - 1] / 1e6) / ticksPerQuarter;
      cum[i] = cum[i - 1] + (segTicks[i] - segTicks[i - 1]) * secPerTick;
    }

    double tickToSeconds(int tick) {
      if (smpte) return tick * secondsPerTickSmpte;
      var j = 0;
      for (var i = 0; i < segTicks.length; i++) {
        if (segTicks[i] <= tick) {
          j = i;
        } else {
          break;
        }
      }
      final secPerTick = (segUs[j] / 1e6) / ticksPerQuarter;
      return cum[j] + (tick - segTicks[j]) * secPerTick;
    }

    final notes = <MidiNote>[
      for (var i = 0; i < noteTicks.length; i++)
        MidiNote(
          tickToSeconds(noteTicks[i]),
          notePitches[i],
          duration:
              (tickToSeconds(noteEndTicks[i]) - tickToSeconds(noteTicks[i]))
                  .clamp(0, double.infinity),
        ),
    ]..sort((a, b) => a.time.compareTo(b.time));

    final bpm = smpte ? 120 : (60000000 / segUs.first).round();
    return ParsedMidi(notes, bpm);
  }
}

/// Big-endian byte reader for MIDI chunks.
class _Reader {
  _Reader(this._bytes) : _view = ByteData.sublistView(_bytes);
  final Uint8List _bytes;
  final ByteData _view;
  int pos = 0;

  int get remaining => _bytes.length - pos;

  String readString(int n) {
    final s = String.fromCharCodes(_bytes.sublist(pos, pos + n));
    pos += n;
    return s;
  }

  int readUint32() {
    final v = _view.getUint32(pos, Endian.big);
    pos += 4;
    return v;
  }

  int readUint16() {
    final v = _view.getUint16(pos, Endian.big);
    pos += 2;
    return v;
  }

  int readByte() => _bytes[pos++];
  int peek() => _bytes[pos];
  void skip(int n) => pos += n;

  /// MIDI variable-length quantity (7 bits per byte, high bit = continue).
  int readVarLen() {
    var value = 0;
    while (true) {
      final b = _bytes[pos++];
      value = (value << 7) | (b & 0x7F);
      if (b & 0x80 == 0) break;
    }
    return value;
  }
}
