/// Represents a single series (set) entry as typed by the user during a workout.
class SeriesEntry {
  final int index;
  final int
  type; // 0: Aquec. (Warm-up), 1: Prep. (Feeder), 2: Trab (Top Set), 3: Falha (Back-Off)
  final String weight;
  final String reps;
  final bool done;
  final bool isDerived;
  final int? miniSetIndex;
  final String? setType;
  final String? techniqueBlockId;

  SeriesEntry({
    required this.index,
    this.type = 2,
    required this.weight,
    required this.reps,
    this.done = false,
    this.isDerived = false,
    this.miniSetIndex,
    this.setType,
    this.techniqueBlockId,
  });

  SeriesEntry copyWith({
    int? index,
    int? type,
    String? weight,
    String? reps,
    bool? done,
    bool? isDerived,
    int? miniSetIndex,
    String? setType,
    String? techniqueBlockId,
  }) {
    return SeriesEntry(
      index: index ?? this.index,
      type: type ?? this.type,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      done: done ?? this.done,
      isDerived: isDerived ?? this.isDerived,
      miniSetIndex: miniSetIndex ?? this.miniSetIndex,
      setType: setType ?? this.setType,
      techniqueBlockId: techniqueBlockId ?? this.techniqueBlockId,
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
