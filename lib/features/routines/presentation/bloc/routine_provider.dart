import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/routine.dart';
import '../../domain/entities/session_creation.dart';
import '../../domain/entities/routine_update.dart';
import '../../domain/repositories/routine_repository.dart';
import '../../domain/usecases/routine_usecases.dart';

// Providers
final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  throw UnimplementedError('RoutineRepository not provided');
});

final getRoutinesUseCaseProvider = Provider<GetRoutinesUseCase>((ref) {
  final repository = ref.watch(routineRepositoryProvider);
  return GetRoutinesUseCase(repository);
});

final getRoutineUseCaseProvider = Provider<GetRoutineUseCase>((ref) {
  final repository = ref.watch(routineRepositoryProvider);
  return GetRoutineUseCase(repository);
});

final createRoutineUseCaseProvider = Provider<CreateRoutineUseCase>((ref) {
  final repository = ref.watch(routineRepositoryProvider);
  return CreateRoutineUseCase(repository);
});

final updateRoutineUseCaseProvider = Provider<UpdateRoutineUseCase>((ref) {
  final repository = ref.watch(routineRepositoryProvider);
  return UpdateRoutineUseCase(repository);
});

final deleteRoutineUseCaseProvider = Provider<DeleteRoutineUseCase>((ref) {
  final repository = ref.watch(routineRepositoryProvider);
  return DeleteRoutineUseCase(repository);
});

// State
class RoutineState {
  final List<Routine> routines;
  final bool isLoading;
  final String? error;
  final Routine? selectedRoutine;

  const RoutineState({
    this.routines = const [],
    this.isLoading = false,
    this.error,
    this.selectedRoutine,
  });

  RoutineState copyWith({
    List<Routine>? routines,
    bool? isLoading,
    String? error,
    Routine? selectedRoutine,
    bool clearError = false,
    bool clearSelectedRoutine = false,
  }) {
    return RoutineState(
      routines: routines ?? this.routines,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedRoutine: clearSelectedRoutine
          ? null
          : (selectedRoutine ?? this.selectedRoutine),
    );
  }
}

// Notifier
class RoutineNotifier extends StateNotifier<RoutineState> {
  final GetRoutinesUseCase _getRoutinesUseCase;
  final GetRoutineUseCase _getRoutineUseCase;
  final CreateRoutineUseCase _createRoutineUseCase;
  final UpdateRoutineUseCase _updateRoutineUseCase;
  final DeleteRoutineUseCase _deleteRoutineUseCase;

  RoutineNotifier(
    this._getRoutinesUseCase,
    this._getRoutineUseCase,
    this._createRoutineUseCase,
    this._updateRoutineUseCase,
    this._deleteRoutineUseCase,
  ) : super(const RoutineState());

  Future<void> loadRoutines() async {
    print('🔄 Iniciando carregamento de rotinas...');
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final routines = await _getRoutinesUseCase.execute();
      print('✅ Rotinas carregadas: ${routines.length}');
      // Ativa sempre em primeiro, demais mantêm ordem original (createdAt desc).
      final sorted = [...routines]
        ..sort((a, b) {
          if (a.isActive && !b.isActive) return -1;
          if (!a.isActive && b.isActive) return 1;
          return 0;
        });
      state = state.copyWith(routines: sorted, isLoading: false);
    } catch (e) {
      print('❌ Erro ao carregar rotinas: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar rotinas: $e',
      );
    }
  }

  Future<void> loadRoutine(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final routine = await _getRoutineUseCase.execute(id);
      state = state.copyWith(selectedRoutine: routine, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar rotina: $e',
      );
    }
  }

  Future<void> createRoutine({
    required String name,
    String? division,
    bool isTemplate = false,
    List<SessionCreation>? sessions,
  }) async {
    print('➕ Criando rotina: $name');
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final newRoutine = await _createRoutineUseCase.execute(
        name: name,
        division: division,
        isTemplate: isTemplate,
        sessions: sessions,
      );
      final updatedRoutines = [...state.routines, newRoutine];
      print('✅ Rotina criada: ${newRoutine.id}');
      state = state.copyWith(routines: updatedRoutines, isLoading: false);
    } catch (e) {
      print('❌ Erro ao criar rotina: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao criar rotina: $e',
      );
    }
  }

  Future<void> updateRoutine(String id, RoutineUpdate updates) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updatedRoutine = await _updateRoutineUseCase.execute(id, updates);
      final updatedRoutines = state.routines.map((routine) {
        return routine.id == id ? updatedRoutine : routine;
      }).toList();
      state = state.copyWith(routines: updatedRoutines, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao atualizar rotina: $e',
      );
    }
  }

  Future<void> deleteRoutine(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _deleteRoutineUseCase.execute(id);
      final updatedRoutines = state.routines
          .where((routine) => routine.id != id)
          .toList();
      state = state.copyWith(routines: updatedRoutines, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao deletar rotina: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void selectRoutine(Routine? routine) {
    state = state.copyWith(selectedRoutine: routine);
  }
}

// Provider
final routineNotifierProvider =
    StateNotifierProvider<RoutineNotifier, RoutineState>((ref) {
      final getRoutinesUseCase = ref.watch(getRoutinesUseCaseProvider);
      final getRoutineUseCase = ref.watch(getRoutineUseCaseProvider);
      final createRoutineUseCase = ref.watch(createRoutineUseCaseProvider);
      final updateRoutineUseCase = ref.watch(updateRoutineUseCaseProvider);
      final deleteRoutineUseCase = ref.watch(deleteRoutineUseCaseProvider);

      return RoutineNotifier(
        getRoutinesUseCase,
        getRoutineUseCase,
        createRoutineUseCase,
        updateRoutineUseCase,
        deleteRoutineUseCase,
      );
    });
