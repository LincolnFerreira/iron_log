import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/http_service.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/mappers/workout_data_mapper.dart';
import '../../domain/entities/workout_exercise.dart';

// Provider para gerenciar os exercícios do workout day
final workoutDayExercisesProvider =
    StateNotifierProvider<
      WorkoutDayExercisesNotifier,
      AsyncValue<List<WorkoutExercise>>
    >((ref) {
      final httpService = ref.read(httpServiceProvider);
      return WorkoutDayExercisesNotifier(httpService);
    });

class WorkoutDayExercisesNotifier
    extends StateNotifier<AsyncValue<List<WorkoutExercise>>> {
  final HttpService _httpService;

  WorkoutDayExercisesNotifier(this._httpService)
    : super(const AsyncValue.loading());

  // Controle para evitar múltiplas chamadas simultâneas
  bool _isLoading = false;

  // Carrega sessão específica com exercícios e dados da rotina (via expand)
  Future<void> loadSession(String sessionId) async {
    // Evita chamadas duplicadas
    if (_isLoading) {
      if (kDebugMode) {
        print('🚫 Evitando chamada duplicada para sessão: $sessionId');
      }
      return;
    }

    _isLoading = true;
    state = const AsyncValue.loading();

    try {
      if (kDebugMode) {
        print('🔍 Carregando sessão: $sessionId');
      }

      // Usa endpoint direto da sessão que já retorna exercícios e dados da rotina
      final url = ApiEndpoints.sessionById(sessionId);
      final response = await _httpService.get(url);

      if (response.statusCode == 200) {
        final sessionData = response.data;

        // Extrai exercícios da sessão com expand
        final sessionExercises =
            sessionData['exercises'] as List<dynamic>? ?? [];

        // Usa mapper dedicado para conversão
        final exercises = WorkoutDataMapper.fromApiList(sessionExercises);

        state = AsyncValue.data(exercises);

        if (kDebugMode) {
          print('✅ Sessão carregada: ${exercises.length} exercícios');
        }
      } else {
        state = AsyncValue.error('Erro ao carregar sessão', StackTrace.current);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      if (kDebugMode) {
        print('❌ Erro ao carregar sessão: $e');
      }
    } finally {
      _isLoading = false;
    }
  }

  // Adiciona um novo exercício à lista
  void addExercise(WorkoutExercise exercise) {
    final currentState = state;
    if (currentState is AsyncData<List<WorkoutExercise>>) {
      final currentExercises = currentState.value;
      state = AsyncValue.data([...currentExercises, exercise]);
    }
  }

  // Remove um exercício da lista
  void removeExercise(String exerciseId) {
    final currentState = state;
    if (currentState is AsyncData<List<WorkoutExercise>>) {
      final currentExercises = currentState.value;
      final filteredExercises = currentExercises
          .where((exercise) => exercise.id != exerciseId)
          .toList();
      state = AsyncValue.data(filteredExercises);
    }
  }

  // Remove um exercício da sessão no backend
  Future<void> removeExerciseFromSession(
    String sessionId,
    String exerciseId,
  ) async {
    try {
      if (kDebugMode) {
        print('🗑️ Removendo exercício $exerciseId da sessão $sessionId');
      }

      final url = ApiEndpoints.removeExerciseFromSession(sessionId, exerciseId);
      final response = await _httpService.delete(url);

      if (response.statusCode == 200) {
        // Remove da lista local após sucesso no backend
        removeExercise(exerciseId);

        if (kDebugMode) {
          print('✅ Exercício removido com sucesso');
        }
      } else {
        throw Exception('Erro ao remover exercício: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao remover exercício: $e');
      }
      throw Exception('Erro ao remover exercício: $e');
    }
  }

  // Limpa o cache para permitir recarregamento
  void clearCache() {
    _isLoading = false;
    state = const AsyncValue.loading();
  }

  // Reordena exercícios
  void reorderExercises(int oldIndex, int newIndex) {
    final currentState = state;
    if (currentState is AsyncData<List<WorkoutExercise>>) {
      final exercises = List<WorkoutExercise>.from(currentState.value);
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final exercise = exercises.removeAt(oldIndex);
      exercises.insert(newIndex, exercise);
      state = AsyncValue.data(exercises);
    }
  }

  // Salva os exercícios atualizados da sessão
  Future<void> saveSessionExercises(String sessionId) async {
    final currentState = state;
    if (currentState is! AsyncData<List<WorkoutExercise>>) {
      throw Exception('Não há exercícios para salvar');
    }

    try {
      // TODO: Por enquanto, apenas simula salvamento
      // Quando o backend tiver endpoint específico para exercícios da sessão,
      // implementar a chamada real aqui

      if (kDebugMode) {
        print(
          '💾 Salvando ${currentState.value.length} exercícios da sessão $sessionId',
        );
      }

      // Constrói payload esperado pelo backend: { exercises: [{ exerciseId, order, config?, customName? }, ...] }
      final currentExercises = currentState.value;
      final payload = {
        'exercises': currentExercises.asMap().entries.map((entry) {
          final index = entry.key;
          final ex = entry.value;
          return {
            'exerciseId': ex.id,
            'order': index + 1,
            'customName': null,
            'config': ex
                .toJson(), // envia configuração básica; backend aceita JSON flexível
          };
        }).toList(),
      };

      final url = '${ApiEndpoints.sessionById(sessionId)}/exercises';
      final response = await _httpService.patch(url, data: payload);

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ Exercícios salvos com sucesso');
        }
      } else {
        throw Exception('Erro ao salvar exercícios: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao salvar exercícios: $e');
      }
      throw Exception('Erro ao salvar exercícios: $e');
    }
  }

  // Força reload da sessão (útil para atualizações)
  Future<void> reloadSession(String sessionId) async {
    _isLoading = false; // Reset loading flag
    await loadSession(sessionId);
  }

  /// Carrega um treino já registrado pelo seu ID (modo edição).
  ///
  /// Chama GET /workout/:workoutId, converte a lista plana de SerieLog em
  /// [WorkoutExercise] via [WorkoutDataMapper.fromSerieLogList], e popula o
  /// estado para que a tela de treino exiba os dados pré-preenchidos.
  Future<void> loadExistingWorkout(String workoutId) async {
    if (_isLoading) return;
    _isLoading = true;
    state = const AsyncValue.loading();

    try {
      if (kDebugMode) {
        print('🔍 Carregando treino existente para edição: $workoutId');
      }

      final url = ApiEndpoints.workoutById(workoutId);
      final response = await _httpService.get(url);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final seriesRaw = data['series'] as List<dynamic>? ?? [];
        final exercises = WorkoutDataMapper.fromSerieLogList(seriesRaw);
        state = AsyncValue.data(exercises);

        if (kDebugMode) {
          print('✅ Treino carregado para edição: ${exercises.length} exercícios');
        }
      } else {
        state = AsyncValue.error(
          'Erro ao carregar treino',
          StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      if (kDebugMode) {
        print('❌ Erro ao carregar treino para edição: $e');
      }
    } finally {
      _isLoading = false;
    }
  }

  // Atualiza um exercício específico
  void updateExercise(String exerciseId, WorkoutExercise updatedExercise) {
    final currentState = state;
    if (currentState is AsyncData<List<WorkoutExercise>>) {
      final currentExercises = currentState.value;
      final updatedExercises = currentExercises.map((exercise) {
        return exercise.id == exerciseId ? updatedExercise : exercise;
      }).toList();
      state = AsyncValue.data(updatedExercises);
    }
  }
}
