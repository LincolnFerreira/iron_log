import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/api/endpoints.dart';
import 'package:iron_log/core/services/http_service.dart';
import 'package:iron_log/features/routines/domain/entities/exercise_muscle_group.dart';
import 'package:iron_log/features/routines/data/models/exercise_browse_dto.dart';

/// Provider que busca exercícios agrupados por grupo muscular, ordenados por popularidade.
final exerciseBrowseProvider = FutureProvider<List<ExerciseMuscleGroup>>((
  ref,
) async {
  final httpService = ref.watch(httpServiceProvider);
  final response = await httpService.get(ApiEndpoints.exerciseBrowse);
  final dto = ExerciseBrowseDto.fromJson(response.data as List<dynamic>);
  return dto.toEntities();
});
