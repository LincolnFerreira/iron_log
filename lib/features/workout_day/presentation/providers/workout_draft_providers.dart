import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/sync_providers.dart';
import '../../../../core/services/auth_service.dart';
import '../../../auth/auth.dart';
import '../../data/datasources/workout_draft_local_datasource.dart';
import '../../data/mappers/workout_draft_snapshot_mapper.dart';
import '../../data/repositories/workout_draft_repository_impl.dart';
import '../../data/services/workout_draft_sync_service.dart';
import '../../data/services/workout_log_service.dart';
import '../../domain/entities/workout_draft.dart';
import '../../domain/repositories/workout_draft_repository.dart';

final workoutDraftSnapshotMapperProvider = Provider<WorkoutDraftSnapshotMapper>(
  (ref) => WorkoutDraftSnapshotMapper(),
);

final workoutDraftLocalDataSourceProvider =
    Provider<WorkoutDraftLocalDataSource>((ref) {
      return WorkoutDraftLocalDataSource(ref.watch(driftDatabaseProvider));
    });

final workoutDraftRepositoryProvider = Provider<WorkoutDraftRepository>((ref) {
  return WorkoutDraftRepositoryImpl(
    ref.watch(workoutDraftLocalDataSourceProvider),
  );
});

/// ID do rascunho ativo na sessão de treino atual (em memória).
final activeDraftIdProvider = StateProvider<String?>((ref) => null);

final activeWorkoutDraftProvider = FutureProvider<WorkoutDraftSummary?>((
  ref,
) async {
  final userId = ref.watch(authStateProvider).user?.uid;
  if (userId == null || userId.isEmpty) return null;

  final draft = await ref
      .watch(workoutDraftRepositoryProvider)
      .getActiveInProgress(userId);
  if (draft == null) return null;

  final mapper = ref.watch(workoutDraftSnapshotMapperProvider);
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
  final userId = ref.watch(authStateProvider).user?.uid;
  if (userId == null || userId.isEmpty) return [];

  return ref.watch(workoutDraftRepositoryProvider).listPendingUpload(userId);
});

final workoutDraftSyncServiceProvider = Provider<WorkoutDraftSyncService>((ref) {
  final repository = ref.watch(workoutDraftRepositoryProvider);
  return WorkoutDraftSyncService(
    repository: repository,
    logService: WorkoutLogService(drafts: repository),
    auth: AuthService(),
  );
});

List<Override> get workoutDraftProvidersOverrides => [
  workoutDraftRepositoryProvider.overrideWith(
    (ref) => WorkoutDraftRepositoryImpl(
      ref.watch(workoutDraftLocalDataSourceProvider),
    ),
  ),
];
