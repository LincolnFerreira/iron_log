import 'package:flutter/material.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_summary.dart';
import '../molecules/exercise_detail_block.dart';

/// Seção de detalhamento de exercícios
class ExerciseBreakdownSection extends StatelessWidget {
  final WorkoutSummary workoutSummary;

  const ExerciseBreakdownSection({super.key, required this.workoutSummary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho de seção
          Text(
            'DETALHES DO TREINO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          // Lista de exercícios
          ...workoutSummary.exercises.asMap().entries.map((entry) {
            final index = entry.key;
            final exercise = entry.value;
            return Column(
              children: [
                ExerciseDetailBlock(
                  exercise: exercise,
                  animated: true,
                  staggerIndex: index,
                ),
                if (index < workoutSummary.exercises.length - 1)
                  const SizedBox(height: 16),
              ],
            );
          }),
        ],
      ),
    );
  }
}
