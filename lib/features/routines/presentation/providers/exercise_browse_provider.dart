import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/routines/domain/entities/exercise_browse_result.dart';
import 'package:iron_log/features/routines/routine_providers.dart';

/// Exercícios para browse na sessão: lista plana por popularidade (useCount).
final exerciseBrowseProvider = FutureProvider<ExerciseBrowseResult>((
  ref,
) async {
  return ref.watch(exerciseRemoteDataSourceProvider).browseExercises();
});
