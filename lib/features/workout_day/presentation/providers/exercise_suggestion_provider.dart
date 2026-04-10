import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/services/http_service.dart';
import 'package:iron_log/core/api/api_endpoints.dart';
import '../../domain/entities/suggestion_result.dart';

final exerciseSuggestionProvider =
    FutureProvider.family<SuggestionResult, String>((ref, exerciseId) async {
  final http = ref.read(httpServiceProvider);
  final response = await http.get(ApiEndpoints.exerciseSuggestion(exerciseId));
  return SuggestionResult.fromJson(response.data as Map<String, dynamic>);
});
