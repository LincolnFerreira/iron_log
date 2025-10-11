import 'package:flutter/material.dart';
import 'package:iron_log/features/routines/domain/entities/routine.dart';

import '../molecules/greeting_header.dart';
import '../molecules/todays_workout_card.dart';
import '../organisms/metrics_row.dart';
import '../organisms/workout_options_grid.dart';

class HomeTemplate extends StatelessWidget {
  final String userName;
  final VoidCallback onStartWorkout;
  final VoidCallback onChangeWorkout;
  final VoidCallback onQuickCreate;
  final VoidCallback? onRetryWorkout;
  final String? imageUrl;
  final Routine? todaysRoutine;
  final Session? todaysSession;
  final bool isLoadingWorkout;
  final String? error;

  const HomeTemplate({
    super.key,
    this.imageUrl,
    required this.userName,
    required this.onStartWorkout,
    required this.onChangeWorkout,
    required this.onQuickCreate,
    this.onRetryWorkout,
    this.todaysRoutine,
    this.todaysSession,
    this.isLoadingWorkout = false,
    this.error,
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
            todaysRoutine: todaysRoutine,
            todaysSession: todaysSession,
            isLoadingWorkout: isLoadingWorkout,
            error: error,
            onStartWorkout: onStartWorkout,
            onChangeWorkout: onChangeWorkout,
            onQuickCreate: onQuickCreate,
            onRetryWorkout: onRetryWorkout,
          ),
          TodaysWorkoutCard(
            todaysRoutine: todaysRoutine,
            todaysSession: todaysSession,
            isLoading: isLoadingWorkout,
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
