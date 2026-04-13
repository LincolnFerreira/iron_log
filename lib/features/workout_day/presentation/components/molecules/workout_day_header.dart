import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'workout_timer.dart';

class WorkoutDayHeader extends ConsumerWidget {
  final VoidCallback? onBackPressed;
  final VoidCallback? onMorePressed;
  final String title;
  final String? subtitle;

  /// Quando não nulo, exibe badge de "treino passado" e omite o timer.
  final DateTime? manualDate;

  /// Quando não nulo e manualDate != null, torna o badge de data clicável.
  final VoidCallback? onDateTap;

  /// Duração existente do treino (modo edição). Quando presente, exibe badge
  /// de duração abaixo da data.
  final Duration? existingDuration;

  const WorkoutDayHeader({
    super.key,
    this.onBackPressed,
    this.onMorePressed,
    this.title = 'Exercícios do Dia',
    this.subtitle,
    this.manualDate,
    this.onDateTap,
    this.existingDuration,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                if (manualDate != null) ...[
                  GestureDetector(
                    onTap: onDateTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Treino de ${manualDate!.day.toString().padLeft(2, '0')}/${manualDate!.month.toString().padLeft(2, '0')}/${manualDate!.year}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onTertiaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          if (onDateTap != null) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit_calendar_outlined,
                              size: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onTertiaryContainer,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  const WorkoutTimer(),
                ],
                if (existingDuration != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(existingDuration!),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onMorePressed ?? () {},
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}min';
    if (hours > 0) return '${hours}h';
    return '${minutes}min';
  }
}
