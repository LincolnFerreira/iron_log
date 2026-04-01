import 'search_exercise.dart';

class ExerciseMuscleGroup {
  final String muscle;
  final List<SearchExercise> exercises;

  const ExerciseMuscleGroup({required this.muscle, required this.exercises});

  factory ExerciseMuscleGroup.fromJson(Map<String, dynamic> json) {
    return ExerciseMuscleGroup(
      muscle: json['muscle']?.toString() ?? '',
      exercises:
          (json['exercises'] as List<dynamic>?)
              ?.map((e) => SearchExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
