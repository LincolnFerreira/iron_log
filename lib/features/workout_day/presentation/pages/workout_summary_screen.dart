import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_summary.dart';
import 'package:iron_log/features/workout_day/presentation/components/organisms/exercise_breakdown_section.dart';
import 'package:iron_log/features/workout_day/presentation/components/organisms/hero_section.dart';
import 'package:iron_log/features/workout_day/presentation/components/organisms/history_section.dart';
import 'package:iron_log/features/workout_day/presentation/components/organisms/stats_grid.dart';

class WorkoutSummaryScreen extends ConsumerWidget {
  final WorkoutSummary workoutSummary;

  const WorkoutSummaryScreen({super.key, required this.workoutSummary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Título no topo
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Text(
                  'Treino Concluído',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            // Hero Section (no topo, sem scroll)
            SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: AlwaysStoppedAnimation(1.0),
                builder: (context, child) {
                  return HeroSection(workoutSummary: workoutSummary);
                },
              ),
            ),
            SliverToBoxAdapter(child: const SizedBox(height: 8)),
            // Stats Grid
            SliverToBoxAdapter(
              child: StatsGrid(workoutSummary: workoutSummary),
            ),
            SliverToBoxAdapter(child: const SizedBox(height: 20)),
            // Exercise Breakdown Section
            SliverToBoxAdapter(
              child: ExerciseBreakdownSection(workoutSummary: workoutSummary),
            ),
            SliverToBoxAdapter(child: const SizedBox(height: 20)),
            // History Section
            SliverToBoxAdapter(
              child: HistorySection(workoutSummary: workoutSummary),
            ),
            SliverToBoxAdapter(child: const SizedBox(height: 40)),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF4CAF50),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        child: Material(
          color: const Color(0xFF4CAF50),
          child: InkWell(
            onTap: () {
              // Pop da summary screen
              Navigator.of(context).pop();
              // Pop da workout day screen
              Navigator.of(context).pop();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 26),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Voltar ao Início',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
