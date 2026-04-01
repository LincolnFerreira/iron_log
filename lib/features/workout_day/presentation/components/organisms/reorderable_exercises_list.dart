import 'package:flutter/material.dart';
import '../../organisms/exercise_card.dart';
import '../../../domain/entities/workout_exercise.dart';
import '../molecules/add_exercise_button.dart';

class ReorderableExercisesList extends StatelessWidget {
  final List<WorkoutExercise> exercises;
  final Function(int oldIndex, int newIndex) onReorder;
  final String? sessionId; // Adicionar sessionId para habilitar remoção
  final VoidCallback? onAddExercise;

  const ReorderableExercisesList({
    super.key,
    required this.exercises,
    required this.onReorder,
    this.sessionId, // Parâmetro opcional
    this.onAddExercise,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      onReorder: onReorder,
      itemCount: exercises.length + 1, // +1 para o botão
      itemBuilder: (context, index) {
        // Último item é o botão de adicionar
        if (index == exercises.length) {
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
