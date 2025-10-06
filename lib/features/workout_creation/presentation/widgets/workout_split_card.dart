import 'package:flutter/material.dart';
import '../../domain/entities/workout_split.dart';

class WorkoutSplitCard extends StatelessWidget {
  final WorkoutSplit split;
  final VoidCallback? onMenuPressed;
  final bool isDragging;

  const WorkoutSplitCard({
    super.key,
    required this.split,
    this.onMenuPressed,
    this.isDragging = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        elevation: isDragging ? 8 : 2,
        color: isDragging
            ? theme.colorScheme.surface.withOpacity(0.9)
            : theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Drag handle - mais visível
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Icon(
                  Icons.drag_indicator,
                  color: theme.colorScheme.primary.withOpacity(0.7),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Split icon based on type
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getSplitColor(split.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getSplitIcon(split.type),
                  color: _getSplitColor(split.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Split info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      split.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${split.exerciseCount} exercícios',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: split.preferredDays.map((day) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getSplitColor(split.type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getSplitColor(
                                split.type,
                              ).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            day,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getSplitColor(split.type),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Menu button
              IconButton(
                onPressed: onMenuPressed,
                icon: const Icon(Icons.more_vert),
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSplitColor(String type) {
    switch (type.toLowerCase()) {
      case 'push':
        return Colors.orange;
      case 'pull':
        return Colors.blue;
      case 'legs':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getSplitIcon(String type) {
    switch (type.toLowerCase()) {
      case 'push':
        return Icons.fitness_center;
      case 'pull':
        return Icons.accessibility_new;
      case 'legs':
        return Icons.directions_run;
      default:
        return Icons.fitness_center;
    }
  }
}
