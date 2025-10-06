import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/workout_split.dart';
import '../state/workout_creation_provider.dart';
import 'workout_split_card.dart';
import 'molecules/add_workout_card.dart';
import 'organisms/add_workout_bottom_sheet.dart';

class ReorderableWorkoutList extends ConsumerWidget {
  const ReorderableWorkoutList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutState = ref.watch(workoutCreationProvider);
    final workoutNotifier = ref.read(workoutCreationProvider.notifier);

    if (workoutState.workoutSplits.isEmpty) {
      return _buildEmptyStateWithAddCard(context, ref);
    }

    return Column(
      children: [
        // Reorderable list of workout splits
        Expanded(
          child: ReorderableListView(
            buildDefaultDragHandles:
                false, // Permite arrastar de qualquer lugar
            onReorder: (oldIndex, newIndex) {
              workoutNotifier.reorderSplits(oldIndex, newIndex);
            },
            children: workoutState.workoutSplits.asMap().entries.map((entry) {
              final index = entry.key;
              final split = entry.value;
              return _buildDraggableItem(context, split, ref, index);
            }).toList(),
          ),
        ),

        // Add workout card at the bottom
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: AddWorkoutCard(
            onTap: () => _showAddWorkoutBottomSheet(context),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStateWithAddCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fitness_center, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Nenhum treino criado',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Adicione treinos para criar sua rotação',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Add workout card at the bottom even when empty
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: AddWorkoutCard(
            onTap: () => _showAddWorkoutBottomSheet(context),
          ),
        ),
      ],
    );
  }

  Widget _buildDraggableItem(
    BuildContext context,
    WorkoutSplit split,
    WidgetRef ref,
    int index,
  ) {
    return ReorderableDragStartListener(
      index: index,
      key: ValueKey(split.id),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: WorkoutSplitCard(
          split: split,
          onMenuPressed: () => _showSplitMenu(context, split, ref),
        ),
      ),
    );
  }

  void _showSplitMenu(BuildContext context, WorkoutSplit split, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              split.name,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildMenuOption(
              context,
              icon: Icons.edit,
              title: 'Editar',
              onTap: () {
                Navigator.pop(context);
                _editSplit(context, split, ref);
              },
            ),
            _buildMenuOption(
              context,
              icon: Icons.copy,
              title: 'Duplicar',
              onTap: () {
                Navigator.pop(context);
                _duplicateSplit(split, ref);
              },
            ),
            _buildMenuOption(
              context,
              icon: Icons.delete,
              title: 'Excluir',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _deleteSplit(context, split, ref);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.textTheme.bodyLarge?.color;

    return ListTile(
      leading: Icon(icon, color: effectiveColor),
      title: Text(title, style: TextStyle(color: effectiveColor)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  void _editSplit(BuildContext context, WorkoutSplit split, WidgetRef ref) {
    // TODO: Implement edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de edição em breve')),
    );
  }

  void _duplicateSplit(WorkoutSplit split, WidgetRef ref) {
    final workoutNotifier = ref.read(workoutCreationProvider.notifier);
    final newSplit = split.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${split.name} (Cópia)',
    );
    workoutNotifier.addSplit(newSplit);
  }

  void _deleteSplit(BuildContext context, WorkoutSplit split, WidgetRef ref) {
    final workoutNotifier = ref.read(workoutCreationProvider.notifier);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text(
          'Tem certeza que deseja excluir o treino "${split.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              workoutNotifier.removeSplit(split.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('${split.name} excluído')));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showAddWorkoutBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddWorkoutBottomSheet(),
    );
  }
}
