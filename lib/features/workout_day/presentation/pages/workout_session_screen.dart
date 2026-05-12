import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/app_colors.dart';
import 'package:iron_log/core/components/exercise_search/exercise_search.dart';
import 'package:iron_log/core/extensions/string_extensions.dart';
import 'package:iron_log/features/routines/domain/entities/search_exercise.dart';
import '../../../home/components/organisms/session_picker_sheet.dart';
import '../../../home/state/home_provider.dart';
import '../../../routines/domain/entities/routine.dart';
import '../../data/services/workout_log_service.dart';
import '../../domain/entities/exercise_tag.dart';
import '../../domain/entities/workout_exercise.dart';
import '../../domain/enums/workout_screen_mode.dart';
import '../../domain/workout_mode.dart';
import '../components/molecules/add_exercise_search_results.dart';
import '../components/molecules/add_exercise_added_list.dart';
import '../components/organisms/session_exercises_sheet.dart';
import '../components/organisms/session_floating_bar.dart';
import '../controllers/workout_controller.dart';
import '../organisms/exercise_skeleton_card.dart';
import '../providers/workout_day_provider.dart';
import '../providers/workout_timer_provider.dart';
import '../widgets/voice_input_bottom_sheet.dart';
import './workout_summary_screen.dart';

class WorkoutSessionScreen extends ConsumerStatefulWidget {
  final String? routineId;
  final String? sessionId;
  final String? subtitle;
  final DateTime? manualDate;
  final String? workoutId;

  const WorkoutSessionScreen({
    super.key,
    this.routineId,
    this.sessionId,
    this.subtitle,
    this.manualDate,
    this.workoutId,
  });

  const WorkoutSessionScreen.create({
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

  const WorkoutSessionScreen.manual({
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

  const WorkoutSessionScreen.edit({
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
  ConsumerState<WorkoutSessionScreen> createState() =>
      _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends ConsumerState<WorkoutSessionScreen> {
  bool _workoutStarted = false;
  bool _isStartingWorkout = false;
  DateTime? _selectedDate;

  final TextEditingController _searchController = TextEditingController();
  List<SearchExercise> _addedExercises = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.manualDate;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final mode = _determineMode();
      ref.read(workoutScreenModeProvider.notifier).state = mode;

      ref.read(exerciseSearchProvider.notifier).clearSearch();

      if (widget.workoutId != null && widget.workoutId!.isNotEmpty) {
        _loadExistingWorkout();
      } else if (widget.sessionId != null && widget.sessionId!.isNotEmpty) {
        _loadSession();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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
      await ref
          .read(workoutDayExercisesProvider.notifier)
          .reloadSession(widget.sessionId!, routineId: widget.routineId);
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao recarregar sessão: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(workoutDayExercisesProvider);
    final searchState = ref.watch(exerciseSearchProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: _buildSearchAppBar(context, isDark),
      body: Stack(
        children: [
          // Main content: search results / empty / added list
          Column(
            children: [
              if (_selectedDate != null)
                _buildDateBadge(context, isDark),
              Expanded(
                child: exercisesAsync.when(
                  skipLoadingOnRefresh: false,
                  data: (_) => _buildSearchContent(context, searchState, isDark),
                  loading: () => ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 3,
                    itemBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: ExerciseSkeleton(),
                    ),
                  ),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Erro ao carregar exercícios',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
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
          // Floating bar
          exercisesAsync.whenOrNull(
                data: (exercises) => exercises.isNotEmpty
                    ? Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: SessionFloatingBar(
                          exercises: exercises,
                          onClear: _clearExercises,
                          onViewSession: () => _openSessionSheet(exercises),
                          workoutStarted: _workoutStarted,
                        ),
                      )
                    : null,
              ) ??
              const SizedBox.shrink(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildSearchAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          // Search field (80%)
          Expanded(
            flex: 4,
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: isDark ? AppColors.dark40 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar exercícios...',
                  hintStyle: TextStyle(
                    fontSize: 15,
                    color: isDark ? AppColors.gray50 : Colors.grey.shade500,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: isDark ? AppColors.gray50 : Colors.grey.shade500,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            size: 18,
                            color: isDark
                                ? AppColors.gray50
                                : Colors.grey.shade500,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(exerciseSearchProvider.notifier)
                                .clearSearch();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onChanged: (value) {
                  ref
                      .read(exerciseSearchProvider.notifier)
                      .updateQuery(value);
                  setState(() {});
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Mic button (20%)
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 42,
              child: Material(
                color: isDark
                    ? AppColors.primaryDark.withOpacity(0.15)
                    : AppColors.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _openVoiceInput,
                  child: Icon(
                    Icons.mic,
                    size: 22,
                    color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      actions: const [SizedBox(width: 12)],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          color: isDark ? AppColors.dark40 : Colors.grey.shade200,
        ),
      ),
    );
  }

  Widget _buildDateBadge(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark
          ? theme.colorScheme.tertiaryContainer.withOpacity(0.2)
          : theme.colorScheme.tertiaryContainer.withOpacity(0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 14,
            color: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 6),
          Text(
            'Treino de ${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_selectedDate != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _changeDate,
              child: Icon(
                Icons.edit_calendar_outlined,
                size: 16,
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchContent(
    BuildContext context,
    ExerciseSearchState searchState,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    if (searchState.query.isNotEmpty) {
      if (searchState.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (searchState.results.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: isDark ? AppColors.gray50 : Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhum exercício encontrado para "${searchState.query}"',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.gray50 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final created = await ref
                        .read(exerciseSearchProvider.notifier)
                        .createExercise(searchState.query);
                    if (created != null && mounted) {
                      _onExerciseSelected(created);
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: Text("Criar '${searchState.query}'"),
                ),
              ],
            ),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 140),
        child: AddExerciseSearchResults(
          results: searchState.results,
          addedExercises: _addedExercises,
          onExerciseSelected: _onExerciseSelected,
        ),
      );
    }

    if (_addedExercises.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 140),
        child: AddExerciseAddedList(addedExercises: _addedExercises),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: isDark ? AppColors.gray50 : Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'Encontre seu exercício',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Digite o nome do exercício na barra acima\nou use o microfone para buscar por voz.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.gray50 : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ex: supino, agachamento, remada...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.gray50 : Colors.grey.shade400,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Actions ────────────────────────────────────────────────────────

  void _onExerciseSelected(SearchExercise exercise) {
    if (_addedExercises.any((e) => e.id == exercise.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${exercise.name.toTitleCase()} já foi adicionado'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _addExercise(exercise);

    setState(() {
      _addedExercises.add(exercise);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${exercise.name.toTitleCase()} adicionado'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
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
      series: 0,
      reps: '',
      weight: '',
      rir: 0,
      restTime: 0,
    );

    ref.read(workoutDayExercisesProvider.notifier).addExercise(newExercise);
  }

  void _clearExercises() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Limpar exercícios'),
        content: const Text(
          'Tem certeza que deseja remover todos os exercícios selecionados?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(workoutDayExercisesProvider.notifier).clearExercises();
              setState(() {
                _addedExercises.clear();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }

  void _openSessionSheet(List<WorkoutExercise> exercises) {
    SessionExercisesSheet.show(
      context,
      exercises: exercises,
      sessionId: widget.sessionId,
      sessionName: widget.subtitle,
      workoutStarted: _workoutStarted,
      isLoading: ref.read(workoutControllerProvider).isLoading ||
          _isStartingWorkout,
      onReorder: (oldIndex, newIndex) {
        ref
            .read(workoutDayExercisesProvider.notifier)
            .reorderExercises(oldIndex, newIndex);
      },
      onStartWorkout: () {
        Navigator.pop(context);
        _handleContinueWorkout();
      },
      onSaveDraft: widget.sessionId != null
          ? () async {
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
            }
          : null,
    );
  }

  void _handleContinueWorkout() {
    if (_isStartingWorkout) return;
    final mode = _determineMode();
    if (mode == WorkoutScreenMode.editing) {
      _handleFinishWorkout();
    } else if (_selectedDate != null) {
      _handleFinishWorkout();
    } else if (_workoutStarted) {
      _handleFinishWorkout();
    } else {
      _handleStartWorkout();
    }
  }

  void _openVoiceInput() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (_) => VoiceInputBottomSheet(sessionId: widget.sessionId),
    );
  }

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

    if (widget.workoutId != null && widget.workoutId!.isNotEmpty) {
      try {
        final originalDuration = ref.read(workoutOriginalDurationProvider);
        DateTime? newEndedAt;
        if (originalDuration != null) {
          newEndedAt = picked.add(originalDuration);
        }
        await WorkoutLogService().patchDate(
          widget.workoutId!,
          picked,
          newEndedAt: newEndedAt,
        );
      } catch (e) {
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

  // ─── Workout lifecycle (same logic as WorkoutDayScreen) ─────────────

  Future<void> _handleStartWorkout() async {
    try {
      setState(() {
        _isStartingWorkout = true;
        _workoutStarted = true;
      });

      if (widget.sessionId != null && widget.sessionId!.isNotEmpty) {
        await ref
            .read(workoutDayExercisesProvider.notifier)
            .startExecution(
              routineId: widget.routineId,
              sessionId: widget.sessionId,
              isManual: widget.manualDate != null,
            );
      }

      if (_selectedDate == null) {
        ref.read(workoutControllerProvider.notifier).startWorkout();
      }
    } catch (e) {
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
        setState(() => _isStartingWorkout = false);
      }
    }
  }

  Future<void> _handleFinishWorkout() async {
    final exercises = ref.read(workoutDayExercisesProvider).value ?? [];
    final timerStartTime = ref.read(workoutTimerProvider);

    final mode = (widget.workoutId != null && widget.workoutId!.isNotEmpty)
        ? WorkoutMode.edit
        : (widget.manualDate != null ? WorkoutMode.manual : WorkoutMode.create);

    final controller = ref.read(workoutControllerProvider.notifier);

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
              content: Text('Nenhuma sessão disponível para selecionar.'),
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
          const SnackBar(content: Text('Treino atualizado com sucesso!')),
        );
        Navigator.of(context).pop();
      } else {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                WorkoutSummaryScreen(workoutSummary: result.summary!),
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
  }

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
}
