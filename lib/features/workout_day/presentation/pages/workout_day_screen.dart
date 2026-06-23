import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/components/app_snackbar.dart';
import '../../../routines/domain/entities/search_exercise.dart';
import '../../data/services/workout_log_service.dart';
import '../../domain/entities/exercise_tag.dart';
import '../../domain/entities/workout_draft.dart';
import '../../domain/entities/workout_exercise.dart';
import '../components/molecules/workout_day_header.dart';
import '../components/organisms/add_exercise_bottom_sheet.dart';
import '../components/organisms/reorderable_exercises_list.dart';
import '../components/organisms/exercise_reorder_sheet.dart';
import '../organisms/footer_actions.dart';
import '../organisms/exercise_skeleton_card.dart';
import '../providers/workout_day_provider.dart';
import '../providers/workout_timer_provider.dart';
import '../controllers/workout_controller.dart';
import '../controllers/workout_finish_flow.dart';
import '../../domain/enums/workout_screen_mode.dart';
import 'package:iron_log/features/workout_day/presentation/widgets/voice_input_bottom_sheet.dart';

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

  /// Quando definido, retoma rascunho local em andamento.
  final String? resumeDraftId;

  const WorkoutDayScreen({
    super.key,
    this.routineId,
    this.sessionId,
    this.subtitle,
    this.manualDate,
    this.workoutId,
    this.resumeDraftId,
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

  const WorkoutDayScreen.resume({
    Key? key,
    required String draftId,
  }) : this(
         key: key,
         resumeDraftId: draftId,
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

      if (widget.resumeDraftId != null) {
        _loadDraft(widget.resumeDraftId!);
      } else if (widget.workoutId != null && widget.workoutId!.isNotEmpty) {
        // Modo edição: carrega treino existente pelo ID do WorkoutSession.
        _loadExistingWorkout();
      } else if (widget.sessionId != null && widget.sessionId!.isNotEmpty) {
        // Modo normal: carrega exercícios da sessão do plano de treino.
        _loadSession();
      }
    });
  }

  Future<void> _loadDraft(String draftId) async {
    try {
      await ref
          .read(workoutDayExercisesProvider.notifier)
          .loadDraftForResume(draftId);
      if (mounted) {
        setState(() {
          _workoutStarted = true;
        });
        _syncDraftContext();
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.warning(
        context: context,
        title: 'Rascunho indisponível',
        message: e is WorkoutDraftCorruptException
            ? 'Os dados salvos estão corrompidos e não puderam ser restaurados. '
                  'O rascunho permanece no dispositivo para revisão em Treinos pendentes.'
            : 'Não foi possível carregar o treino salvo. Tente novamente.',
      );
      if (kDebugMode) {
        print('Erro ao carregar rascunho: $e');
      }
    }
  }

  void _syncDraftContext() {
    ref.read(workoutDayExercisesProvider.notifier).setDraftExecutionContext(
      WorkoutDraftExecutionContext(
        workoutStarted: _workoutStarted,
        subtitle: widget.subtitle,
        routineId: widget.routineId,
        sessionId: widget.sessionId,
        manualDate: _selectedDate,
      ),
    );
  }

  Future<void> _flushDraftOnExit() async {
    if (!_workoutStarted) return;
    _syncDraftContext();
    await ref
        .read(workoutDayExercisesProvider.notifier)
        .flushPersistInProgressDraft();
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
  /// - execution: treino ao vivo a partir do plano (home) ou retroativo com data
  /// - template: edição de template sem sessão ligada à execução do dia
  WorkoutScreenMode _determineMode() {
    if (widget.workoutId != null && widget.workoutId!.isNotEmpty) {
      return WorkoutScreenMode.editing;
    }
    if (widget.manualDate != null) {
      return WorkoutScreenMode.execution;
    }
    if (widget.sessionId != null &&
        widget.sessionId!.isNotEmpty &&
        widget.routineId != null &&
        widget.routineId!.isNotEmpty) {
      return WorkoutScreenMode.execution;
    }
    return WorkoutScreenMode.template;
  }

  Future<void> _loadSession() async {
    if (widget.sessionId == null) return;

    try {
      await ref
          .read(workoutDayExercisesProvider.notifier)
          .loadSession(widget.sessionId!, routineId: widget.routineId);
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
          .reloadSession(widget.sessionId!, routineId: widget.routineId);
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

    Future<void> openReorderSheet() async {
      final current = ref.read(workoutDayExercisesProvider).value ?? [];
      if (current.isEmpty) return;
      final result = await ExerciseReorderSheet.show(context, current);
      if (result != null && result.isNotEmpty) {
        ref.read(workoutDayExercisesProvider.notifier).replaceExercises(result);
      }
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          unawaited(_flushDraftOnExit());
        }
      },
      child: Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            exercisesAsync.when(
              skipLoadingOnRefresh: false,
              data: (exercises) => WorkoutDayHeader(
                title: widget.subtitle ?? 'Exercícios do Dia',
                subtitle: exercises.isEmpty
                    ? 'Nenhum exercício'
                    : '${exercises.length} exercício${exercises.length > 1 ? 's' : ''}',
                manualDate: _selectedDate,
                onDateTap: _selectedDate != null ? _changeDate : null,
                onMorePressed: openReorderSheet,
                existingDuration: ref.watch(workoutOriginalDurationProvider),
              ),
              loading: () => WorkoutDayHeader(
                title: widget.subtitle ?? 'Exercícios do Dia',
                subtitle: 'Carregando...',
                manualDate: _selectedDate,
                onDateTap: _selectedDate != null ? _changeDate : null,
                onMorePressed: openReorderSheet,
                existingDuration: ref.watch(workoutOriginalDurationProvider),
              ),
              error: (_, __) => WorkoutDayHeader(
                title: widget.subtitle ?? 'Exercícios do Dia',
                subtitle: 'Erro ao carregar',
                manualDate: _selectedDate,
                onDateTap: _selectedDate != null ? _changeDate : null,
                onMorePressed: openReorderSheet,
                existingDuration: ref.watch(workoutOriginalDurationProvider),
              ),
            ),
            const SizedBox(height: 24),
            // Content
            Expanded(
              child: exercisesAsync.when(
                skipLoadingOnRefresh: false,
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
                loading: () => ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 3,
                  itemBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: ExerciseSkeleton(),
                  ),
                ),
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
        skipLoadingOnRefresh: false,
        data: (exercises) => exercises.isNotEmpty
            ? FooterActions(
                exercises: exercises,
                sessionTitle: widget.subtitle,
                onMoreOptions: openReorderSheet,
                isManual: _selectedDate != null,
                workoutStarted: _workoutStarted,
                isLoading:
                    ref.watch(workoutControllerProvider).isLoading ||
                    _isStartingWorkout,
                onStartWorkout: _handleStartWorkout,
                onFinishWorkout: () async {
                  final exercises =
                      ref.read(workoutDayExercisesProvider).value ?? [];
                  final mode = WorkoutFinishFlow.resolveMode(
                    workoutId: widget.workoutId,
                    manualDate: widget.manualDate,
                  );

                  await WorkoutFinishFlow.run(
                    context: context,
                    ref: ref,
                    mode: mode,
                    exercises: exercises,
                    routineId: widget.routineId,
                    sessionId: widget.sessionId,
                    workoutId: widget.workoutId,
                    selectedDate: _selectedDate,
                    isMounted: () => mounted,
                    onWorkoutNotStarted: () {
                      if (mounted) setState(() => _workoutStarted = false);
                    },
                  );
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
      floatingActionButton: FloatingActionButton(
        tooltip: _workoutStarted
            ? 'Buscar exercício por voz'
            : 'Inicie o treino para usar o microfone',
        heroTag: 'workout_day_voice_fab',
        onPressed: _workoutStarted
            ? () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  builder: (_) =>
                      VoiceInputBottomSheet(sessionId: widget.sessionId),
                );
              }
            : null,
        child: const Icon(Icons.mic),
      ),
      ),
    );
  }

  Future<void> _handleStartWorkout() async {
    try {
      setState(() {
        _isStartingWorkout = true;
        _workoutStarted = true;
      });
      _syncDraftContext();

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
}
