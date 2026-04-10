import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/services/http_service.dart';
import 'package:iron_log/core/api/api_endpoints.dart';
import '../../domain/entities/exercise_set_history.dart';

final exerciseLastSetsProvider =
    FutureProvider.family<ExerciseSetHistory, String>((ref, exerciseId) async {
      final http = ref.read(httpServiceProvider);
      final response = await http.get(
        ApiEndpoints.exerciseLastSets(exerciseId),
      );
      return ExerciseSetHistory.fromJson(response.data as Map<String, dynamic>);
    });
