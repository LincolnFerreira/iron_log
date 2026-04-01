import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/app_colors.dart';
import 'package:iron_log/features/routines/domain/entities/search_exercise.dart';
import 'package:iron_log/features/routines/presentation/providers/exercise_browse_provider.dart';
import 'package:iron_log/features/routines/presentation/providers/session_selection_provider.dart';

/// Lista de exercícios agrupada por músculo, ordenada por popularidade.
/// Exibida quando não há query de busca ativa.
class ExerciseBrowseList extends ConsumerWidget {
  final Function(SearchExercise)? onExerciseSelected;

  const ExerciseBrowseList({super.key, this.onExerciseSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final browseAsync = ref.watch(exerciseBrowseProvider);

    return browseAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Erro ao carregar exercícios',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ),
      data: (groups) => ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return ExerciseMuscleGroupTile(
            muscle: group.muscle,
            exercises: group.exercises,
            onExerciseSelected: onExerciseSelected,
          );
        },
      ),
    );
  }
}

/// Tile expansível para um grupo muscular com seus exercícios.
class ExerciseMuscleGroupTile extends ConsumerWidget {
  final String muscle;
  final List<SearchExercise> exercises;
  final Function(SearchExercise)? onExerciseSelected;

  const ExerciseMuscleGroupTile({
    super.key,
    required this.muscle,
    required this.exercises,
    this.onExerciseSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIds = ref.watch(sessionAllExerciseIdsProvider);
    final theme = Theme.of(context);

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 4),
      childrenPadding: EdgeInsets.zero,
      title: Text(
        muscle,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondaryLight,
          letterSpacing: 0.5,
        ),
      ),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.fitness_center,
          size: 16,
          color: AppColors.primaryLight,
        ),
      ),
      children: exercises
          .map(
            (ex) => ExerciseBrowseItem(
              exercise: ex,
              isSelected: selectedIds.contains(ex.id),
              onTap: () => onExerciseSelected?.call(ex),
            ),
          )
          .toList(),
    );
  }
}

/// Item individual de exercício dentro do browse agrupado.
class ExerciseBrowseItem extends StatelessWidget {
  final SearchExercise exercise;
  final bool isSelected;
  final VoidCallback onTap;

  const ExerciseBrowseItem({
    super.key,
    required this.exercise,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: isSelected
            ? AppColors.primaryLight.withOpacity(0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryLight.withOpacity(0.4)
                    : AppColors.primaryLight.withOpacity(0.12),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryLight.withOpacity(0.14)
                        : AppColors.primaryLight.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    size: 20,
                    color: isSelected
                        ? AppColors.primaryLight
                        : AppColors.gray50,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (exercise.equipment != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          exercise.equipment!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(
                              0.55,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.add_circle_outline_rounded,
                  size: 22,
                  color: isSelected
                      ? AppColors.blue100
                      : AppColors.primaryLight.withOpacity(0.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
