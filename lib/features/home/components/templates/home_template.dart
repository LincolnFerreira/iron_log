import 'package:flutter/material.dart';

import '../molecules/greeting_header.dart';
import '../molecules/last_workout_card.dart';
import '../organisms/metrics_row.dart';
import '../organisms/workout_options_grid.dart';

class HomeTemplate extends StatelessWidget {
  final String userName;
  final VoidCallback onStartWorkout;
  final VoidCallback onChangeWorkout;
  final VoidCallback onQuickCreate;
  final String? imageUrl;

  const HomeTemplate({
    super.key,
    this.imageUrl,
    required this.userName,
    required this.onStartWorkout,
    required this.onChangeWorkout,
    required this.onQuickCreate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Column(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          GreetingHeader(
            name: userName,
            date: 'Hoje • ${DateTime.now().day} de ${_getMonthName()}',
            imageUrl: imageUrl,
          ),
          WorkoutOptionsGrid(
            onStartWorkout: onStartWorkout,
            onChangeWorkout: onChangeWorkout,
            onQuickCreate: onQuickCreate,
          ),
          const LastWorkoutCard(
            workoutName: 'Treino B - Costas e Bíceps',
            date: 'Ontem',
            duration: '1h 15m',
            volume: '8.5t',
            exercises: '12',
            observation: 'Ótimo treino! Consegui aumentar carga no supino.',
          ),
          const MetricsRow(monthlyWorkouts: 28, currentStreak: 5),
        ],
      ),
    );
  }

  String _getMonthName() {
    const months = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    return months[DateTime.now().month - 1];
  }
}
