import 'exercise_tag.dart';
import 'series_entry.dart';
import 'weight_unit.dart';

// Sentinel used in copyWith to distinguish "not provided" from explicit null.
const _notSet = Object();

class WorkoutExercise {
  final String id;
  final String name;
  final ExerciseTag tag;
  final String muscles;
  final String variation;
  final int series;
  final String reps;
  final String weight;
  final int rir;
  final int restTime;
  final WeightUnit weightUnit;

  /// Per-series data as typed by the user. When non-empty, this is the
  /// source of truth for the API payload. [reps] and [weight] are used
  /// only as defaults when initialising new rows.
  final List<SeriesEntry> entries;

  /// Optional observation the user may add for this exercise.
  final String? notes;

  const WorkoutExercise({
    required this.id,
    required this.name,
    required this.tag,
    required this.muscles,
    required this.variation,
    required this.series,
    required this.reps,
    required this.weight,
    required this.rir,
    required this.restTime,
    this.weightUnit = WeightUnit.kg,
    this.entries = const [],
    this.notes,
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      tag: ExerciseTag.fromString(json['tag']?.toString() ?? 'multi'),
      muscles: json['muscles']?.toString() ?? '',
      variation: json['variation']?.toString() ?? 'Traditional',
      series: json['series'] ?? 3,
      reps: json['reps']?.toString() ?? '-',
      weight: json['weight']?.toString() ?? '0',
      rir: json['rir'] ?? 2,
      restTime: json['restTime'] ?? 120,
      weightUnit: WeightUnit.fromString(json['weightUnit']?.toString() ?? 'kg'),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tag': tag.label,
      'muscles': muscles,
      'variation': variation,
      'series': series,
      'reps': reps,
      'weight': weight,
      'rir': rir,
      'restTime': restTime,
      'weightUnit': weightUnit.label,
      if (notes != null) 'notes': notes,
    };
  }

  /// Converts to the config format expected by the backend SessionExercise.config field.
  ///
  /// Output: `{ series: [{ label, reps, weight, rir, rest }], variation, notes }`
  Map<String, dynamic> toConfigJson() {
    final seriesList = entries.isNotEmpty
        ? entries
              .map(
                (e) => {
                  'label': e.backendLabel,
                  'reps': int.tryParse(e.reps) ?? 0,
                  'weight': double.tryParse(e.weight) ?? 0.0,
                  'rir': rir,
                  'rest': restTime,
                },
              )
              .toList()
        : List.generate(
            series,
            (_) => {
              'label': 'Top Set',
              'reps': int.tryParse(reps) ?? 0,
              'weight': double.tryParse(weight) ?? 0.0,
              'rir': rir,
              'rest': restTime,
            },
          );

    return {
      'series': seriesList,
      'variation': variation,
      if (notes != null) 'notes': notes,
    };
  }

  WorkoutExercise copyWith({
    String? id,
    String? name,
    ExerciseTag? tag,
    String? muscles,
    String? variation,
    int? series,
    String? reps,
    String? weight,
    int? rir,
    int? restTime,
    WeightUnit? weightUnit,
    List<SeriesEntry>? entries,
    Object? notes = _notSet,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      name: name ?? this.name,
      tag: tag ?? this.tag,
      muscles: muscles ?? this.muscles,
      variation: variation ?? this.variation,
      series: series ?? this.series,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      rir: rir ?? this.rir,
      restTime: restTime ?? this.restTime,
      weightUnit: weightUnit ?? this.weightUnit,
      entries: entries ?? this.entries,
      notes: notes == _notSet ? this.notes : notes as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutExercise && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'WorkoutExercise(id: $id, name: $name, series: $series, reps: $reps)';
  }
}
