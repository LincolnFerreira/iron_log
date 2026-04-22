import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/components/organisms/session_picker_sheet.dart';
import '../../../home/state/home_provider.dart';
import '../../../routines/domain/entities/routine.dart';
import '../../../routines/domain/entities/search_exercise.dart';
import '../../data/services/workout_log_service.dart';
import '../../domain/entities/exercise_tag.dart';
import '../../domain/entities/exercise_summary.dart';
import '../../domain/entities/serie_log.dart';
import '../../domain/entities/workout_exercise.dart';
import '../components/molecules/workout_day_header.dart';
import '../components/organisms/add_exercise_bottom_sheet.dart';
import '../components/organisms/reorderable_exercises_list.dart';
import '../components/organisms/exercise_reorder_sheet.dart';
import '../organisms/footer_actions.dart';
import '../providers/workout_day_provider.dart';
import '../providers/workout_timer_provider.dart';
import '../controllers/workout_controller.dart';
import '../../domain/workout_mode.dart';
import '../../domain/enums/workout_screen_mode.dart';
import './workout_summary_screen.dart';

class WorkoutDayScreen extends ConsumerStatefulWidget {
  final String? routineId;
  final String? sessionId;
  final String? subtitle;

  /// Quando não nulo, indica que é um registro de treino passado.
  /// A data escolhida pelo usuário é usada como startedAt.
  final DateTime? manualDate;

  /// Quando não nulo, a tela entra em modo de edição:
  /// carrega o treino existente e ao finalizar faz PATCH em vez de POST.
  final String? workoutId;

  const WorkoutDayScreen({
    super.key,
    this.routineId,
    this.sessionId,
    this.subtitle,
    this.manualDate,
    this.workoutId,
  });

  const WorkoutDayScreen.create({
    Key? key,
    String? routineId,
    String? sessionId,
    String? subtitle,
  }) : this(
         key: key,
         routineId: routineId,
         sessionId: sessionId,
         subtitle: subtitle,
         manualDate: null,
         workoutId: null,
       );

  const WorkoutDayScreen.manual({
    Key? key,
    required DateTime manualDate,
    String? routineId,
    String? sessionId,
    String? subtitle,
  }) : this(
         key: key,
         routineId: routineId,
         sessionId: sessionId,
         subtitle: subtitle,
         manualDate: manualDate,
         workoutId: null,
       );

  const WorkoutDayScreen.edit({
    Key? key,
    required String workoutId,
    DateTime? manualDate,
    String? routineId,
    String? sessionId,
    String? subtitle,
  }) : this(
         key: key,
         routineId: routineId,
         sessionId: sessionId,
         subtitle: subtitle,
         manualDate: manualDate,
         workoutId: workoutId,
       );

  @override
  ConsumerState<WorkoutDayScreen> createState() => _WorkoutDayScreenState();
}

class _WorkoutDayScreenState extends ConsumerState<WorkoutDayScreen> {
  bool _workoutStarted = false;
  bool _isStartingWorkout = false;

  /// Data mutável do treino — inicializada com widget.manualDate e pode ser
  /// alterada pelo usuário via date picker no header.
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.manualDate;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Determina e define o modo de operação baseado nos parâmetros do widget
      final mode = _determineMode();
      ref.read(workoutScreenModeProvider.notifier).state = mode;

      if (widget.workoutId != null && widget.workoutId!.isNotEmpty) {
        // Modo edição: carrega treino existente pelo ID do WorkoutSession.
        _loadExistingWorkout();
      } else if (widget.sessionId != null && widget.sessionId!.isNotEmpty) {
        // Modo normal: carrega exercícios da sessão do plano de treino.
        _loadSession();
      }
    });
  }

  @override
  void dispose() {
    // Reseta o timer ao sair da tela se o treino não foi iniciado
    if (!_workoutStarted) {
      try {
        if (mounted) {
          ref.read(workoutTimerProvider.notifier).resetTimer();
        }
      } catch (e) {
        if (kDebugMode) {
          print('Aviso: não foi possível resetar o timer no dispose: $e');
        }
      }
    }

    super.dispose();
  }

  /// Determina o modo de operação baseado nos parâmetros do widget.
  /// - editing: se workoutId está definido (editando treino passado)
  /// - execution: se manualDate está definido (executando treino em data específica)
  /// - template: caso contrário (editando/visualizando template de sessão)
  WorkoutScreenMode _determineMode() {
    if (widget.workoutId != null && widget.workoutId!.isNotEmpty) {
      return WorkoutScreenMode.editing;
    } else if (widget.manualDate != null) {
      return WorkoutScreenMode.execution;
    } else {
      return WorkoutScreenMode.template;
    }
  }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   // Auto-reload quando retornar para a tela (ex: de "organize suas sessões")
  //   // Só aplica no modo de sessão normal — no modo edição não recarregamos.
  //   if (widget.workoutId == null &&
  //       widget.sessionId != null &&
  //       widget.sessionId!.isNotEmpty) {
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       if (!mounted) return;
  //       _reloadSessionIfNeeded();
  //     });
  //   }
  // }

  Future<void> _loadSession() async {
    if (widget.sessionId == null) return;

    try {
      await ref
          .read(workoutDayExercisesProvider.notifier)
          .loadSession(widget.sessionId!);
    } catch (e) {
      // O erro já é tratado pelo AsyncValue no provider
      if (kDebugMode) {
        print('Erro ao carregar sessão: $e');
      }
    }
  }

  Future<void> _loadExistingWorkout() async {
    if (widget.workoutId == null) return;

    try {
      await ref
          .read(workoutDayExercisesProvider.notifier)
          .loadExistingWorkout(widget.workoutId!);
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar treino para edição: $e');
      }
    }
  }

  Future<void> _reloadSessionIfNeeded() async {
    if (widget.sessionId == null) return;

    try {
      // Usa método que JÁ EXISTE para recarregar
      await ref
          .read(workoutDayExercisesProvider.notifier)
          .reloadSession(widget.sessionId!);
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao recarregar sessão: $e');
      }
    }
  }

  /// Abre o date picker para o usuário alterar a data do treino.
  /// Em modo edição (workoutId != null), salva automaticamente no backend.
  /// Preserva a duração original do treino ao mudar de data.
  Future<void> _changeDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: 'Data do treino',
    );
    if (picked == null || !mounted) return;

    setState(() => _selectedDate = picked);

    // Em modo edição: auto-save da nova data no backend
    if (widget.workoutId != null && widget.workoutId!.isNotEmpty) {
      try {
        // Lê a duração original do provider
        final originalDuration = ref.read(workoutOriginalDurationProvider);

        // Se temos duração original, calcula o novo endedAt preservando a duração
        DateTime? newEndedAt;
        if (originalDuration != null) {
          // Preserva o horário original somando a duração à nova data
          newEndedAt = picked.add(originalDuration);

          if (kDebugMode) {
            print('📅 Data alterada: $picked');
            print(
              '⏱️ Novo endedAt calculado: $newEndedAt (duração: ${originalDuration.inMinutes}min)',
            );
          }
        }

        // Envia a atualização com nova data e endedAt preservado
        await WorkoutLogService().patchDate(
          widget.workoutId!,
          picked,
          newEndedAt: newEndedAt,
        );
      } catch (e) {
        if (kDebugMode) {
          print('Aviso: falha ao atualizar data no backend: $e');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Não foi possível salvar a nova data.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(workoutDayExercisesProvider);

    Future<void> _openReorderSheet() async {
      final current = ref.read(workoutDayExercisesProvider).value ?? [];
      if (current.isEmpty) return;
      final result = await ExerciseReorderSheet.show(context, current);
      if (result != null && result.isNotEmpty) {
        ref.read(workoutDayExercisesProvider.notifier).replaceExercises(result);
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            exercisesAsync.when(
              data: (exercises) => WorkoutDayHeader(
                title: widget.subtitle ?? 'Exercícios do Dia',
                subtitle: exercises.isEmpty
                    ? 'Nenhum exercício'
                    : '${exercises.length} exercício${exercises.length > 1 ? 's' : ''}',
                manualDate: _selectedDate,
                onDateTap: _selectedDate != null ? _changeDate : null,
                onMorePressed: _openReorderSheet,
                existingDuration: ref.watch(workoutOriginalDurationProvider),
              ),
              loading: () => WorkoutDayHeader(
                title: widget.subtitle ?? 'Exercícios do Dia',
                subtitle: 'Carregando...',
                manualDate: _selectedDate,
                onDateTap: _selectedDate != null ? _changeDate : null,
                onMorePressed: _openReorderSheet,
                existingDuration: ref.watch(workoutOriginalDurationProvider),
              ),
              error: (_, __) => WorkoutDayHeader(
                title: widget.subtitle ?? 'Exercícios do Dia',
                subtitle: 'Erro ao carregar',
                manualDate: _selectedDate,
                onDateTap: _selectedDate != null ? _changeDate : null,
                onMorePressed: _openReorderSheet,
                existingDuration: ref.watch(workoutOriginalDurationProvider),
              ),
            ),
            const SizedBox(height: 24),
            // Content
            Expanded(
              child: exercisesAsync.when(
                data: (exercises) => exercises.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Nenhum exercício adicionado',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Use o botão abaixo para adicionar exercícios',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withValues(alpha: 0.6),
                                  ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _showAddExerciseBottomSheet,
                              icon: const Icon(Icons.add),
                              label: const Text('Adicionar Exercício'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ReorderableExercisesList(
                        exercises: exercises,
                        sessionId: widget.sessionId,
                        onReorder: (oldIndex, newIndex) {
                          ref
                              .read(workoutDayExercisesProvider.notifier)
                              .reorderExercises(oldIndex, newIndex);
                        },

                        //NÃO retirar esse método daqui, ele está totalmente correto aqui!
                        onAddExercise: () => _showAddExerciseBottomSheet(),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Erro ao carregar exercícios',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _reloadSessionIfNeeded,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: exercisesAsync.when(
        data: (exercises) => exercises.isNotEmpty
            ? FooterActions(
                isManual: _selectedDate != null,
                seriesDone: _calculateSeriesDone(exercises),
                volumeKg: _calculateVolume(exercises),
                completionPercent: _calculateCompletion(exercises),
                workoutStarted: _workoutStarted,
                isLoading:
                    ref.watch(workoutControllerProvider).isLoading ||
                    _isStartingWorkout,
                onStartWorkout: _handleStartWorkout,
                onFinishWorkout: () async {
                  final exercises =
                      ref.read(workoutDayExercisesProvider).value ?? [];
                  final timerStartTime = ref.read(workoutTimerProvider);

                  final mode =
                      (widget.workoutId != null && widget.workoutId!.isNotEmpty)
                      ? WorkoutMode.edit
                      : (widget.manualDate != null
                            ? WorkoutMode.manual
                            : WorkoutMode.create);

                  final controller = ref.read(
                    workoutControllerProvider.notifier,
                  );

                  var result = await controller.finishWorkout(
                    mode: mode,
                    exercises: exercises,
                    routineId: widget.routineId,
                    sessionId: widget.sessionId,
                    workoutId: widget.workoutId,
                    selectedDate: _selectedDate,
                    timerStartTime: timerStartTime,
                  );

                  if (result.needDuration) {
                    final picked = await _pickDuration(context);
                    if (!mounted) return;
                    if (picked == null) {
                      if (mounted) setState(() => _workoutStarted = false);
                      return;
                    }
                    result = await controller.finishWorkout(
                      mode: mode,
                      exercises: exercises,
                      routineId: widget.routineId,
                      sessionId: widget.sessionId,
                      workoutId: widget.workoutId,
                      selectedDate: _selectedDate,
                      timerStartTime: timerStartTime,
                      manualDuration: picked,
                    );
                  }

                  if (result.needSessionSelection) {
                    final homeState = ref.read(homeProvider);
                    final routine = homeState.todaysRoutine;
                    if (routine != null && routine.sessions.isNotEmpty) {
                      if (!mounted) return;
                      Session? selectedSession = await SessionPickerSheet.show(
                        context,
                        sessions: routine.sessions,
                        onSelectSession: (_) {},
                      );
                      if (selectedSession == null || !mounted) {
                        if (mounted) setState(() => _workoutStarted = false);
                        return;
                      }
                      result = await controller.finishWorkout(
                        mode: mode,
                        exercises: exercises,
                        routineId: widget.routineId,
                        sessionId: selectedSession.id,
                        workoutId: widget.workoutId,
                        selectedDate: _selectedDate,
                        timerStartTime: timerStartTime,
                      );
                    } else {
                      if (mounted) {
                        setState(() => _workoutStarted = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Nenhuma sessão disponível para selecionar.',
                            ),
                          ),
                        );
                      }
                      return;
                    }
                  }

                  if (result.success && result.summary != null) {
                    if (mode == WorkoutMode.edit) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Treino atualizado com sucesso!'),
                        ),
                      );
                      Navigator.of(context).pop();
                    } else {
                      if (!mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => WorkoutSummaryScreen(
                            workoutSummary: result.summary!,
                          ),
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      setState(() => _workoutStarted = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Erro ao finalizar treino: ${result.error ?? 'unknown'}',
                          ),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  }
                },
                onDiscard: () => _discardWorkout(),
                onSaveTrain: () async {
                  if (widget.sessionId == null || widget.sessionId!.isEmpty) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Nenhuma sessão associada para salvar.',
                          ),
                        ),
                      );
                    }
                    return;
                  }

                  try {
                    await ref
                        .read(workoutDayExercisesProvider.notifier)
                        .saveSessionExercises(widget.sessionId!);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Treino salvo com sucesso'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erro ao salvar treino: $e'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  }
                },
              )
            : null,
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

  Future<void> _handleStartWorkout() async {
    try {
      setState(() {
        _isStartingWorkout = true;
        _workoutStarted = true;
      });

      // Se em modo execution, cria a WorkoutSession no backend
      if (widget.sessionId != null && widget.sessionId!.isNotEmpty) {
        if (kDebugMode) {
          print('🚀 Iniciando execução de treino em modo execution');
        }

        await ref
            .read(workoutDayExercisesProvider.notifier)
            .startExecution(
              routineId: widget.routineId,
              sessionId: widget.sessionId,
              isManual: widget.manualDate != null,
            );

        if (kDebugMode) {
          print('✅ WorkoutSession criada com sucesso');
        }
      }

      // Treino manual não usa o timer em tempo real
      if (_selectedDate == null) {
        ref.read(workoutControllerProvider.notifier).startWorkout();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao iniciar treino: $e');
      }

      setState(() {
        _isStartingWorkout = false;
        _workoutStarted = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao iniciar treino: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStartingWorkout = false;
        });
      }
    }
  }

  /// Exibe um dialog para o usuário informar a duração estimada do treino.
  /// Retorna null se o usuário cancelar.
  Future<Duration?> _pickDuration(BuildContext context) async {
    final hoursCtrl = TextEditingController(text: '1');
    final minutesCtrl = TextEditingController(text: '0');

    return showDialog<Duration>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Duração do treino'),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: hoursCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Horas',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: minutesCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Minutos',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final h = int.tryParse(hoursCtrl.text) ?? 0;
              final m = int.tryParse(minutesCtrl.text) ?? 0;
              Navigator.pop(ctx, Duration(hours: h, minutes: m));
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _showAddExerciseBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => AddExerciseBottomSheet(
        onExerciseSelected: (searchExercise) {
          _addExercise(searchExercise);
        },
      ),
    );
  }

  void _addExercise(SearchExercise searchExercise) {
    final newExercise = WorkoutExercise(
      id: searchExercise.id,
      name: searchExercise.name,
      tag: _mapExerciseTag(searchExercise.category ?? ''),
      muscles: searchExercise.primaryMuscle ?? 'Não especificado',
      variation: 'Traditional',
      series: 0, // Começa sem séries - usuário adiciona
      reps: '', // Vazio para o usuário preencher
      weight: '', // Vazio para o usuário preencher
      rir: 0, // Zerado
      restTime: 0, // Zerado
    );

    ref.read(workoutDayExercisesProvider.notifier).addExercise(newExercise);
  }

  ExerciseTag _mapExerciseTag(String category) {
    switch (category.toLowerCase()) {
      case 'multi':
        return ExerciseTag.multi;
      case 'iso':
        return ExerciseTag.iso;
      case 'cardio':
        return ExerciseTag.cardio;
      case 'funcional':
      case 'functional':
        return ExerciseTag.functional;
      default:
        return ExerciseTag.multi;
    }
  }

  void _discardWorkout() async {
    try {
      await ref.read(workoutControllerProvider.notifier).discardWorkout();
    } catch (e) {
      if (kDebugMode) {
        print('Aviso: falha ao descartar treino: $e');
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Treino descartado'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    }
  }

  int _calculateSeriesDone(List<WorkoutExercise> exercises) {
    // TODO: Implementar cálculo real baseado no histórico de séries completadas
    // Por enquanto, retorna o total de séries configuradas
    return exercises.fold<int>(0, (sum, exercise) => sum + exercise.series);
  }

  double _calculateVolume(List<WorkoutExercise> exercises) {
    // TODO: Implementar cálculo real baseado no peso registrado
    // Por enquanto, tenta extrair valor numérico do campo weight
    return exercises.fold<double>(0.0, (sum, exercise) {
      final weightStr = exercise.weight.replaceAll(RegExp(r'[^0-9.]'), '');
      final weight = double.tryParse(weightStr) ?? 0.0;
      return sum + (weight * exercise.series);
    });
  }

  int _calculateCompletion(List<WorkoutExercise> exercises) {
    // TODO: Implementar cálculo real baseado no progresso do treino
    // Por enquanto, retorna 0% pois é um novo treino
    return 0;
  }

  /// Constrói a lista de ExerciseSummary a partir da lista de WorkoutExercise
  List<ExerciseSummary> _buildExerciseSummaries(
    List<WorkoutExercise> exercises,
  ) {
    return exercises.map((exercise) {
      // Para cada exercício, cria séries de mock baseado no número de séries configuradas
      // TODO: Buscar dados reais de séries completadas do backend/banco de dados
      final series = List<SerieLog>.generate(exercise.series, (index) {
        final serieNumber = index + 1;
        // Determina o tipo da série
        String serieType = 'work';
        if (serieNumber == 1) {
          serieType = 'warmup'; // Primeira série é aquecimento
        }

        // Por enquanto, todas as séries são marcadas como "completed"
        // TODO: Buscar status real do banco de dados
        return SerieLog(
          serieNumber: serieNumber,
          type: serieType,
          weight: exercise.weight,
          reps: exercise.reps,
          rir: exercise.rir.toString(),
          status: 'completed', // TODO: Buscar status real
        );
      });

      return ExerciseSummary(
        id: exercise.id,
        name: exercise.name,
        muscleGroup: exercise.muscles,
        series: series,
      );
    }).toList();
  }
}
