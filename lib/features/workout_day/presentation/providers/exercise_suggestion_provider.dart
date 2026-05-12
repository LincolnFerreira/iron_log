import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/services/http_service.dart';
import 'package:iron_log/core/api/api_endpoints.dart';
import '../../domain/entities/suggestion_result.dart';

final exerciseSuggestionProvider =
    FutureProvider.family<SuggestionResult, String>((ref, exerciseId) async {
      final http = ref.read(httpServiceProvider);
      final url = ApiEndpoints.exerciseSuggestion(exerciseId);

      if (kDebugMode) {
        print('[exerciseSuggestionProvider] Fetching suggestion for exerciseId=$exerciseId');
        print('[exerciseSuggestionProvider] URL: $url');
      }

      try {
        final response = await http.get(url);

        if (kDebugMode) {
          print('[exerciseSuggestionProvider] Response status: ${response.statusCode}');
          print('[exerciseSuggestionProvider] Response data: ${response.data}');
        }

        final result = SuggestionResult.fromJson(response.data as Map<String, dynamic>);

        if (kDebugMode) {
          print('[exerciseSuggestionProvider] Parsed: weight=${result.suggestedWeight}, reps=${result.suggestedReps}, action=${result.action}, hasData=${result.hasData}');
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
