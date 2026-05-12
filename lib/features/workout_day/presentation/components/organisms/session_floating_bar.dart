import 'package:flutter/material.dart';
import 'package:iron_log/core/app_colors.dart';
import 'package:iron_log/core/extensions/string_extensions.dart';
import '../../../domain/entities/workout_exercise.dart';

class SessionFloatingBar extends StatelessWidget {
  final List<WorkoutExercise> exercises;
  final VoidCallback onClear;
  final VoidCallback onViewSession;
  final bool workoutStarted;

  const SessionFloatingBar({
    super.key,
    required this.exercises,
    required this.onClear,
    required this.onViewSession,
    this.workoutStarted = false,
  });

  WorkoutExercise? get _nextExercise =>
      exercises.isNotEmpty ? exercises.first : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final count = exercises.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.dark30 : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.5 : 0.1),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, -1),
          ),
        ],
        border: Border.all(
          color: isDark ? AppColors.dark40 : Colors.grey.shade100,
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onViewSession,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
            child: Row(
              children: [
                // Next exercise preview
                _buildLeadingIcon(theme, isDark),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_nextExercise != null)
                        Text(
                          _nextExercise!.name.toTitleCase(),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          'Sua sessão',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      const SizedBox(height: 1),
                      Row(
                        children: [
                          Text(
                            '$count exercício${count != 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.gray50
                                  : AppColors.gray60,
                            ),
                          ),
                          _dot(isDark),
                          _buildAvatarStack(context, isDark),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // CTA
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: workoutStarted
                        ? AppColors.success
                        : theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        workoutStarted
                            ? Icons.visibility
                            : Icons.play_arrow_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        workoutStarted ? 'Ver' : 'Treinar',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(ThemeData theme, bool isDark) {
    if (_nextExercise == null) {
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark ? AppColors.dark40 : AppColors.gray10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.fitness_center,
          size: 18,
          color: isDark ? AppColors.gray50 : AppColors.gray60,
        ),
      );
    }

    final tagColor = _nextExercise!.tag.color;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: tagColor.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tagColor.withOpacity(0.2),
        ),
      ),
      child: Center(
        child: Text(
          _nextExercise!.name.isNotEmpty
              ? _nextExercise!.name[0].toUpperCase()
              : '?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: tagColor,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarStack(BuildContext context, bool isDark) {
    final preview = exercises.skip(1).take(3).toList();
    if (preview.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < preview.length; i++)
          Transform.translate(
            offset: Offset(-4.0 * i, 0),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: preview[i].tag.color.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.dark30 : Colors.white,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  preview[i].name.isNotEmpty
                      ? preview[i].name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: preview[i].tag.color,
                  ),
                ),
              ),
            ),
          ),
        if (exercises.length > 4)
          Transform.translate(
            offset: Offset(-4.0 * preview.length, 0),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isDark ? AppColors.dark40 : Colors.grey.shade200,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.dark30 : Colors.white,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  '+${exercises.length - 4}',
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.gray50 : AppColors.gray60,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _dot(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(
          color: isDark ? AppColors.gray50 : AppColors.gray40,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
