import 'package:flutter/foundation.dart';
import 'package:iron_log/features/routines/domain/entities/routine.dart';
import 'package:iron_log/features/routines/domain/entities/routine_update.dart';
import 'package:iron_log/features/routines/domain/entities/session_creation.dart';
import 'package:iron_log/features/routines/domain/usecases/routine_usecases.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'routine_provider.dart';
import 'routine_state.dart';

part 'routine_controller.g.dart';

@Riverpod(keepAlive: true)
class RoutineController extends _$RoutineController {
  @override
  RoutineState build() => const RoutineState();

  GetRoutinesUseCase get _getRoutinesUseCase =>
      ref.read(getRoutinesUseCaseProvider);

  GetRoutineUseCase get _getRoutineUseCase =>
      ref.read(getRoutineUseCaseProvider);

  CreateRoutineUseCase get _createRoutineUseCase =>
      ref.read(createRoutineUseCaseProvider);

  UpdateRoutineUseCase get _updateRoutineUseCase =>
      ref.read(updateRoutineUseCaseProvider);

  DeleteRoutineUseCase get _deleteRoutineUseCase =>
      ref.read(deleteRoutineUseCaseProvider);

  Future<void> loadRoutines() async {
    if (kDebugMode) {
      debugPrint('🔄 Iniciando carregamento de rotinas...');
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final routines = await _getRoutinesUseCase.execute();
      if (kDebugMode) {
        debugPrint('✅ Rotinas carregadas: ${routines.length}');
      }
      final sorted = [...routines]
        ..sort((a, b) {
          if (a.isActive && !b.isActive) return -1;
          if (!a.isActive && b.isActive) return 1;
          return 0;
        });
      state = state.copyWith(routines: sorted, isLoading: false);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erro ao carregar rotinas: $e');
      }
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

  Future<Routine?> createRoutine({
    required String name,
    String? division,
    bool isTemplate = false,
    List<SessionCreation>? sessions,
  }) async {
    if (kDebugMode) {
      debugPrint('➕ Criando rotina: $name');
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final newRoutine = await _createRoutineUseCase.execute(
        name: name,
        division: division,
        isTemplate: isTemplate,
        sessions: sessions,
      );
      final updatedRoutines = [...state.routines, newRoutine];
      if (kDebugMode) {
        debugPrint('✅ Rotina criada: ${newRoutine.id}');
      }
      state = state.copyWith(routines: updatedRoutines, isLoading: false);
      return newRoutine;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erro ao criar rotina: $e');
      }
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao criar rotina: $e',
      );
      return null;
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

/// Alias de compatibilidade — preferir [routineControllerProvider] em código novo.
final routineNotifierProvider = routineControllerProvider;
