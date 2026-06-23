import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:iron_log/core/api/api_endpoints.dart';
import 'package:iron_log/core/services/auth_service.dart';
import 'package:iron_log/features/workout_day/data/workout_local_ids.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_draft.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_exercise.dart';
import 'package:iron_log/features/workout_day/domain/mappers/technique_block_mapper.dart';
import 'package:iron_log/features/workout_day/domain/repositories/workout_draft_repository.dart';

/// Falha de upload com rascunho já persistido localmente.
class WorkoutUploadDeferredException implements Exception {
  WorkoutUploadDeferredException({
    required this.draftId,
    this.message = 'Treino salvo localmente; envio pendente.',
  });

  final String draftId;
  final String message;

  @override
  String toString() => message;
}

/// Serviço responsável por persistir sessões de treino no backend.
class WorkoutLogService {
  final AuthService _auth;
  final WorkoutDraftRepository? _drafts;

  WorkoutLogService({
    AuthService? auth,
    WorkoutDraftRepository? drafts,
  }) : _auth = auth ?? AuthService(),
       _drafts = drafts;

  Future<String> saveWorkout({
    required List<WorkoutExercise> exercises,
    String? routineId,
    required DateTime startedAt,
    required DateTime endedAt,
    bool isManual = false,
    String? notes,
    String? sessionId,
    String? draftId,
    bool markPendingOnFailure = false,
  }) async {
    final payload = buildCreatePayload(
      exercises: exercises,
      routineId: routineId,
      startedAt: startedAt,
      endedAt: endedAt,
      isManual: isManual,
      notes: notes,
      sessionId: sessionId,
    );

    try {
      final data = await postRaw(payload);
      return data['workoutId'] as String;
    } on DioException catch (e) {
      await _handleUploadFailure(
        e: e,
        draftId: draftId,
        markPendingOnFailure: markPendingOnFailure,
        payload: payload,
        operation: PendingOperation.create,
        serverWorkoutId: null,
        endedAt: endedAt,
      );
      return WorkoutLocalIds.newLocalSessionId();
    }
  }

  Future<void> updateWorkout({
    required String workoutId,
    required List<WorkoutExercise> exercises,
    required DateTime startedAt,
    required DateTime endedAt,
    String? notes,
    String? sessionId,
    String? draftId,
    bool markPendingOnFailure = false,
  }) async {
    final payload = buildPatchPayload(
      exercises: exercises,
      startedAt: startedAt,
      endedAt: endedAt,
      notes: notes,
      sessionId: sessionId,
    );

    try {
      await patchRaw(workoutId, payload);
    } on DioException catch (e) {
      await _handleUploadFailure(
        e: e,
        draftId: draftId,
        markPendingOnFailure: markPendingOnFailure,
        payload: payload,
        operation: PendingOperation.patch,
        serverWorkoutId: workoutId,
        endedAt: endedAt,
      );
      if (markPendingOnFailure && draftId != null) {
        throw WorkoutUploadDeferredException(draftId: draftId);
      }
      rethrow;
    }
  }

  Map<String, dynamic> buildCreatePayload({
    required List<WorkoutExercise> exercises,
    String? routineId,
    required DateTime startedAt,
    required DateTime endedAt,
    bool isManual = false,
    String? notes,
    String? sessionId,
  }) {
    return {
      if (routineId != null) 'routineId': routineId,
      'date': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'isManual': isManual,
      if (notes != null) 'notes': notes,
      if (sessionId != null) 'sessionId': sessionId,
      'exercises': exercises
          .asMap()
          .entries
          .map((e) => _exerciseToDto(e.value, order: e.key + 1))
          .toList(),
    };
  }

  Map<String, dynamic> buildPatchPayload({
    required List<WorkoutExercise> exercises,
    required DateTime startedAt,
    required DateTime endedAt,
    String? notes,
    String? sessionId,
  }) {
    return {
      'date': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      if (notes != null) 'notes': notes,
      if (sessionId != null) 'sessionId': sessionId,
      'exercises': exercises
          .asMap()
          .entries
          .map((e) => _exerciseToDto(e.value, order: e.key + 1))
          .toList(),
    };
  }

  Future<Map<String, dynamic>> postRaw(Map<String, dynamic> payload) async {
    final response = await _auth.post(ApiEndpoints.workouts, data: payload);
    return response.data as Map<String, dynamic>;
  }

  Future<void> patchRaw(String workoutId, Map<String, dynamic> payload) async {
    await _auth.patch(ApiEndpoints.workoutById(workoutId), data: payload);
  }

  Future<void> _handleUploadFailure({
    required DioException e,
    required String? draftId,
    required bool markPendingOnFailure,
    required Map<String, dynamic> payload,
    required PendingOperation operation,
    required String? serverWorkoutId,
    required DateTime? endedAt,
  }) async {
    final uid = _auth.currentUser?.uid;
    final drafts = _drafts;
    if (drafts == null || uid == null || uid.isEmpty || draftId == null) {
      return;
    }

    if (markPendingOnFailure) {
      await drafts.markPendingUpload(
        draftId: draftId,
        apiPayload: payload,
        serverWorkoutId: serverWorkoutId,
        operation: operation,
        endedAt: endedAt,
        error: DraftUploadError(
          type: e.type.name,
          statusCode: e.response?.statusCode,
          message: e.message,
        ),
      );
      throw WorkoutUploadDeferredException(draftId: draftId);
    }
  }

  Map<String, dynamic> _exerciseToDto(
    WorkoutExercise exercise, {
    int order = 1,
  }) {
    final blocks = TechniqueBlockMapper.ensureBlocks(exercise);
    final flatEntries = TechniqueBlockMapper.flattenBlocks(blocks);
    final sets = flatEntries.isNotEmpty
        ? flatEntries.length
        : (exercise.series > 0 ? exercise.series : 1);

    final repsList = flatEntries.map((e) => _parseReps(e.reps)).toList();
    final weightList = flatEntries.map((e) => _parseWeight(e.weight)).toList();
    final labelList = flatEntries.map((e) => e.backendLabel).toList();

    List<int>? rirList;
    List<int>? restSecondsList;
    if (exercise.rir > 0) {
      rirList = List.filled(sets, exercise.rir);
    }
    if (exercise.restTime > 0) {
      restSecondsList = List.filled(sets, exercise.restTime);
    }

    return {
      'exerciseId': exercise.id,
      'name': exercise.name,
      'order': order,
      'sets': sets,
      'reps': repsList,
      'weight': weightList,
      'label': labelList,
      'weightUnit': exercise.weightUnit.label,
      if (rirList != null) 'rir': rirList,
      if (restSecondsList != null) 'restSeconds': restSecondsList,
      if (exercise.notes != null) 'notes': exercise.notes,
      'techniqueBlocks': TechniqueBlockMapper.blocksToDto(
        blocks,
        exerciseRir: exercise.rir,
        exerciseRestTime: exercise.restTime,
      ),
    };
  }

  int _parseReps(String value) => TechniqueBlockMapper.parseReps(value);

  double _parseWeight(String value) => TechniqueBlockMapper.parseWeight(value);

  Map<String, dynamic> exerciseToWorkoutExerciseDto(
    WorkoutExercise exercise, {
    int order = 1,
  }) => _exerciseToDto(exercise, order: order);

  @visibleForTesting
  Map<String, dynamic> exerciseToDtoForTesting(
    WorkoutExercise exercise, {
    int order = 1,
  }) => _exerciseToDto(exercise, order: order);

  Future<void> patchDate(
    String workoutId,
    DateTime newDate, {
    DateTime? newEndedAt,
  }) async {
    final payload = {'date': newDate.toIso8601String()};

    if (newEndedAt != null) {
      payload['endedAt'] = newEndedAt.toIso8601String();
    }

    await _auth.patch(ApiEndpoints.workoutById(workoutId), data: payload);
  }
}
