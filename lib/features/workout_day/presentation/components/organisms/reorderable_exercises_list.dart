import 'package:flutter/material.dart';
import '../../organisms/exercise_card.dart';
import '../../../domain/entities/workout_exercise.dart';

class ReorderableExercisesList extends StatelessWidget {
  final List<WorkoutExercise> exercises;
  final Function(int oldIndex, int newIndex) onReorder;
  final String? sessionId; // Adicionar sessionId para habilitar remoção

  const ReorderableExercisesList({
    super.key,
    required this.exercises,
    required this.onReorder,
    this.sessionId, // Parâmetro opcional
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      onReorder: onReorder,
      itemCount: exercises.length,
      itemBuilder: (context, index) {
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
