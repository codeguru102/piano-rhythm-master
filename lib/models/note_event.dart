/// A single note in a song's beat map: hit [lane] at [time] seconds.
class NoteEvent {
  final double time; // seconds from song start
  final int lane; // 0..laneCount-1

  const NoteEvent(this.time, this.lane);

  factory NoteEvent.fromJson(Map<String, dynamic> json) =>
      NoteEvent((json['time'] as num).toDouble(), json['lane'] as int);

  Map<String, dynamic> toJson() => {'time': time, 'lane': lane};
}
