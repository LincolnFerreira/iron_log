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

  const WorkoutDayHeader({
    super.key,
    this.onBackPressed,
    this.onMorePressed,
    this.title = 'Exercícios do Dia',
    this.subtitle,
    this.manualDate,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                  'Treino de ${manualDate!.day.toString().padLeft(2, '0')}/${manualDate!.month.toString().padLeft(2, '0')}/${manualDate!.year}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ] else ...[
                  const WorkoutTimer(),
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
}
