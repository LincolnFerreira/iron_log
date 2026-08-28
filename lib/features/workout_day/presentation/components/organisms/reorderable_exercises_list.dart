import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_exercise.dart';
import 'package:iron_log/features/workout_day/presentation/components/molecules/add_exercise_button.dart';
import 'package:iron_log/features/workout_day/presentation/organisms/exercise_card.dart';
import 'package:iron_log/features/workout_day/presentation/providers/workout_day_provider.dart';

class ReorderableExercisesList extends ConsumerStatefulWidget {
  final List<WorkoutExercise> exercises;
  final Function(int oldIndex, int newIndex) onReorder;
  final String? sessionId;
  final VoidCallback? onAddExercise;
  final bool enableReorder;
  final bool showAddButton;

  const ReorderableExercisesList({
    super.key,
    required this.exercises,
    required this.onReorder,
    this.sessionId,
    this.onAddExercise,
    this.enableReorder = true,
    this.showAddButton = true,
  });

  @override
  ConsumerState<ReorderableExercisesList> createState() =>
      _ReorderableExercisesListState();
}

class _ReorderableExercisesListState
    extends ConsumerState<ReorderableExercisesList> {
  final Map<String, GlobalKey> _itemKeys = {};

  GlobalKey _keyFor(String exerciseId) =>
      _itemKeys.putIfAbsent(exerciseId, GlobalKey.new);

  void _scrollToExercise(String? exerciseId) {
    if (exerciseId == null || exerciseId.isEmpty) return;
    final ctx = _keyFor(exerciseId).currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<WorkoutFooterFocus>(workoutFooterFocusProvider, (prev, next) {
      if (next.exerciseId == null || next.exerciseId!.isEmpty) return;
      if (prev?.exerciseId == next.exerciseId) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollToExercise(next.exerciseId);
      });
    });

    // Remove keys de exercícios que saíram da lista.
    final ids = widget.exercises.map((e) => e.id).toSet();
    _itemKeys.removeWhere((id, _) => !ids.contains(id));

    if (!widget.enableReorder) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.exercises.length,
        itemBuilder: (context, index) {
          final exercise = widget.exercises[index];
          return Container(
            key: ValueKey(exercise.id),
            margin: const EdgeInsets.only(bottom: 16),
            child: KeyedSubtree(
              key: _keyFor(exercise.id),
              child: ExerciseCard(
                exercise: exercise,
                sessionId: widget.sessionId,
              ),
            ),
          );
        },
      );
    }

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      onReorder: (oldIndex, newIndex) {
        if (oldIndex >= widget.exercises.length) return;

        var targetIndex = newIndex;
        if (targetIndex > widget.exercises.length) {
          targetIndex = widget.exercises.length;
        }
        if (targetIndex > oldIndex) targetIndex -= 1;
        if (targetIndex == oldIndex) return;

        widget.onReorder(oldIndex, targetIndex);
      },
      itemCount:
          widget.exercises.length + (widget.showAddButton ? 1 : 0),
      itemBuilder: (context, index) {
        if (widget.showAddButton && index == widget.exercises.length) {
          return Padding(
            key: const ValueKey('add_exercise_button'),
            padding: const EdgeInsets.only(bottom: 16),
            child: AddExerciseButton(
              onPressed:
                  widget.onAddExercise ??
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Use a barra de busca para adicionar exercícios',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
            ),
          );
        }

        final exercise = widget.exercises[index];
        return Container(
          key: ValueKey(exercise.id),
          margin: const EdgeInsets.only(bottom: 16),
          child: KeyedSubtree(
            key: _keyFor(exercise.id),
            child: ExerciseCard(
              exercise: exercise,
              index: index,
              sessionId: widget.sessionId,
            ),
          ),
        );
      },
    );
  }
}
