import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/workout_day/domain/entities/suggestion_result.dart';
import 'package:iron_log/features/workout_day/workout_day_providers.dart';

final exerciseSuggestionProvider =
    FutureProvider.family<SuggestionResult, String>((ref, exerciseId) async {
      if (kDebugMode) {
        print(
          '[exerciseSuggestionProvider] Fetching suggestion for exerciseId=$exerciseId',
        );
      }

      try {
        final result = await ref
            .read(workoutDayRepositoryProvider)
            .fetchExerciseSuggestion(exerciseId);

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
