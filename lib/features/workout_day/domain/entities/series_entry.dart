/// Represents a single series (set) entry as typed by the user during a workout.
class SeriesEntry {
  final int index;
  int type; // 0: Aquec. (Warm-up), 1: Prep. (Feeder), 2: Trab (Top Set), 3: Falha (Back-Off)
  String weight;
  String reps;
  bool done;

  SeriesEntry({
    required this.index,
    this.type = 2,
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

  /// Maps the integer [type] to the label string expected by the backend SerieLog.label field.
  String get backendLabel {
    switch (type) {
      case 0:
        return 'Warm-up';
      case 1:
        return 'Feeder';
      case 3:
        return 'Back-Off';
      case 2:
      default:
        return 'Top Set';
    }
  }
}
