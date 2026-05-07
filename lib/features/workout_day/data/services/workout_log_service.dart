import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:iron_log/core/api/api_endpoints.dart';
import 'package:iron_log/core/services/auth_service.dart';
import 'package:iron_log/core/services/http_error_handler.dart';
import 'package:iron_log/features/workout_day/data/datasources/workout_outbox_local_datasource.dart';
import 'package:iron_log/features/workout_day/data/workout_local_ids.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_exercise.dart';

/// Serviço responsável por persistir sessões de treino no backend.
/// Converte os dados locais do [WorkoutExercise] para o formato
/// esperado pelo endpoint POST /workout.
class WorkoutLogService {
  final AuthService _auth;
  final WorkoutOutboxLocalDataSource? _outbox;

  WorkoutLogService({
    AuthService? auth,
    WorkoutOutboxLocalDataSource? outbox,
  }) : _auth = auth ?? AuthService(),
       _outbox = outbox;

  /// Salva uma sessão de treino no backend.
  ///
  /// [exercises]          lista de exercícios executados
  /// [routineId]          ID da rotina associada
  /// [startedAt]          início do treino
  /// [endedAt]            término do treino (DateTime.now() para tempo real, custom para manual)
  /// [isManual]           true quando o treino foi registrado retroativamente
  /// [exercises]          lista de exercícios executados (cada um carrega sua própria weightUnit)
  /// [routineId]          ID da rotina associada
  /// [startedAt]          início do treino
  /// [endedAt]            término do treino
  /// [isManual]           true quando o treino foi registrado retroativamente
  ///
  /// [skipOutboxEnqueueOnUnreachable] — em falha de rede, devolve um id `local_…`
  /// sem gravar fila (uso no “Iniciar treino”). Caso false, enfileira POST em Drift.
  Future<String> saveWorkout({
    required List<WorkoutExercise> exercises,
    String? routineId,
    required DateTime startedAt,
    required DateTime endedAt,
    bool isManual = false,
    String? notes,
    String? sessionId,
    bool skipOutboxEnqueueOnUnreachable = false,
  }) async {
    final payload = {
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

    try {
      final response = await _auth.post(ApiEndpoints.workouts, data: payload);
      final data = response.data as Map<String, dynamic>;
      return data['workoutId'] as String;
    } on DioException catch (e) {
      if (!HttpErrorHandler.isConnectivityError(e)) rethrow;
      if (skipOutboxEnqueueOnUnreachable) {
        return WorkoutLocalIds.newLocalSessionId();
      }
      final uid = _auth.currentUser?.uid;
      final outbox = _outbox;
      if (outbox == null || uid == null || uid.isEmpty) rethrow;
      final rowId = WorkoutLocalIds.newOutboxRowId();
      await outbox.enqueuePost(
        rowId: rowId,
        userId: uid,
        workoutPayload: payload,
      );
      return 'queued_$rowId';
    }
  }

  Map<String, dynamic> _exerciseToDto(
    WorkoutExercise exercise, {
    int order = 1,
  }) {
    final entries = exercise.entries;
    final sets = entries.isNotEmpty
        ? entries.length
        : (exercise.series > 0 ? exercise.series : 1);

    final List<int> repsList;
    final List<double> weightList;
    final List<String> labelList;
    List<int>? rirList;
    List<int>? restSecondsList;

    if (entries.isNotEmpty) {
      // Use the actual values typed by the user in each row.
      repsList = entries.map((e) => _parseReps(e.reps)).toList();
      weightList = entries.map((e) => _parseWeight(e.weight)).toList();
      labelList = entries.map((e) => e.backendLabel).toList();

      if (exercise.rir > 0) {
        rirList = List.filled(sets, exercise.rir);
      }
      if (exercise.restTime > 0) {
        restSecondsList = List.filled(sets, exercise.restTime);
      }
    } else {
      // Fallback: all series use the exercise default values.
      final parsedReps = _parseReps(exercise.reps);
      final parsedWeight = _parseWeight(exercise.weight);
      repsList = List.filled(sets, parsedReps);
      weightList = List.filled(sets, parsedWeight);
      labelList = List.filled(sets, 'Top Set');

      if (exercise.rir > 0) {
        rirList = List.filled(sets, exercise.rir);
      }
      if (exercise.restTime > 0) {
        restSecondsList = List.filled(sets, exercise.restTime);
      }
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
    };
  }

  int _parseReps(String value) =>
      int.tryParse(RegExp(r'\d+').firstMatch(value)?.group(0) ?? '') ?? 0;

  double _parseWeight(String value) =>
      double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

  /// Formato de exercício em POST/PATCH `/workout` (séries, reps, peso, etc.).
  Map<String, dynamic> exerciseToWorkoutExerciseDto(
    WorkoutExercise exercise, {
    int order = 1,
  }) => _exerciseToDto(exercise, order: order);

  /// Exposes [_exerciseToDto] for unit testing without HTTP/Firebase.
  @visibleForTesting
  Map<String, dynamic> exerciseToDtoForTesting(
    WorkoutExercise exercise, {
    int order = 1,
  }) => _exerciseToDto(exercise, order: order);

  /// Atualiza (substitui as séries de) um treino já registrado.
  ///
  /// Corresponde ao endpoint PATCH /workout/:id.
  /// O backend deleta os SerieLog existentes e recria a partir de [exercises].
  Future<void> updateWorkout({
    required String workoutId,
    required List<WorkoutExercise> exercises,
    required DateTime startedAt,
    required DateTime endedAt,
    String? notes,
    String? sessionId,
  }) async {
    final payload = {
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

    try {
      await _auth.patch(ApiEndpoints.workoutById(workoutId), data: payload);
    } on DioException catch (e) {
      if (!HttpErrorHandler.isConnectivityError(e)) rethrow;
      final uid = _auth.currentUser?.uid;
      final outbox = _outbox;
      if (outbox == null || uid == null || uid.isEmpty) rethrow;
      final rowId = WorkoutLocalIds.newOutboxRowId();
      await outbox.enqueuePatch(
        rowId: rowId,
        userId: uid,
        workoutId: workoutId,
        patchPayload: payload,
      );
    }
  }

  /// Atualiza apenas a data (startedAt) de um treino já registrado.
  /// Usado para auto-save quando o usuário troca a data no modo edição.
  ///
  /// Se [newEndedAt] for fornecido, também atualiza o endedAt para preservar a duração.
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
