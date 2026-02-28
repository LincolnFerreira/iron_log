import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/routine.dart';
import '../../domain/usecases/session_usecases.dart';
import '../../session_providers.dart';

// Session State
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

// Session Notifier
class SessionNotifier extends StateNotifier<SessionState> {
  final CreateSessionUseCase _createSessionUseCase;
  final UpdateSessionUseCase _updateSessionUseCase;
  final DeleteSessionUseCase _deleteSessionUseCase;

  SessionNotifier(
    this._createSessionUseCase,
    this._updateSessionUseCase,
    this._deleteSessionUseCase,
  ) : super(const SessionState());

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

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void selectSession(Session? session) {
    state = state.copyWith(selectedSession: session);
  }
}

// Session Provider
final sessionNotifierProvider =
    StateNotifierProvider<SessionNotifier, SessionState>((ref) {
      final createSessionUseCase = ref.watch(createSessionUseCaseProvider);
      final updateSessionUseCase = ref.watch(updateSessionUseCaseProvider);
      final deleteSessionUseCase = ref.watch(deleteSessionUseCaseProvider);

      return SessionNotifier(
        createSessionUseCase,
        updateSessionUseCase,
        deleteSessionUseCase,
      );
    });
