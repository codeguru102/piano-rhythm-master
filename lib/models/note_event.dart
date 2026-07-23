/// A single note in a song's beat map: hit [lane] at [time] seconds.
class NoteEvent {
  final double time; // seconds from song start
  final int lane; // 0..laneCount-1
  final double duration; // sustain length in seconds; 0 means a tap note

  const NoteEvent(this.time, this.lane, {this.duration = 0});

  bool get isHold => duration > 0.18;

  factory NoteEvent.fromJson(Map<String, dynamic> json) => NoteEvent(
    (json['time'] as num).toDouble(),
    json['lane'] as int,
    duration: (json['duration'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'time': time,
    'lane': lane,
    if (isHold) 'duration': duration,
  };
}
