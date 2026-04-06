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
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: widget.index,
              child: Icon(
                Icons.drag_indicator,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
                size: 18,
              ),
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
      ),
    );
  }
}
