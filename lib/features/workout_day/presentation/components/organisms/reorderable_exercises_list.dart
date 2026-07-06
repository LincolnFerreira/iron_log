import 'package:flutter/material.dart';
import '../../organisms/exercise_card.dart';
import '../../../domain/entities/workout_exercise.dart';
import '../molecules/add_exercise_button.dart';

class ReorderableExercisesList extends StatelessWidget {
  final List<WorkoutExercise> exercises;
  final Function(int oldIndex, int newIndex) onReorder;
  final String? sessionId; // Adicionar sessionId para habilitar remoção
  final VoidCallback? onAddExercise;
  final bool enableReorder;
  final bool showAddButton;

  const ReorderableExercisesList({
    super.key,
    required this.exercises,
    required this.onReorder,
    this.sessionId, // Parâmetro opcional
    this.onAddExercise,
    this.enableReorder = true,
    this.showAddButton = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enableReorder) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          return Container(
            key: ValueKey(exercise.id),
            margin: const EdgeInsets.only(bottom: 16),
            child: ExerciseCard(
              exercise: exercise,
              sessionId: sessionId,
            ),
          );
        },
      );
    }

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      onReorder: (oldIndex, newIndex) {
        // Guard: ignore reorder starting from the add-button slot
        if (oldIndex >= exercises.length) return;

        // The ReorderableListView's newIndex is the index in the full
        // list (including the add-button). Convert it to a target index
        // for the underlying `exercises` list and clamp to valid bounds.
        var targetIndex = newIndex;

        // Cap to the add-button index (safe upper bound)
        if (targetIndex > exercises.length) targetIndex = exercises.length;

        // If the item is moved forward in the list, the removal of the
        // original element shifts indices down by one.
        if (targetIndex > oldIndex) targetIndex -= 1;

        // If there's no effective change, ignore.
        if (targetIndex == oldIndex) return;

        onReorder(oldIndex, targetIndex);
      },
      itemCount: exercises.length + (showAddButton ? 1 : 0), // +1 para o botão
      itemBuilder: (context, index) {
        // Último item é o botão de adicionar
        if (showAddButton && index == exercises.length) {
          return Padding(
            key: const ValueKey('add_exercise_button'),
            padding: const EdgeInsets.only(bottom: 16),
            child: AddExerciseButton(
              onPressed:
                  onAddExercise ??
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Use a barra de busca para adicionar exercícios',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
            ),
          );
        }

        final exercise = exercises[index];
        return Container(
          key: ValueKey(exercise.id),
          margin: const EdgeInsets.only(bottom: 16),
          child: ExerciseCard(
            exercise: exercise,
            index: index,
            sessionId: sessionId, // Passa o sessionId para habilitar remoção
          ),
        );
      },
    );
  }
}
