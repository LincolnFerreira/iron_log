import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/routines/domain/entities/routine.dart';
import '../../state/workout_provider.dart';
import '../molecules/workout_option_card.dart';

class WorkoutOptionsGrid extends ConsumerWidget {
  final VoidCallback onStartWorkout;
  final VoidCallback onChangeWorkout;
  final VoidCallback onQuickCreate;
  final VoidCallback? onRetryWorkout;
  final Routine? todaysRoutine;
  final Session? todaysSession;
  final bool isLoadingWorkout;
  final String? error;
  final int primary; // 0: start, 1: change, 2: quick create

  const WorkoutOptionsGrid({
    super.key,
    required this.onStartWorkout,
    required this.onChangeWorkout,
    required this.onQuickCreate,
    this.onRetryWorkout,
    this.todaysRoutine,
    this.todaysSession,
    this.isLoadingWorkout = false,
    this.error,
    this.primary = 0,
  });

  String _getWorkoutSubtitle() {
    if (error != null) {
      return 'Erro ao carregar';
    }
    if (isLoadingWorkout) {
      return 'Carregando...';
    }
    if (todaysRoutine == null) {
      return 'Nenhuma rotina encontrada';
    }
    if (todaysSession == null) {
      return 'Nenhuma sessão para hoje';
    }
    return '${todaysSession!.name} (${todaysSession!.exercises.length} exercícios)';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final workoutState = ref.watch(workoutProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('O que vamos fazer hoje?', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Column(
          children: [
            WorkoutOptionCard(
              title: error != null
                  ? 'Tentar novamente'
                  : 'Iniciar treino de hoje',
              subtitle: _getWorkoutSubtitle(),
              icon: error != null ? Icons.refresh : Icons.play_arrow,
              onTap: () {
                if (error != null && onRetryWorkout != null) {
                  onRetryWorkout!();
                } else {
                  ref.read(workoutProvider.notifier).startWorkout();
                  onStartWorkout();
                }
              },
              isPrimary: primary == 0,
              isLoading: workoutState.isLoading || isLoadingWorkout,
              isEnabled:
                  (todaysSession != null &&
                      !isLoadingWorkout &&
                      error == null) ||
                  (error != null && onRetryWorkout != null),
            ),
            WorkoutOptionCard(
              title: 'Trocar treino do dia',
              subtitle: todaysSession != null
                  ? 'Sessão atual: ${todaysSession!.name}'
                  : 'Escolher outro treino',
              icon: Icons.sync,
              onTap: onChangeWorkout,
              isPrimary: primary == 1,
            ),
            WorkoutOptionCard(
              title: 'Criar treino rápido',
              subtitle: 'Exercícios personalizados',
              icon: Icons.edit,
              onTap: onQuickCreate,
              isPrimary: primary == 2,
            ),
          ],
        ),
      ],
    );
  }
}
