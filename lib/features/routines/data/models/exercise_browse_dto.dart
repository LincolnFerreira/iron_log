import '../../domain/entities/exercise_muscle_group.dart';
import '../../domain/entities/search_exercise.dart';

/// DTO for exercise browse response - list of muscle groups with exercises
class ExerciseBrowseDto {
  final List<ExerciseMuscleGroupDto> groups;

  ExerciseBrowseDto({required this.groups});

  /// Factory constructor to deserialize from API response
  factory ExerciseBrowseDto.fromJson(List<dynamic> json) {
    return ExerciseBrowseDto(
      groups: json
          .map(
            (g) => ExerciseMuscleGroupDto.fromJson(g as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  /// Convert DTOs to domain entities
  List<ExerciseMuscleGroup> toEntities() {
    return groups.map((g) => g.toEntity()).toList();
  }
}

/// DTO for a single muscle group
class ExerciseMuscleGroupDto {
  final String muscle;
  final List<Map<String, dynamic>> exercises;

  ExerciseMuscleGroupDto({required this.muscle, required this.exercises});

  factory ExerciseMuscleGroupDto.fromJson(Map<String, dynamic> json) {
    return ExerciseMuscleGroupDto(
      muscle: json['muscle']?.toString() ?? '',
      exercises:
          (json['exercises'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
          [],
    );
  }

  /// Convert to domain entity
  ExerciseMuscleGroup toEntity() {
    return ExerciseMuscleGroup(
      muscle: muscle,
      exercises: exercises.map((e) => SearchExercise.fromJson(e)).toList(),
    );
  }
}
