import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iron_log/core/providers/sync_providers.dart';
import 'package:iron_log/features/auth/auth.dart';
import 'package:iron_log/features/workout_day/data/datasources/workout_draft_local_datasource.dart';
import 'package:iron_log/features/workout_day/data/mappers/workout_draft_snapshot_mapper.dart';
import 'package:iron_log/features/workout_day/data/repositories/workout_draft_repository_impl.dart';
import 'package:iron_log/features/workout_day/data/services/workout_draft_sync_service.dart';
import 'package:iron_log/features/workout_day/data/services/workout_log_service.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_draft.dart';
import 'package:iron_log/features/workout_day/domain/repositories/workout_draft_repository.dart';

final workoutDraftSnapshotMapperProvider = Provider<WorkoutDraftSnapshotMapper>(
  (ref) => WorkoutDraftSnapshotMapper(),
);

final workoutDraftLocalDataSourceProvider =
    Provider<WorkoutDraftLocalDataSource>((ref) {
      return WorkoutDraftLocalDataSource(ref.read(driftDatabaseProvider));
    });

final workoutDraftRepositoryProvider = Provider<WorkoutDraftRepository>((ref) {
  return WorkoutDraftRepositoryImpl(
    ref.read(workoutDraftLocalDataSourceProvider),
  );
});

/// ID do rascunho ativo na sessão de treino atual (em memória).
final activeDraftIdProvider = StateProvider<String?>((ref) => null);

final activeWorkoutDraftProvider = FutureProvider<WorkoutDraftSummary?>((
  ref,
) async {
  final userId = ref.watch(authStateProvider.select((s) => s.user?.uid));
  if (userId == null || userId.isEmpty) return null;

  final draft = await ref
      .read(workoutDraftRepositoryProvider)
      .getActiveInProgress(userId);
  if (draft == null) return null;

  final mapper = ref.read(workoutDraftSnapshotMapperProvider);
  final snapshot = mapper.decode(draft.snapshotJson);
  final summary = mapper.toSummary(snapshot, draft.id);
  return WorkoutDraftSummary(
    id: summary.id,
    sessionName: summary.sessionName,
    exerciseCount: summary.exerciseCount,
    startedAt: draft.startedAt,
    routineId: summary.routineId,
    sessionId: summary.sessionId,
  );
});

final pendingWorkoutDraftsProvider = FutureProvider<List<WorkoutDraft>>((
  ref,
) async {
  final userId = ref.watch(authStateProvider.select((s) => s.user?.uid));
  if (userId == null || userId.isEmpty) return [];

  return ref.read(workoutDraftRepositoryProvider).listPendingUpload(userId);
});

final workoutDraftSyncServiceProvider = Provider<WorkoutDraftSyncService>((ref) {
  final repository = ref.read(workoutDraftRepositoryProvider);
  return WorkoutDraftSyncService(
    repository: repository,
    logService: WorkoutLogService(drafts: repository),
    currentUserId: () => ref.read(authStateProvider).user?.uid,
  );
});

List<Override> get workoutDraftProvidersOverrides => [
  workoutDraftRepositoryProvider.overrideWith(
    (ref) => WorkoutDraftRepositoryImpl(
      ref.read(workoutDraftLocalDataSourceProvider),
    ),
  ),
];
