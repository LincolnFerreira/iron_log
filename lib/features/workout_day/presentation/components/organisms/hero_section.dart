import 'package:flutter/material.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_summary.dart';
import '../atoms/trophy_icon.dart';
import '../atoms/celebration_title.dart';
import '../atoms/contextual_subtitle.dart';

/// Seção hero no topo - celebração visual
class HeroSection extends StatelessWidget {
  final WorkoutSummary workoutSummary;

  const HeroSection({super.key, required this.workoutSummary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF4CAF50).withValues(alpha: 0.6),
              const Color(0xFFFFC107).withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(12),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          child: Column(
            children: [
              // Troféu com animação de bounce
              TrophyIcon(size: 80, animated: true),
              const SizedBox(height: 16),
              // Título de celebração
              CelebrationTitle(
                text: workoutSummary.celebrationMessage,
                animated: true,
              ),
              const SizedBox(height: 8),
              // Subtítulo contextual
              ContextualSubtitle(
                routineName: workoutSummary.sessionName,
                dateFormatted: workoutSummary.dateFormatted,
                animated: true,
              ),
              const SizedBox(height: 12),
              // Status da sessão
              Text(
                workoutSummary.subtitleMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
