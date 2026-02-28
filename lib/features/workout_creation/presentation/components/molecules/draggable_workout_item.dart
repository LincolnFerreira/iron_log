import 'package:flutter/material.dart';
import '../../../domain/entities/workout_split.dart';
import '../../widgets/workout_split_card.dart';

class DraggableWorkoutItem extends StatelessWidget {
  final WorkoutSplit split;
  final int index;
  final VoidCallback onMenuPressed;

  const DraggableWorkoutItem({
    super.key,
    required this.split,
    required this.index,
    required this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableDragStartListener(
      index: index,
      key: ValueKey(split.id),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: WorkoutSplitCard(split: split, onMenuPressed: onMenuPressed),
      ),
    );
  }
}
