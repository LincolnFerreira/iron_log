import 'package:iron_log/features/routines/data/models/session_exercise_update_dto.dart';
import 'package:iron_log/features/routines/domain/entities/routine.dart';
import 'package:iron_log/features/routines/domain/usecases/session_usecases.dart';
import 'package:iron_log/features/routines/session_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_provider.g.dart';

class SessionState {
  final bool isLoading;
  final String? error;
  final Session? selectedSession;

  const SessionState({
    this.isLoading = false,
    this.error,
    this.selectedSession,
  });

  SessionState copyWith({
    bool? isLoading,
    String? error,
    Session? selectedSession,
    bool clearError = false,
    bool clearSelectedSession = false,
  }) {
    return SessionState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedSession: clearSelectedSession
          ? null
          : (selectedSession ?? this.selectedSession),
    );
  }
}

@Riverpod(keepAlive: true)
class SessionNotifier extends _$SessionNotifier {
  @override
  SessionState build() => const SessionState();

  CreateSessionUseCase get _createSessionUseCase =>
      ref.read(createSessionUseCaseProvider);
  UpdateSessionUseCase get _updateSessionUseCase =>
      ref.read(updateSessionUseCaseProvider);
  DeleteSessionUseCase get _deleteSessionUseCase =>
      ref.read(deleteSessionUseCaseProvider);
  UpdateSessionExercisesUseCase get _updateSessionExercisesUseCase =>
      ref.read(updateSessionExercisesUseCaseProvider);
  RemoveExerciseFromSessionUseCase get _removeExerciseFromSessionUseCase =>
      ref.read(removeExerciseFromSessionUseCaseProvider);

  Future<Session?> createSession({
    required String routineId,
    required String name,
    required int order,
    List<String> muscles = const [],
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final newSession = await _createSessionUseCase.execute(
        routineId: routineId,
        name: name,
        order: order,
        muscles: muscles,
      );
      state = state.copyWith(isLoading: false);
      return newSession;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao criar sessão: $e',
      );
      return null;
    }
  }

  Future<Session?> updateSession(
    String id, {
    String? name,
    int? order,
    List<String>? muscles,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updatedSession = await _updateSessionUseCase.execute(
        id,
        name: name,
        order: order,
        muscles: muscles,
      );
      state = state.copyWith(isLoading: false);
      return updatedSession;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao atualizar sessão: $e',
      );
      return null;
    }
  }

  Future<bool> deleteSession(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _deleteSessionUseCase.execute(id);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao deletar sessão: $e',
      );
      return false;
    }
  }

  Future<bool> updateSessionExercises(
    String sessionId,
    List<SessionExerciseUpdateDto> exercises,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _updateSessionExercisesUseCase.execute(sessionId, exercises);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao atualizar exercícios da sessão: $e',
      );
      return false;
    }
  }

  Future<bool> removeExerciseFromSession(
    String sessionId,
    String exerciseId,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _removeExerciseFromSessionUseCase.execute(sessionId, exerciseId);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao remover exercício da sessão: $e',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void selectSession(Session? session) {
    state = state.copyWith(selectedSession: session);
  }
}
