import 'package:iron_log/features/routines/domain/entities/routine.dart';
import 'package:iron_log/features/workout_day/data/models/api_field_names.dart';
import 'package:iron_log/features/workout_day/data/models/session_exercise_dto.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_exercise.dart';

/// Monta o mesmo formato que GET `/session/:id` para reutilizar [SessionExerciseDto].
List<WorkoutExercise> workoutExercisesFromPlanSession({
  required Session planSession,
}) {
  final sessionId = planSession.id;
  final list = planSession.exercises;
  final exercises = <WorkoutExercise>[];

  for (var i = 0; i < list.length; i++) {
    final se = list[i];
    final json = <String, dynamic>{
      ApiFieldNames.exerciseId: se.exerciseId,
      ApiFieldNames.sessionId: sessionId,
      ApiFieldNames.order: i + 1,
      ApiFieldNames.isActive: true,
      ApiFieldNames.exercise: {
        ApiFieldNames.id: se.exercise.id,
        ApiFieldNames.name: se.exercise.name,
        ApiFieldNames.category: null,
        ApiFieldNames.primaryMuscle: se.exercise.primaryMuscle,
        ApiFieldNames.tags: se.exercise.tags,
      },
      ApiFieldNames.config: Map<String, dynamic>.from(se.config ?? {}),
    };
    exercises.add(SessionExerciseDto.fromJson(json).toEntity());
  }

  exercises.sort((a, b) {
    final aOrder = a.order ?? 999;
    final bOrder = b.order ?? 999;
    return aOrder.compareTo(bOrder);
  });

  return exercises;
}
