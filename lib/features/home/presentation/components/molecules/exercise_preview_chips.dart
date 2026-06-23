import 'package:flutter/material.dart';
import 'package:iron_log/core/app_colors.dart';
import 'package:iron_log/features/routines/domain/entities/routine.dart';

/// Displays a single-line preview of exercises for today's session as chips.
/// If not all chips fit, shows a second-line text "+N mais" indicating remaining.
class ExercisePreviewChips extends StatelessWidget {
  final List<SessionExercise> exercises;
  final VoidCallback? onViewAllTap;

  const ExercisePreviewChips({
    super.key,
    required this.exercises,
    this.onViewAllTap,
  });

  double _measureTextWidth(String text, TextStyle style, double textScale) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaleFactor: textScale,
    )..layout();
    return tp.width;
  }

  Widget _buildChip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.blue10,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primaryDarkShade800,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final textStyle =
            Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primaryDarkShade800,
              fontWeight: FontWeight.w500,
            ) ??
            const TextStyle();
        final textScale = MediaQuery.textScaleFactorOf(context);

        const double circleWidth = 8.0;
        const double innerSpacing = 6.0; // between circle and text
        const double horizontalPadding = 12.0; // left+right per chip
        const double chipSpacing = 8.0; // space between chips

        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;

        // compute widths for each chip label
        final labels = exercises.map((e) => e.exercise.name).toList();
        final widths = <double>[];
        for (final label in labels) {
          final textW = _measureTextWidth(label, textStyle, textScale);
          final chipW =
              textW + circleWidth + innerSpacing + horizontalPadding * 2;
          widths.add(chipW);
        }

        // count how many chips fit in a single line
        double used = 0.0;
        int fitCount = 0;
        for (int i = 0; i < widths.length; i++) {
          final w = widths[i];
          final additional = (fitCount == 0) ? w : (chipSpacing + w);
          if (used + additional <= maxWidth) {
            used += additional;
            fitCount++;
          } else {
            break;
          }
        }

        // ensure at least one chip is shown
        if (fitCount == 0 && labels.isNotEmpty) fitCount = 1;

        final remaining = labels.length - fitCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (int i = 0; i < fitCount; i++) ...[
                  _buildChip(context, labels[i]),
                  if (i < fitCount - 1) const SizedBox(width: chipSpacing),
                ],
              ],
            ),
            if (remaining > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: GestureDetector(
                  onTap: onViewAllTap,
                  child: Text(
                    '+$remaining mais',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
