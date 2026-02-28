import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../organisms/footer_actions.dart';
import '../../../workout_session/presentation/pages/workout_session_screen.dart';
import '../components/molecules/workout_day_header.dart';
import '../components/molecules/workout_title_section.dart';
import '../components/molecules/exercise_search_bar.dart';
import '../components/organisms/reorderable_exercises_list.dart';
import '../../domain/entities/workout_exercise.dart';
import '../../domain/entities/exercise_tag.dart';
import '../../../routines/domain/entities/search_exercise.dart';
import '../providers/workout_day_provider.dart';

class WorkoutDayScreen extends ConsumerStatefulWidget {
  final String? routineId; // rotina atual para contexto
  final String? sessionId; // sessão específica que será treinada
  final String? subtitle; // ex: 'Segunda-feira • PPL: Push'
  const WorkoutDayScreen({
    super.key,
    this.routineId,
    this.sessionId,
    this.subtitle,
  });

  @override
  ConsumerState<WorkoutDayScreen> createState() => _WorkoutDayScreenState();
}

class _WorkoutDayScreenState extends ConsumerState<WorkoutDayScreen> {
  @override
  void initState() {
    super.initState();
    // Carrega a sessão específica se o ID for fornecido
    if (widget.sessionId != null && widget.sessionId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadSession();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Auto-reload quando retornar para a tela (ex: de "organize suas sessões")
    if (widget.sessionId != null && widget.sessionId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _reloadSessionIfNeeded();
      });
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(workoutDayExercisesProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            const WorkoutDayHeader(),
            const SizedBox(height: 24),
            // Title Section
            exercisesAsync.when(
              data: (exercises) => WorkoutTitleSection(
                title: widget.subtitle ?? 'Erro inesperado',
                exerciseCount: '${exercises.length} exercícios adicionados',
              ),
              loading: () => const WorkoutTitleSection(
                title: 'Carregando...',
                exerciseCount: 'Carregando exercícios...',
              ),
              error: (error, _) => WorkoutTitleSection(
                title: widget.subtitle ?? 'Erro inesperado',
                exerciseCount: 'Erro ao carregar exercícios',
              ),
            ),
            const SizedBox(height: 16),
            // Search Bar
            ExerciseSearchBar(onExerciseSelected: _addExercise),
            const SizedBox(height: 16),
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
                              'Use o botão + para adicionar exercícios',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withValues(alpha: 0.6),
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ReorderableExercisesList(
                        exercises: exercises,
                        sessionId: widget.sessionId, // Passa o sessionId
                        onReorder: (oldIndex, newIndex) {
                          ref
                              .read(workoutDayExercisesProvider.notifier)
                              .reorderExercises(oldIndex, newIndex);
                        },
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
                onStartWorkout: () => _startWorkoutSession(exercises),
                onSaveRoutine: () => _saveRoutine(exercises),
              )
            : null,
        loading: () => null,
        error: (_, __) => null,
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
      series: 3,
      reps: '10-12',
      weight: '0kg',
      rir: 2,
      restTime: 120,
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

  void _startWorkoutSession(List<WorkoutExercise> exercises) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkoutSessionScreen(
          workoutId: 'workout_${DateTime.now().millisecondsSinceEpoch}',
          subtitle: widget.subtitle ?? 'Treino do dia',
        ),
      ),
    );
  }

  void _saveRoutine(List<WorkoutExercise> exercises) async {
    try {
      final sessionId = widget.sessionId;
      if (sessionId != null) {
        // Usa o método que JÁ EXISTE no provider
        await ref
            .read(workoutDayExercisesProvider.notifier)
            .saveSessionExercises(sessionId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Exercícios salvos com sucesso'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
