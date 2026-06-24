import 'package:flutter/material.dart';

import '../../domain/entities/effort_type.dart';
import '../../domain/entities/parsed_workout_import.dart';

class ImportExerciseTile extends StatelessWidget {
  const ImportExerciseTile({
    super.key,
    required this.exercise,
    required this.setRows,
    this.onNameChanged,
    this.onPickExercise,
    this.onRemove,
  });

  final ParsedImportExercise exercise;
  final List<Widget> setRows;
  final ValueChanged<String>? onNameChanged;
  final VoidCallback? onPickExercise;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: exercise.name,
                  decoration: InputDecoration(
                    labelText: 'Exercício',
                    suffixIcon: exercise.nameConfidence != ConfidenceLevel.high
                        ? const Icon(Icons.help_outline, size: 18)
                        : null,
                  ),
                  onChanged: onNameChanged,
                ),
              ),
              if (onPickExercise != null)
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Catálogo',
                  onPressed: onPickExercise,
                ),
              if (onRemove != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onRemove,
                ),
            ],
          ),
          if (exercise.notes != null && exercise.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                exercise.notes!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ...setRows,
        ],
      ),
    );
  }
}
