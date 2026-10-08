import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/training_place/domain/entities/exercise_query_key.dart';
import 'package:iron_log/features/workout_day/domain/entities/suggestion_result.dart';
import 'package:iron_log/features/workout_day/workout_day_providers.dart';

final exerciseSuggestionProvider =
    FutureProvider.family<SuggestionResult, ExerciseQueryKey>((ref, key) async {
      if (kDebugMode) {
        print(
          '[exerciseSuggestionProvider] Fetching suggestion for exerciseId=${key.exerciseId} station=${key.stationId}',
        );
      }

      try {
        final result = await ref
            .read(workoutDayRepositoryProvider)
            .fetchExerciseSuggestion(key.exerciseId, stationId: key.stationId);

        if (kDebugMode) {
          print(
            '[exerciseSuggestionProvider] Parsed: weight=${result.suggestedWeight}, reps=${result.suggestedReps}, action=${result.action}, hasData=${result.hasData}',
          );
        }

        return result;
      } catch (e, st) {
        if (kDebugMode) {
          print('[exerciseSuggestionProvider] ERROR: $e');
          print('[exerciseSuggestionProvider] StackTrace: $st');
        }
        rethrow;
      }
    });
