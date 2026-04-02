import 'exercise_tag.dart';
import 'weight_unit.dart';

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
      weight: json['weight']?.toString() ?? '0kg',
      rir: json['rir'] ?? 2,
      restTime: json['restTime'] ?? 120,
      weightUnit: WeightUnit.fromString(json['weightUnit']?.toString() ?? 'kg'),
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
