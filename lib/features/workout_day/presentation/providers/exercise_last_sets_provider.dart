import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/services/http_service.dart';
import 'package:iron_log/core/api/api_endpoints.dart';
import '../../domain/entities/exercise_set_history.dart';

final exerciseLastSetsProvider =
    FutureProvider.family<ExerciseSetHistory, String>((ref, exerciseId) async {
      final http = ref.read(httpServiceProvider);
      try {
        final response = await http.get(
          ApiEndpoints.exerciseLastSets(exerciseId),
        );
        return ExerciseSetHistory.fromJson(response.data as Map<String, dynamic>);
      } catch (e, st) {
        // Log for debugging but return empty history to avoid bubbling errors to UI
        // (the widget will show no history instead of crashing)
        // Use print to ensure logs are visible in Flutter debug console
        print('[exerciseLastSetsProvider] Error fetching last sets for $exerciseId: $e');
        print(st);
        return ExerciseSetHistory.empty();
      }
    });
