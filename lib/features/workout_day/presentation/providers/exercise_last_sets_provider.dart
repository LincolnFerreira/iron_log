import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/training_place/domain/entities/exercise_query_key.dart';
import 'package:iron_log/features/workout_day/domain/entities/exercise_set_history.dart';
import 'package:iron_log/features/workout_day/workout_day_providers.dart';

final exerciseLastSetsProvider =
    FutureProvider.family<ExerciseSetHistory, ExerciseQueryKey>((
      ref,
      key,
    ) async {
      try {
        return await ref
            .read(workoutDayRepositoryProvider)
            .fetchExerciseLastSets(key.exerciseId, stationId: key.stationId);
      } catch (e, st) {
        print(
          '[exerciseLastSetsProvider] Error fetching last sets for ${key.exerciseId}: $e',
        );
        print(st);
        return ExerciseSetHistory.empty();
      }
    });
