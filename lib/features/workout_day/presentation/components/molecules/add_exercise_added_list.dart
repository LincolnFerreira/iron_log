import 'package:flutter/material.dart';
import 'package:iron_log/core/extensions/string_extensions.dart';
import 'package:iron_log/features/routines/domain/entities/search_exercise.dart';

class AddExerciseAddedList extends StatelessWidget {
  final List<SearchExercise> addedExercises;

  const AddExerciseAddedList({super.key, required this.addedExercises});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Exercícios adicionados',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: addedExercises.length,
            itemBuilder: (context, index) {
              final exercise = addedExercises[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                            const SizedBox(height: 4),
                            Text(
                              exercise.primaryMuscle ?? 'Sem categoria',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
