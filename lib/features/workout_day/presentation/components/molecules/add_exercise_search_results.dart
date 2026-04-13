import 'package:flutter/material.dart';
import 'package:iron_log/core/extensions/string_extensions.dart';
import 'package:iron_log/features/routines/domain/entities/search_exercise.dart';

class AddExerciseSearchResults extends StatelessWidget {
  final List<SearchExercise> results;
  final List<SearchExercise> addedExercises;
  final Function(SearchExercise) onExerciseSelected;

  const AddExerciseSearchResults({
    super.key,
    required this.results,
    required this.addedExercises,
    required this.onExerciseSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final exercise = results[index];
        final isAdded = addedExercises.any((e) => e.id == exercise.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: isAdded ? Colors.green.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => onExerciseSelected(exercise),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isAdded
                        ? Colors.green.shade200
                        : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.fitness_center, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name.toTitleCase(),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (exercise.primaryMuscle != null)
                            Text(
                              exercise.primaryMuscle!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey.shade600),
                            ),
                        ],
                      ),
                    ),
                    if (isAdded)
                      const Icon(Icons.check_circle, color: Colors.green)
                    else
                      Icon(
                        Icons.add_circle_outline,
                        color: Colors.grey.shade400,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
