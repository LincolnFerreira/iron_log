import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/components/app_snackbar.dart';
import 'package:iron_log/features/routines/domain/entities/search_exercise.dart';
import 'package:iron_log/features/workout_day/data/services/workout_log_service.dart';
import 'package:iron_log/features/workout_day/domain/entities/exercise_tag.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_draft.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_exercise.dart';
import 'package:iron_log/features/workout_day/domain/enums/workout_screen_mode.dart';
import 'package:iron_log/features/workout_day/presentation/components/molecules/workout_day_header.dart';
import 'package:iron_log/features/workout_day/presentation/components/organisms/add_exercise_bottom_sheet.dart';
import 'package:iron_log/features/workout_day/presentation/components/organisms/exercise_reorder_sheet.dart';
import 'package:iron_log/features/workout_day/presentation/components/organisms/reorderable_exercises_list.dart';
import 'package:iron_log/features/workout_day/presentation/controllers/workout_controller.dart';
import 'package:iron_log/features/workout_day/presentation/controllers/workout_finish_flow.dart';
import 'package:iron_log/features/workout_day/presentation/organisms/exercise_skeleton_card.dart';
import 'package:iron_log/features/workout_day/presentation/organisms/footer_actions.dart';
import 'package:iron_log/features/workout_day/presentation/providers/workout_day_provider.dart';
import 'package:iron_log/features/workout_day/presentation/providers/workout_timer_provider.dart';
import 'package:iron_log/features/workout_day/presentation/providers/workout_ui_feedback_provider.dart';
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

  /// Registro/edição de histórico: rodapé de cargas ativo sem "Iniciar" nem timer.
  bool get _isRetroactiveLog =>
      widget.manualDate != null ||
      (widget.workoutId != null && widget.workoutId!.isNotEmpty);

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.manualDate;
    // Ativa o assistente de cargas imediatamente no fluxo retroativo.
    _workoutStarted = _isRetroactiveLog;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Determina e define o modo de operação baseado nos parâmetros do widget
      final mode = _determineMode();
      ref.read(workoutScreenModeProvider.notifier).state = mode;

      if (_isRetroactiveLog) {
        _syncDraftContext();
      }

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
      showWorkoutUiFeedback(
        ref,
        WorkoutUiFeedbackMessage.warning(
          title: 'Rascunho indisponível',
          message: e is WorkoutDraftCorruptException
              ? 'Os dados salvos estão corrompidos e não puderam ser restaurados. '
                    'O rascunho permanece no dispositivo para revisão em Treinos pendentes.'
              : 'Não foi possível carregar o treino salvo. Tente novamente.',
        ),
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
    try {
      await ref
          .read(workoutDayExercisesProvider.notifier)
          .flushPersistInProgressDraft();
    } catch (e) {
      if (kDebugMode) {
        print('Aviso: falha ao persistir rascunho ao sair: $e');
      }
    }
  }

  bool get _shouldGuardBackNavigation =>
      _isRetroactiveLog && _workoutStarted;

  /// Impede sair sem aviso no registro/edição de histórico.
  Future<bool> _confirmLeaveRetroactive() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair do treino?'),
        content: const Text(
          'Seu progresso será salvo como rascunho. '
          'Na Home você pode continuar de onde parou.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuar editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Header e system back passam por aqui (maybePop) — nunca Navigator.pop cru.
  Future<void> _handleBackPressed() async {
    final navigator = Navigator.of(context);
    if (!_shouldGuardBackNavigation) {
      await _flushDraftOnExit();
      if (mounted) navigator.pop();
      return;
    }
    final leave = await _confirmLeaveRetroactive();
    if (!leave || !mounted) return;
    await _flushDraftOnExit();
    if (mounted) navigator.pop();
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
      // Retroativo: grava rascunho local assim que a sessão carrega
      // (não depende de upload; aparece em Continuar treino na Home).
      if (_isRetroactiveLog && mounted) {
        _syncDraftContext();
        await ref
            .read(workoutDayExercisesProvider.notifier)
            .flushPersistInProgressDraft();
      }
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
      if (_isRetroactiveLog && mounted) {
        _syncDraftContext();
        await ref
            .read(workoutDayExercisesProvider.notifier)
            .flushPersistInProgressDraft();
      }
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
          showWorkoutUiFeedback(
            ref,
            WorkoutUiFeedbackMessage.error(
              title: 'Data do treino',
              message: 'Não foi possível salvar a nova data.',
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(workoutUiFeedbackProvider, (previous, next) {
      if (next == null || !mounted) return;
      switch (next.kind) {
        case WorkoutUiFeedbackKind.success:
          AppSnackbar.success(
            context: context,
            title: next.title,
            message: next.message,
          );
        case WorkoutUiFeedbackKind.warning:
          AppSnackbar.warning(
            context: context,
            title: next.title,
            message: next.message,
          );
        case WorkoutUiFeedbackKind.error:
          AppSnackbar.error(
            context: context,
            title: next.title,
            message: next.message,
          );
        case WorkoutUiFeedbackKind.info:
          AppSnackbar.warning(
            context: context,
            title: next.title,
            message: next.message,
          );
      }
      ref.read(workoutUiFeedbackProvider.notifier).clear();
    });

    final exercisesAsync = ref.watch(workoutDayExercisesProvider);
    final controllerLoading = ref.watch(
      workoutControllerProvider.select((state) => state.isLoading),
    );

    Future<void> openReorderSheet() async {
      final current = ref.read(workoutDayExercisesProvider).value ?? [];
      if (current.isEmpty) return;
      final result = await ExerciseReorderSheet.show(context, current);
      if (result != null && result.isNotEmpty) {
        ref.read(workoutDayExercisesProvider.notifier).replaceExercises(result);
      }
    }

    return PopScope(
      // canPop false só no retroativo: system back cai em onPopInvoked.
      // O botão do header usa _handleBackPressed (não Navigator.pop cru).
      canPop: !_shouldGuardBackNavigation,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          // Rota já saiu (treino ao vivo / sem guarda): best-effort.
          unawaited(_flushDraftOnExit());
          return;
        }
        await _handleBackPressed();
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
                onBackPressed: () {
                  unawaited(_handleBackPressed());
                },
                onMorePressed: openReorderSheet,
                existingDuration: ref.watch(workoutOriginalDurationProvider),
              ),
              loading: () => WorkoutDayHeader(
                title: widget.subtitle ?? 'Exercícios do Dia',
                subtitle: 'Carregando...',
                manualDate: _selectedDate,
                onDateTap: _selectedDate != null ? _changeDate : null,
                onBackPressed: () {
                  unawaited(_handleBackPressed());
                },
                onMorePressed: openReorderSheet,
                existingDuration: ref.watch(workoutOriginalDurationProvider),
              ),
              error: (_, _) => WorkoutDayHeader(
                title: widget.subtitle ?? 'Exercícios do Dia',
                subtitle: 'Erro ao carregar',
                manualDate: _selectedDate,
                onDateTap: _selectedDate != null ? _changeDate : null,
                onBackPressed: () {
                  unawaited(_handleBackPressed());
                },
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
                isLoading: controllerLoading || _isStartingWorkout,
                onStartWorkout: _handleStartWorkout,
                onFinishWorkout: () async {
                  ref
                      .read(workoutDayExercisesProvider.notifier)
                      .flushPendingExerciseMemoryUpdates();
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
                      // Em retroativo o rodapé já nasce "iniciado"; não desativa
                      // o assistente de cargas se o usuário cancelar a duração.
                      if (mounted && !_isRetroactiveLog) {
                        setState(() => _workoutStarted = false);
                      }
                    },
                  );
                },
                onDiscard: () => _discardWorkout(),
                onSaveTrain: () async {
                  if (widget.sessionId == null || widget.sessionId!.isEmpty) {
                    showWorkoutUiFeedback(
                      ref,
                      WorkoutUiFeedbackMessage.warning(
                        title: 'Sessão',
                        message: 'Nenhuma sessão associada para salvar.',
                      ),
                    );
                    return;
                  }

                  try {
                    await ref
                        .read(workoutDayExercisesProvider.notifier)
                        .saveSessionExercises(widget.sessionId!);
                    showWorkoutUiFeedback(
                      ref,
                      WorkoutUiFeedbackMessage.success(
                        title: 'Treino salvo',
                        message: 'Treino salvo com sucesso',
                      ),
                    );
                  } catch (e) {
                    showWorkoutUiFeedback(
                      ref,
                      WorkoutUiFeedbackMessage.error(
                        title: 'Erro ao salvar',
                        message: 'Erro ao salvar treino: $e',
                      ),
                    );
                  }
                },
              )
            : null,
        loading: () => null,
        error: (_, _) => null,
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
        showWorkoutUiFeedback(
          ref,
          WorkoutUiFeedbackMessage.error(
            title: 'Erro ao iniciar',
            message: 'Erro ao iniciar treino: $e',
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
      showWorkoutUiFeedback(
        ref,
        WorkoutUiFeedbackMessage.warning(
          title: 'Treino descartado',
          message: 'Treino descartado',
        ),
      );
      Navigator.pop(context);
    }
  }
}
