import 'package:flutter/material.dart';
import 'package:iron_log/core/app_colors.dart';
import 'package:iron_log/features/routines/domain/entities/search_exercise.dart';
import 'muscle_type_icon.dart';
import 'session_screen_styles.dart';

class SessionExerciseCard extends StatefulWidget {
  final SearchExercise exercise;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showAddedFeedback;
  final String? muscleGroup;

  const SessionExerciseCard({
    super.key,
    required this.exercise,
    required this.isSelected,
    required this.onTap,
    this.showAddedFeedback = true,
    this.muscleGroup,
  });

  @override
  State<SessionExerciseCard> createState() => _SessionExerciseCardState();
}

class _SessionExerciseCardState extends State<SessionExerciseCard> {
  bool _flashAdded = false;

  Future<void> _handleTap() async {
    final wasSelected = widget.isSelected;

    widget.onTap();

    if (!widget.showAddedFeedback || wasSelected) return;

    setState(() => _flashAdded = true);

    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _flashAdded = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle =
        widget.exercise.equipment ??
        widget.exercise.primaryMuscle ??
        widget.exercise.muscles.firstOrNull;
    final showAddedState = widget.isSelected || _flashAdded;

    return Padding(
      padding: const EdgeInsets.only(bottom: SessionScreenStyles.spacingSm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(SessionScreenStyles.cardRadius),
          child: Ink(
            decoration: SessionScreenStyles.cardDecoration(
              selected: widget.isSelected,
            ),
            padding: const EdgeInsets.all(SessionScreenStyles.spacingMd),
            child: Row(
              children: [
                MuscleTypeIcon(
                  exercise: widget.exercise,
                  muscleGroup: widget.muscleGroup,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.exercise.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 14,
                            color: SessionScreenStyles.metaColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: showAddedState
                        ? SessionScreenStyles.addedBackground
                        : SessionScreenStyles.addButtonBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    showAddedState ? Icons.check_rounded : Icons.add_rounded,
                    size: 20,
                    color: showAddedState
                        ? SessionScreenStyles.addedForeground
                        : AppColors.blue100,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
