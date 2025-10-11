import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'exercise_search_field.dart';
import 'exercise_search_results.dart';

class ExerciseSearchSection extends ConsumerWidget {
  const ExerciseSearchSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Buscar Exercícios',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Campo de busca
          const ExerciseSearchField(),

          const SizedBox(height: 16),

          // Resultados da busca
          const Expanded(child: ExerciseSearchResults()),
        ],
      ),
    );
  }
}
