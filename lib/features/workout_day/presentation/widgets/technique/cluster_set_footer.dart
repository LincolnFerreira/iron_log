import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:iron_log/features/workout_day/presentation/exercise_card_styles.dart';
import 'package:iron_log/features/workout_day/presentation/workout_test_keys.dart';

/// Progress bar and full-width remove button for cluster blocks.
class ClusterSetFooter extends StatelessWidget {
  final int doneCount;
  final int totalCount;
  final VoidCallback? onRemove;

  const ClusterSetFooter({
    super.key,
    required this.doneCount,
    required this.totalCount,
    this.onRemove,
  });

  static int progressPercent(int doneCount, int totalCount) {
    if (totalCount <= 0) return 0;
    return ((doneCount / totalCount) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final fraction = totalCount <= 0 ? 0.0 : doneCount / totalCount;
    final percent = progressPercent(doneCount, totalCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 8,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: ExerciseCardStyles.clusterProgressTrackDecoration(),
                ),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fraction.clamp(0.0, 1.0),
                  child: DecoratedBox(
                    decoration:
                        ExerciseCardStyles.clusterProgressFillDecoration(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$percent% concluído',
          style: ExerciseCardStyles.seriesLabelStyle.copyWith(
            color: ExerciseCardStyles.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: WorkoutTestKeys.removeCluster,
          onPressed: onRemove == null
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onRemove!();
                },
          style: ExerciseCardStyles.clusterRemoveButtonStyle(),
          child: const Text('Remover cluster'),
        ),
      ],
    );
  }
}
