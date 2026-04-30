import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/workout_history/presentation/components/molecules/workout_history_card.dart';
import '../../providers/routine_last_workout_provider.dart';

/// Seção exibida no rodapé do RoutineCard com os dados do último treino,
/// reutilizando o WorkoutHistoryCard da tela de histórico.
class RoutineLastWorkoutSection extends ConsumerWidget {
  final String routineId;

  const RoutineLastWorkoutSection({super.key, required this.routineId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ref
        .watch(routineLastWorkoutProvider(routineId))
        .when(
          skipLoadingOnRefresh: false,
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (workout) {
            if (workout == null) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(
                  height: 1,
                  color: colorScheme.outline.withOpacity(0.12),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 2),
                  child: Text(
                    'Último treino',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.4),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                WorkoutHistoryCard(workout: workout),
              ],
            );
          },
        );
  }
}
