import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/components/exercise_search/exercise_search.dart';
import 'package:iron_log/core/app_colors.dart';
import '../../domain/entities/search_exercise.dart';
import '../providers/session_selection_provider.dart';
import 'exercise_browse_list.dart';

/// Widget que exibe os exercícios disponíveis baseado na busca
class AvailableExercisesList extends ConsumerWidget {
  final Function(SearchExercise)? onExerciseSelected;

  const AvailableExercisesList({super.key, this.onExerciseSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(exerciseSearchProvider);
    // Assiste diretamente — rebuild imediato quando o usuário seleciona/deseleciona
    final selectedExerciseIds = ref.watch(sessionAllExerciseIdsProvider);

    if (searchState.query.isEmpty) {
      return ExerciseBrowseList(onExerciseSelected: onExerciseSelected);
    }

    if (searchState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchState.results.isEmpty) {
      return _buildNoResultsState(context, searchState.query);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: searchState.results.length,
      itemBuilder: (context, index) {
        final exercise = searchState.results[index];
        final isSelected = selectedExerciseIds.contains(exercise.id);
        return _buildExerciseCard(context, exercise, isSelected);
      },
    );
  }

  Widget _buildNoResultsState(BuildContext context, String query) {
    return SizedBox(
      height: 260,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center,
              size: 48,
              color: AppColors.primaryLight.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhum exercício encontrado\npara "$query"',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    SearchExercise exercise,
    bool isSelected,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: isSelected
            ? AppColors.primaryLight.withOpacity(0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            onExerciseSelected?.call(exercise);
          },
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
                // Ícone de categoria
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

                // Nome + detalhes
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
                      if (exercise.primaryMuscle != null ||
                          exercise.equipment != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (exercise.primaryMuscle != null)
                              Text(
                                exercise.primaryMuscle!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.primaryLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            if (exercise.primaryMuscle != null &&
                                exercise.equipment != null)
                              Text(
                                ' · ',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.35),
                                ),
                              ),
                            if (exercise.equipment != null)
                              Flexible(
                                child: Text(
                                  exercise.equipment!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.55),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Ícone de estado
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
