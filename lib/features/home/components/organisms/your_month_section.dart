import 'package:flutter/material.dart';
import '../atoms/metric_card.dart';

/// Your Month section displaying monthly metrics and progress towards monthly goal
class YourMonthSection extends StatelessWidget {
  final int workoutsCompleted; // e.g., 3
  final int monthlyGoal; // e.g., 20
  final int totalSeries; // Total series performed this month
  final int totalRoutines; // Number of routines created/available

  const YourMonthSection({
    super.key,
    required this.workoutsCompleted,
    required this.monthlyGoal,
    required this.totalSeries,
    required this.totalRoutines,
  });

  double _getProgressPercentage() {
    return (workoutsCompleted / monthlyGoal * 100).clamp(0, 100);
  }

  int _getRemainingWorkouts() {
    return (monthlyGoal - workoutsCompleted).clamp(0, monthlyGoal);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final progressPercentage = _getProgressPercentage();
    final remainingWorkouts = _getRemainingWorkouts();

    return Column(
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          'SEU MÊS',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        // Three metrics in a row
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: MetricCard(
                value: workoutsCompleted.toString(),
                label: 'Treinos',
              ),
            ),
            Expanded(
              child: MetricCard(
                value: totalSeries.toString(),
                label: 'Séries totais',
              ),
            ),
            Expanded(
              child: MetricCard(
                value: totalRoutines.toString(),
                label: 'Rotinas',
              ),
            ),
          ],
        ),
        // Monthly goal progress section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1D26), Color(0xFF12141A)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Color(0xFFF4F6FB)],
                  ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: .04)
                  : Colors.black.withValues(alpha: .04),
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: isDark ? 20 : 14,
                spreadRadius: -2,
                offset: const Offset(0, 10),
                color: isDark
                    ? Colors.black.withValues(alpha: .28)
                    : Colors.black.withValues(alpha: .06),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Goal header with icon box + texts
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primary.withValues(alpha: isDark ? .22 : .14),
                          primary.withValues(alpha: isDark ? .10 : .06),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      color: isDark
                          ? primary.withValues(alpha: .92)
                          : primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meta mensal',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          progressPercentage == 0
                              ? 'Seu progresso começa no primeiro treino'
                              : remainingWorkouts == 0
                                  ? 'Meta concluída neste mês'
                                  : 'Faltam $remainingWorkouts treinos para sua meta',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                            color: isDark
                                ? Colors.white.withValues(alpha: .62)
                                : Colors.black.withValues(alpha: .52),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progressPercentage / 100,
                  minHeight: 10,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: .06)
                      : Colors.black.withValues(alpha: .06),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    primary,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$workoutsCompleted/$monthlyGoal treinos',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${progressPercentage.toStringAsFixed(0)}%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                'Meta de ${monthlyGoal.toString()} treinos no mês',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? Colors.white.withValues(alpha: .62)
                      : Colors.black.withValues(alpha: .52),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
