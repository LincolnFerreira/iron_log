import '../../domain/entities/routine.dart';
import 'package:flutter/material.dart';

class SelectedExerciseCard extends StatefulWidget {
  final SessionExercise exercise;
  final VoidCallback onDelete;

  const SelectedExerciseCard({
    super.key,
    required this.exercise,
    required this.onDelete,
  });

  @override
  State<SelectedExerciseCard> createState() => _SelectedExerciseCardState();
}

class _SelectedExerciseCardState extends State<SelectedExerciseCard> {
  final TextEditingController seriesController = TextEditingController(
    text: '3',
  );
  final TextEditingController repsController = TextEditingController(
    text: '10',
  );
  final TextEditingController weightController = TextEditingController(
    text: '0',
  );

  @override
  void dispose() {
    seriesController.dispose();
    repsController.dispose();
    weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com drag handle e título
              Row(
                children: [
                  // Drag handle
                  ReorderableDragStartListener(
                    index: 0, // Será definido pelo parent
                    child: Icon(
                      Icons.drag_indicator,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),

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
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: Colors.red.shade400,
                      size: 20,
                    ),
                    onPressed: widget.onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Músculos atingidos (se houver)
              if (widget.exercise.exercise.primaryMuscle != null ||
                  (widget.exercise.exercise.tags.isNotEmpty))
                Wrap(
                  spacing: 4,
                  children: [
                    if (widget.exercise.exercise.primaryMuscle != null)
                      _buildMuscleChip(widget.exercise.exercise.primaryMuscle!),
                    ...widget.exercise.exercise.tags
                        .take(2)
                        .map(_buildMuscleChip),
                  ],
                ),

              const SizedBox(height: 12),

              // Campos de input
              // Row(
              //   children: [
              //     // Séries
              //     Expanded(
              //       child: _buildInputField(
              //         controller: seriesController,
              //         label: 'Séries',
              //         hint: '3',
              //       ),
              //     ),
              //     const SizedBox(width: 8),

              //     // Reps
              //     Expanded(
              //       child: _buildInputField(
              //         controller: repsController,
              //         label: 'Reps',
              //         hint: '10',
              //       ),
              //     ),
              //     const SizedBox(width: 8),

              //     // Carga
              //     Expanded(
              //       child: _buildInputField(
              //         controller: weightController,
              //         label: 'Carga',
              //         hint: '0',
              //         suffix: 'kg',
              //       ),
              //     ),
              //   ],
              // ),
            ],
          ),
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 32,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
            decoration: InputDecoration(
              hintText: hint,
              suffixText: suffix,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
