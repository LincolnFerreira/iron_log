import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/http_service.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../data/models/session_exercise_dto.dart';
import '../../domain/entities/workout_exercise.dart';
import '../../data/models/workout_edit_dto.dart';
import '../../data/services/workout_log_service.dart';
import '../../domain/enums/workout_screen_mode.dart';

// Enum para rastrear tipo de atividade
enum WorkoutActivityType { training, cardio, rest }

// Provider para armazenar a duração original de um treino em edição
// Usado para preservar a duração ao mudar a data do treino
final workoutOriginalDurationProvider = StateProvider<Duration?>((ref) => null);

// Provider para rastrear o tipo de atividade atual (training, cardio, rest)
// Padrão: training (treino normal com séries)
final workoutActivityTypeProvider = StateProvider<WorkoutActivityType>(
  (ref) => WorkoutActivityType.training,
);

// Provider para armazenar metadata de cardio (tipo, intensidade, duração)
final cardioMetadataProvider =
    StateProvider<({String? type, String? intensity, int? duration})>(
      (ref) => (type: null, intensity: null, duration: null),
    );

// Provider para rastrear o modo atual da tela de treino
// Diferencia entre template (editando rotina), execution (fazendo treino) e editing (editando log)
final workoutScreenModeProvider = StateProvider<WorkoutScreenMode?>(
  (ref) => null,
);

// Provider para rastrear o ID da sessão de treino ativa durante execution/editing
// Criado ao iniciar treino (execution) ou carregado ao editar (editing)
// Nulo em modo template
final workoutSessionIdProvider = StateProvider<String?>((ref) => null);

// Provider para gerenciar os exercícios do workout day
final workoutDayExercisesProvider =
    StateNotifierProvider<
      WorkoutDayExercisesNotifier,
      AsyncValue<List<WorkoutExercise>>
    >((ref) {
      final httpService = ref.read(httpServiceProvider);
      return WorkoutDayExercisesNotifier(httpService, ref: ref);
    });

class WorkoutDayExercisesNotifier
    extends StateNotifier<AsyncValue<List<WorkoutExercise>>> {
  final HttpService _httpService;
  final Ref? _ref;

  WorkoutDayExercisesNotifier(this._httpService, {required Ref? ref})
    : _ref = ref,
      super(const AsyncValue.loading());

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

        // Converte DTOs diretamente para entidades
        final exercises = sessionExercises
            .map(
              (data) => SessionExerciseDto.fromJson(
                data as Map<String, dynamic>,
              ).toEntity(),
            )
            .toList();

        // Ordena exercícios por campo "order" para garantir exibição correta
        exercises.sort((a, b) {
          final aOrder = a.order ?? 999;
          final bOrder = b.order ?? 999;
          return aOrder.compareTo(bOrder);
        });

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

  // Salva os exercícios atualizados da sessão (apenas em modo template)
  Future<void> saveSessionExercises(String sessionId) async {
    final mode = _ref?.read(workoutScreenModeProvider);
    if (mode != WorkoutScreenMode.template) {
      throw Exception(
        'saveSessionExercises deve ser chamado apenas em modo template. '
        'Modo atual: $mode. '
        'Use updateExistingWorkout() para editar treinos passados.',
      );
    }

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
      final Map<String, dynamic> payload = {
        'exercises': currentExercises.asMap().entries.map((entry) {
          final index = entry.key;
          final ex = entry.value;
          return {
            'exerciseId': ex.id,
            'order': index + 1,
            'customName': null,
            'config': ex.toConfigJson(),
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
        final dto = WorkoutEditDto.fromJson(
          response.data as Map<String, dynamic>,
        );

        if (kDebugMode) {
          print('📦 Workout data:');
          print('   id         : ${dto.id}');
          print('   startedAt  : ${dto.startedAt}');
          print('   endedAt    : ${dto.endedAt}');
          print('   isManual   : ${dto.isManual}');
          print('   routineId  : ${dto.routineId}');
          print('   routineName: ${dto.routineName}');
          print('   series cnt : ${dto.series.length}');
        }
        //TODO: imagino que isso poderia estar sendo feito na propria entity se não estiver errado diante de um clean architecture
        // Armazena o ID da WorkoutSession para referência durante edição
        if (_ref != null) {
          _ref.read(workoutSessionIdProvider.notifier).state = dto.id;
          if (kDebugMode) {
            print('📌 WorkoutSession ID armazenado: ${dto.id}');
          }
        }

        // Calcula e armazena a duração original do treino
        if (dto.endedAt != null && _ref != null) {
          try {
            final originalDuration = dto.endedAt!.difference(dto.startedAt);
            _ref.read(workoutOriginalDurationProvider.notifier).state =
                originalDuration;

            if (kDebugMode) {
              print(
                '⏱️ Duração original extraída: ${originalDuration.inMinutes} min',
              );
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Falha ao calcular duração: $e');
            }
          }
        }

        final exercises = dto.toWorkoutExercises();
        state = AsyncValue.data(exercises);

        if (kDebugMode) {
          print(
            '✅ Treino carregado para edição: ${exercises.length} exercícios',
          );
        }
      } else {
        state = AsyncValue.error('Erro ao carregar treino', StackTrace.current);
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

  /// Inicia a execução de um treino criando uma WorkoutSession no backend.
  ///
  /// Deve ser chamado apenas em modo execution (após o usuário clicar em "Iniciar Treino").
  /// Cria a sessão com os exercícios carregados, armazenando o workoutSessionId
  /// para permitir recovery se o app crashear.
  ///
  /// Parâmetros:
  /// - routineId: ID da rotina associada (opcional)
  /// - sessionId: ID da sessão da rotina (opcional)
  /// - isManual: true se é um treino retroativo (manual date)
  Future<void> startExecution({
    String? routineId,
    String? sessionId,
    bool isManual = false,
  }) async {
    final mode = _ref?.read(workoutScreenModeProvider);
    if (mode != WorkoutScreenMode.execution) {
      throw Exception(
        'startExecution deve ser chamado apenas em modo execution. '
        'Modo atual: $mode',
      );
    }

    try {
      if (kDebugMode) {
        print('🚀 Iniciando execução de treino...');
      }

      final currentState = state;
      if (currentState is! AsyncData<List<WorkoutExercise>>) {
        throw Exception('Nenhum exercício carregado para iniciar execução');
      }

      // Importa o serviço de log
      final WorkoutLogService workoutLogService = WorkoutLogService();

      // Cria a WorkoutSession no backend com os exercícios e timestamp inicial
      final workoutSessionId = await workoutLogService.saveWorkout(
        exercises: currentState.value,
        routineId: routineId,
        startedAt: DateTime.now(),
        endedAt: DateTime.now(), // Será atualizado no finish
        isManual: isManual,
        sessionId: sessionId,
      );

      // Armazena o ID da sessão criada para referência durante execução
      if (_ref != null) {
        _ref.read(workoutSessionIdProvider.notifier).state = workoutSessionId;
      }

      if (kDebugMode) {
        print('✅ WorkoutSession criada: $workoutSessionId');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Erro ao iniciar execução: $e');
      }
      throw Exception('Erro ao iniciar execução de treino: $e');
    }
  }

  void updateExerciseExecution(
    String exerciseId,
    WorkoutExercise updatedExercise,
  ) {
    final mode = _ref?.read(workoutScreenModeProvider);
    if (mode != WorkoutScreenMode.execution) {
      throw Exception(
        'updateExerciseExecution deve ser chamado apenas em modo execution. '
        'Modo atual: $mode',
      );
    }
    _updateExerciseInMemory(exerciseId, updatedExercise);
  }

  // Atualiza um exercício durante edição de template/sessão
  void updateExerciseTemplate(
    String exerciseId,
    WorkoutExercise updatedExercise,
  ) {
    final mode = _ref?.read(workoutScreenModeProvider);
    if (mode != WorkoutScreenMode.template) {
      throw Exception(
        'updateExerciseTemplate deve ser chamado apenas em modo template. '
        'Modo atual: $mode',
      );
    }
    _updateExerciseInMemory(exerciseId, updatedExercise);
  }

  // Atualiza um exercício durante edição de treino passado (log)
  void updateExerciseLog(String exerciseId, WorkoutExercise updatedExercise) {
    final mode = _ref?.read(workoutScreenModeProvider);
    if (mode != WorkoutScreenMode.editing) {
      throw Exception(
        'updateExerciseLog deve ser chamado apenas em modo editing. '
        'Modo atual: $mode',
      );
    }
    _updateExerciseInMemory(exerciseId, updatedExercise);
  }

  // Método legado mantido para compatibilidade - depreciado em favor dos métodos específicos
  @Deprecated(
    'Use updateExerciseExecution, updateExerciseTemplate ou updateExerciseLog em vez disso. '
    'Este método será removido em versão futura.',
  )
  void updateExercise(String exerciseId, WorkoutExercise updatedExercise) {
    debugPrint(
      '[Provider.updateExercise] ⚠️ DEPRECATED: Use método específico (execution/template/log)',
    );
    _updateExerciseInMemory(exerciseId, updatedExercise);
  }

  // Helper privado: atualiza exercício em memória sem validação de modo
  void _updateExerciseInMemory(
    String exerciseId,
    WorkoutExercise updatedExercise,
  ) {
    debugPrint(
      '[Provider._updateExerciseInMemory] exerciseId=$exerciseId, entries: ${updatedExercise.entries.map((e) => "s${e.index}(w=${e.weight} r=${e.reps})").join(", ")}',
    );
    final currentState = state;
    if (currentState is AsyncData<List<WorkoutExercise>>) {
      final currentExercises = currentState.value;
      debugPrint(
        '[Provider._updateExerciseInMemory] BEFORE: ${currentExercises.where((ex) => ex.id == exerciseId).firstOrNull?.entries.map((e) => "s${e.index}(w=${e.weight} r=${e.reps})").join(", ")}',
      );
      final updatedExercises = currentExercises.map((exercise) {
        return exercise.id == exerciseId ? updatedExercise : exercise;
      }).toList();
      debugPrint(
        '[Provider._updateExerciseInMemory] AFTER: ${updatedExercises.where((ex) => ex.id == exerciseId).firstOrNull?.entries.map((e) => "s${e.index}(w=${e.weight} r=${e.reps})").join(", ")}',
      );
      state = AsyncValue.data(updatedExercises);
    }
  }

  /// Atualiza um treino existente (editando log histórico).
  ///
  /// Deve ser chamado apenas em modo editing após o usuário editar um treino passado.
  /// Converte WorkoutExercise.entries para o formato esperado pelo backend e envia PATCH.
  ///
  /// Parâmetros:
  /// - workoutSessionId: ID da WorkoutSession a ser atualizada
  /// - exercises: lista de exercícios com modificações
  /// - endedAt: nova data/hora de término (opcional, se mudou a duração)
  Future<void> updateExistingWorkout({
    required String workoutSessionId,
    required List<WorkoutExercise> exercises,
    DateTime? endedAt,
  }) async {
    final mode = _ref?.read(workoutScreenModeProvider);
    if (mode != WorkoutScreenMode.editing) {
      throw Exception(
        'updateExistingWorkout deve ser chamado apenas em modo editing. '
        'Modo atual: $mode',
      );
    }

    try {
      if (kDebugMode) {
        print(
          '📝 Atualizando treino existente: $workoutSessionId com ${exercises.length} exercícios',
        );
      }

      // Importa o serviço para converter exercícios
      final WorkoutLogService workoutLogService = WorkoutLogService();

      // Constrói payload similiar a saveWorkout mas como PATCH
      final Map<String, dynamic> payload = {
        'exercises': exercises
            .asMap()
            .entries
            .map(
              (e) => workoutLogService.exerciseToDtoForTesting(
                e.value,
                order: e.key + 1,
              ),
            )
            .toList(),
      };

      if (endedAt != null) {
        payload['endedAt'] = endedAt.toIso8601String();
      }

      // Envia PATCH para atualizar a WorkoutSession
      final url = ApiEndpoints.workoutById(workoutSessionId);
      final response = await _httpService.patch(url, data: payload);

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ Treino atualizado com sucesso');
        }
      } else {
        throw Exception('Erro ao atualizar treino: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao atualizar treino existente: $e');
      }
      throw Exception('Erro ao atualizar treino: $e');
    }
  }
}
