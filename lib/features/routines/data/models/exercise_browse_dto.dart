import '../../domain/entities/exercise_browse_result.dart';
import '../../domain/entities/search_exercise.dart';

class ExerciseBrowseDto {
  final List<Map<String, dynamic>> exercises;
  final List<String> muscles;

  ExerciseBrowseDto({required this.exercises, required this.muscles});

  factory ExerciseBrowseDto.fromJson(Map<String, dynamic> json) {
    final rawExercises = json['exercises'] as List<dynamic>? ?? [];
    final rawMuscles = json['muscles'] as List<dynamic>? ?? [];

    return ExerciseBrowseDto(
      exercises: rawExercises.cast<Map<String, dynamic>>(),
      muscles: rawMuscles.map((m) => m.toString()).where((m) => m.isNotEmpty).toList(),
    );
  }

  ExerciseBrowseResult toEntity() {
    return ExerciseBrowseResult(
      exercises: exercises
          .map((e) => SearchExercise.fromJson(e))
          .toList(),
      muscles: muscles,
    );
  }
}
