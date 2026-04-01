/// Represents a single series entry (série) in a series table.
class SeriesEntry {
  final int index;
  int type; // 0: Aquec., 1: Prep., 2: Trab, 3: Falha
  String weight;
  String reps;
  bool done;

  SeriesEntry({
    required this.index,
    this.type = 0,
    required this.weight,
    required this.reps,
    this.done = false,
  });

  SeriesEntry copyWith({
    int? index,
    int? type,
    String? weight,
    String? reps,
    bool? done,
  }) {
    return SeriesEntry(
      index: index ?? this.index,
      type: type ?? this.type,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      done: done ?? this.done,
    );
  }
}
