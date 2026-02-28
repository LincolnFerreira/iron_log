import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/services/auth_service.dart';
import 'package:iron_log/core/api/endpoints.dart';
import '../../domain/entities/session_exercise.dart';

/// Provider para gerenciar exercícios da sessão de treino
/// Substitui o mock data que estava hardcoded na tela

final sessionExercisesProvider =
    StateNotifierProvider.family<
      SessionExercisesNotifier,
      AsyncValue<List<SessionExercise>>,
      String?
    >((ref, sessionId) {
      return SessionExercisesNotifier(sessionId);
    });

class SessionExercisesNotifier
    extends StateNotifier<AsyncValue<List<SessionExercise>>> {
  final String? sessionId;

  SessionExercisesNotifier(this.sessionId) : super(const AsyncValue.loading()) {
    if (sessionId != null && sessionId!.isNotEmpty) {
      loadSessionExercises();
    } else {
      // Se não há sessionId, usa exercícios padrão temporários
      _loadDefaultExercises();
    }
  }

  Future<void> loadSessionExercises() async {
    state = const AsyncValue.loading();

    try {
      final auth = AuthService();
      auth.initialize();

      final response = await auth.get(
        '${ApiEndpoints.workoutSessions}/$sessionId/exercises',
      );

      final exercisesData = response.data as List;
      final exercises = exercisesData
          .map((json) => SessionExercise.fromJson(json as Map<String, dynamic>))
          .toList();

      state = AsyncValue.data(exercises);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      // Fallback para exercícios padrão em caso de erro
      _loadDefaultExercises();
    }
  }

  void _loadDefaultExercises() {
    // Exercícios padrão para desenvolvimento/teste
    // TODO: Remover quando integração com backend estiver completa
    const defaultExercises = [
      SessionExercise(
        name: 'Desenvolvimento Halteres',
        sets: 4,
        done: 0,
        weight: '30kg',
        reps: '8-10',
      ),
      SessionExercise(
        name: 'Elevação Lateral',
        sets: 3,
        done: 0,
        weight: '10kg',
        reps: '12-15',
      ),
      SessionExercise(
        name: 'Tríceps Corda',
        sets: 3,
        done: 0,
        weight: '25kg',
        reps: '10-12',
      ),
    ];

    state = const AsyncValue.data(defaultExercises);
  }

  void updateExercise(int index, SessionExercise updatedExercise) {
    state.whenData((exercises) {
      final newExercises = List<SessionExercise>.from(exercises);
      if (index >= 0 && index < newExercises.length) {
        newExercises[index] = updatedExercise;
        state = AsyncValue.data(newExercises);
      }
    });
  }

  void markSetAsDone(int exerciseIndex) {
    state.whenData((exercises) {
      final exercise = exercises[exerciseIndex];
      if (exercise.done < exercise.sets) {
        final updatedExercise = SessionExercise(
          name: exercise.name,
          sets: exercise.sets,
          done: exercise.done + 1,
          weight: exercise.weight,
          reps: exercise.reps,
        );
        updateExercise(exerciseIndex, updatedExercise);
      }
    });
  }

  void resetExercise(int exerciseIndex) {
    state.whenData((exercises) {
      final exercise = exercises[exerciseIndex];
      final resetExercise = SessionExercise(
        name: exercise.name,
        sets: exercise.sets,
        done: 0,
        weight: exercise.weight,
        reps: exercise.reps,
      );
      updateExercise(exerciseIndex, resetExercise);
    });
  }

  Future<void> saveSessionProgress() async {
    if (sessionId == null || sessionId!.isEmpty) return;

    try {
      final auth = AuthService();
      auth.initialize();

      await state.when(
        data: (exercises) async {
          final progress = exercises
              .map(
                (exercise) => {
                  'name': exercise.name,
                  'sets_completed': exercise.done,
                  'total_sets': exercise.sets,
                  'weight': exercise.weight,
                  'reps': exercise.reps,
                },
              )
              .toList();

          await auth.post(
            '${ApiEndpoints.workoutSessions}/$sessionId/progress',
            data: {'exercises': progress},
          );
        },
        loading: () async {},
        error: (_, __) async {},
      );
    } catch (error) {
      // Log error but don't throw - progress should still be saved locally
      print('Error saving session progress: $error');
    }
  }
}
