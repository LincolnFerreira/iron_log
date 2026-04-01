import '../../domain/entities/routine.dart';
import 'package:flutter/material.dart';

class SelectedExerciseCard extends StatefulWidget {
  final SessionExercise exercise;
  final VoidCallback onDelete;
  final int index;
  final int totalCount;

  const SelectedExerciseCard({
    super.key,
    required this.exercise,
    required this.onDelete,
    required this.index,
    required this.totalCount,
  });

  @override
  State<SelectedExerciseCard> createState() => _SelectedExerciseCardState();
}

class _SelectedExerciseCardState extends State<SelectedExerciseCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header com drag handle e título
            Row(
              children: [
                Icon(
                  Icons.drag_indicator,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                  size: 18,
                ),
                const SizedBox(width: 6),

                // Título do exercício
                Expanded(
                  child: Text(
                    widget.exercise.exercise.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Botão de deletar
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.red.shade400,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Músculos — linha de chips compacta
            if (widget.exercise.exercise.primaryMuscle != null ||
                widget.exercise.exercise.tags.isNotEmpty)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  if (widget.exercise.exercise.primaryMuscle != null)
                    _buildMuscleChip(widget.exercise.exercise.primaryMuscle!),
                  ...widget.exercise.exercise.tags
                      .take(1)
                      .map(_buildMuscleChip),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMuscleChip(String muscle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        muscle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w500,
          fontSize: 10,
        ),
      ),
    );
  }
}
