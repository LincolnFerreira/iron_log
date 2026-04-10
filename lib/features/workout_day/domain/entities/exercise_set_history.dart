class WorkoutSet {
  final double? weight;
  final int? reps;
  final String? label;
  final String weightUnit;

  const WorkoutSet({
    this.weight,
    this.reps,
    this.label,
    this.weightUnit = 'kg',
  });

  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSet(
      weight: (json['weight'] as num?)?.toDouble(),
      reps: json['reps'] as int?,
      label: json['label'] as String?,
      weightUnit: (json['weightUnit'] as String?) ?? 'kg',
    );
  }

  String get displayText {
    final w = weight != null
        ? '${weight!.toStringAsFixed(weight! % 1 == 0 ? 0 : 1)}$weightUnit'
        : '—';
    final r = reps != null ? '${reps}x' : '—';
    return '$w × $r';
  }
}

class ExerciseSetHistory {
  final DateTime? sessionDate;
  final List<WorkoutSet> sets;

  const ExerciseSetHistory({required this.sessionDate, required this.sets});

  bool get hasHistory => sets.isNotEmpty;

  factory ExerciseSetHistory.empty() {
    return const ExerciseSetHistory(sessionDate: null, sets: []);
  }

  factory ExerciseSetHistory.fromJson(Map<String, dynamic> json) {
    final rawDate = json['sessionDate'] as String?;
    return ExerciseSetHistory(
      sessionDate: rawDate != null ? DateTime.tryParse(rawDate) : null,
      sets: (json['sets'] as List<dynamic>? ?? [])
          .map((e) => WorkoutSet.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
