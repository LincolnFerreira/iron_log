import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'exercise_search_field.dart';

class ExerciseResultCard extends ConsumerWidget {
  final Map<String, dynamic> exercise;
  final VoidCallback onSelect;

  const ExerciseResultCard({
    super.key,
    required this.exercise,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedIds = ref.watch(selectedExerciseIdsProvider);
    final id = exercise['id'] as String? ?? '';
    final isSelected = selectedIds.contains(id);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Ícone do exercício
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Informações do exercício
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome do exercício
                    Text(
                      exercise['name'] as String,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Músculo primário e equipamento
                    Row(
                      children: [
                        if (exercise['primaryMuscle'] != null)
                          Text(
                            exercise['primaryMuscle'] as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        if (exercise['primaryMuscle'] != null &&
                            exercise['equipment'] != null)
                          Text(
                            ' • ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.4,
                              ),
                            ),
                          ),
                        if (exercise['equipment'] != null)
                          Text(
                            exercise['equipment'] as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Tags
                    if ((exercise['tags'] as List?)?.isNotEmpty ?? false)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 4,
                          children: (exercise['tags'] as List)
                              .take(3)
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    tag as String,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.secondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),

              // Ícone de adicionar
              InkResponse(
                radius: 20,
                onTap: () {
                  // Tentar alternar seleção localmente (feedback visual)
                  final notifier = ref.read(
                    selectedExerciseIdsProvider.notifier,
                  );
                  final current = Set<String>.of(selectedIds);
                  if (isSelected) {
                    current.remove(id);
                  } else {
                    current.add(id);
                  }
                  notifier.state = current;
                  onSelect();
                },
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.add_circle_outline,
                  color: isSelected
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.primary,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
