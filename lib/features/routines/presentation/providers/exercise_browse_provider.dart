import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/api/endpoints.dart';
import 'package:iron_log/core/services/http_service.dart';
import 'package:iron_log/features/routines/data/models/exercise_browse_dto.dart';
import 'package:iron_log/features/routines/domain/entities/exercise_browse_result.dart';

/// Exercícios para browse na sessão: lista plana por popularidade (useCount).
final exerciseBrowseProvider = FutureProvider<ExerciseBrowseResult>((
  ref,
) async {
  final httpService = ref.watch(httpServiceProvider);
  final response = await httpService.get(ApiEndpoints.exerciseBrowse);
  final dto = ExerciseBrowseDto.fromJson(response.data as Map<String, dynamic>);
  return dto.toEntity();
});
