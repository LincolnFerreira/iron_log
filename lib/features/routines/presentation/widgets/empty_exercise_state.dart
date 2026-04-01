import 'package:flutter/material.dart';
import 'package:iron_log/core/app_colors.dart';
import '../../domain/entities/search_exercise.dart';
import 'create_exercise_modal.dart';

class EmptyExerciseState extends StatelessWidget {
  final String query;
  final void Function(SearchExercise exercise)? onExerciseCreated;

  const EmptyExerciseState({
    super.key,
    required this.query,
    this.onExerciseCreated,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _openCreateModal(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Criar exercício'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCreateModal(BuildContext context) async {
    final created = await showModalBottomSheet<SearchExercise>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CreateExerciseModal(initialName: query),
    );

    if (created != null) {
      onExerciseCreated?.call(created);
    }
  }
}
