import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/workout_provider.dart';

class WorkoutOptionsGrid extends ConsumerWidget {
  final VoidCallback onStartWorkout;
  final VoidCallback onChangeWorkout;
  final VoidCallback onQuickCreate;
  final int primary; // 0: start, 1: change, 2: quick create

  const WorkoutOptionsGrid({
    super.key,
    required this.onStartWorkout,
    required this.onChangeWorkout,
    required this.onQuickCreate,
    this.primary = 0,
  });

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
            _buildOptionCard(
              context,
              'Iniciar treino de hoje',
              workoutState.currentWorkout,
              Icons.play_arrow,
              () {
                ref.read(workoutProvider.notifier).startWorkout();
                onStartWorkout();
              },
              isPrimary: primary == 0,
              isLoading: workoutState.isLoading,
            ),
            _buildOptionCard(
              context,
              'Trocar treino do dia',
              'Escolher outro treino',
              Icons.sync,
              onChangeWorkout,
              isPrimary: primary == 1,
            ),
            _buildOptionCard(
              context,
              'Criar treino rápido',
              'Exercícios personalizados',
              Icons.edit,
              onQuickCreate,
              isPrimary: primary == 2,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isPrimary = false,
    bool isLoading = false,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final cardColor = isPrimary ? primaryColor : theme.cardColor;
    final textColor = isPrimary
        ? Colors.white
        : theme.textTheme.bodyMedium?.color;
    final subtitleColor = isPrimary
        ? Colors.white70
        : theme.textTheme.bodySmall?.color;

    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isPrimary
                      ? Color.alphaBlend(
                          Colors.white.withOpacity(0.18),
                          primaryColor,
                        )
                      : Colors.grey.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isPrimary
                    ? (isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Icon(icon, size: 24, color: Colors.white))
                    : Icon(icon, size: 24, color: theme.iconTheme.color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isPrimary ? Colors.white70 : Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
