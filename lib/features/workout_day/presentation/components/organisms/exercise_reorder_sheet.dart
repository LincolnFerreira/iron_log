import 'package:flutter/material.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_exercise.dart';

class ExerciseReorderSheet {
  /// Shows the reorder sheet and returns the new ordered list on confirm,
  /// or null if the user cancelled.
  static Future<List<WorkoutExercise>?> show(
    BuildContext context,
    List<WorkoutExercise> initialExercises,
  ) {
    return showModalBottomSheet<List<WorkoutExercise>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ExerciseReorderContent(exercises: initialExercises);
      },
    );
  }
}

class _ExerciseReorderContent extends StatefulWidget {
  final List<WorkoutExercise> exercises;

  const _ExerciseReorderContent({required this.exercises});

  @override
  State<_ExerciseReorderContent> createState() =>
      _ExerciseReorderContentState();
}

class _ExerciseReorderContentState extends State<_ExerciseReorderContent> {
  late List<WorkoutExercise> _list;

  @override
  void initState() {
    super.initState();
    _list = List<WorkoutExercise>.from(widget.exercises);
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) newIndex -= 1;
      final item = _list.removeAt(oldIndex);
      _list.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.7;
    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Organizar exercícios',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _list.isEmpty
                          ? null
                          : () => Navigator.of(context).pop(_list),
                      child: const Text('Confirmar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _list.length,
              onReorder: _onReorder,
              itemBuilder: (context, index) {
                final ex = _list[index];
                return ListTile(
                  key: ValueKey(ex.id),
                  title: Text(ex.name, overflow: TextOverflow.ellipsis),
                  leading: CircleAvatar(
                    radius: 14,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  trailing: ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.drag_handle),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
