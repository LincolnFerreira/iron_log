import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/workout_day/domain/entities/exercise_set_history.dart';
import 'package:iron_log/features/workout_day/workout_day_providers.dart';

final exerciseLastSetsProvider =
    FutureProvider.family<ExerciseSetHistory, String>((ref, exerciseId) async {
      try {
        return await ref
            .read(workoutDayRepositoryProvider)
            .fetchExerciseLastSets(exerciseId);
      } catch (e, st) {
        // Log for debugging but return empty history to avoid bubbling errors to UI
        print(
          '[exerciseLastSetsProvider] Error fetching last sets for $exerciseId: $e',
        );
        print(st);
        return ExerciseSetHistory.empty();
      }
    });
