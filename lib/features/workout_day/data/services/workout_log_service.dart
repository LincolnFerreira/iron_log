import 'package:iron_log/core/api/api_endpoints.dart';
import 'package:iron_log/core/services/auth_service.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_exercise.dart';

/// Serviço responsável por persistir sessões de treino no backend.
/// Converte os dados locais do [WorkoutExercise] para o formato
/// esperado pelo endpoint POST /workout.
class WorkoutLogService {
  final AuthService _auth;

  WorkoutLogService({AuthService? auth}) : _auth = auth ?? AuthService();

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
  Future<String> saveWorkout({
    required List<WorkoutExercise> exercises,
    required String routineId,
    required DateTime startedAt,
    required DateTime endedAt,
    bool isManual = false,
    String? notes,
    String? sessionId,
  }) async {
    final payload = {
      'routineId': routineId,
      'date': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'isManual': isManual,
      if (notes != null) 'notes': notes,
      if (sessionId != null) 'sessionId': sessionId,
      'exercises': exercises.map((e) => _exerciseToDto(e)).toList(),
    };

    final response = await _auth.post(ApiEndpoints.workouts, data: payload);
    final data = response.data as Map<String, dynamic>;
    return data['workoutId'] as String;
  }

  Map<String, dynamic> _exerciseToDto(WorkoutExercise exercise) {
    // reps e weight são strings simples ("10", "80.5") — mapeamos como
    // arrays de 1 elemento por série configurada.
    final sets = exercise.series > 0 ? exercise.series : 1;
    final parsedReps =
        int.tryParse(exercise.reps.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final parsedWeight =
        double.tryParse(exercise.weight.replaceAll(RegExp(r'[^0-9.]'), '')) ??
        0.0;

    return {
      'name': exercise.name,
      'sets': sets,
      'reps': List.filled(sets, parsedReps),
      'weight': List.filled(sets, parsedWeight),
      'weightUnit': exercise.weightUnit.label,
      if (exercise.rir > 0) 'rir': List.filled(sets, exercise.rir),
      if (exercise.restTime > 0)
        'restSeconds': List.filled(sets, exercise.restTime),
    };
  }

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
  }) async {
    final payload = {
      'date': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      if (notes != null) 'notes': notes,
      'exercises': exercises.map((e) => _exerciseToDto(e)).toList(),
    };

    await _auth.patch(ApiEndpoints.workoutById(workoutId), data: payload);
  }

  /// Atualiza apenas a data (startedAt) de um treino já registrado.
  /// Usado para auto-save quando o usuário troca a data no modo edição.
  Future<void> patchDate(String workoutId, DateTime newDate) async {
    await _auth.patch(
      ApiEndpoints.workoutById(workoutId),
      data: {'date': newDate.toIso8601String()},
    );
  }
}
