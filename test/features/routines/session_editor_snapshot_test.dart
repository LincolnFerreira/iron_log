import 'package:flutter_test/flutter_test.dart';
import 'package:iron_log/features/routines/domain/entities/search_exercise.dart';
import 'package:iron_log/features/routines/presentation/providers/session_editor_state.dart';

void main() {
  group('SessionEditorSnapshot', () {
    test('detects exercise order change after reorder', () {
      const baseline = SessionEditorSnapshot(
        name: 'Upper 1',
        muscles: ['peito'],
        exerciseIds: ['a', 'b', 'c'],
      );

      final reordered = SessionEditorSnapshot.fromForm(
        name: 'Upper 1',
        musclesText: 'peito',
        exercises: const [
          SearchExercise(id: 'b', name: 'B'),
          SearchExercise(id: 'a', name: 'A'),
          SearchExercise(id: 'c', name: 'C'),
        ],
      );

      expect(reordered.hasChangesFrom(baseline), isTrue);
    });

    test('no changes when order and fields match baseline', () {
      const baseline = SessionEditorSnapshot(
        name: 'Upper 1',
        muscles: ['peito'],
        exerciseIds: ['a', 'b', 'c'],
      );

      final same = SessionEditorSnapshot.fromForm(
        name: 'Upper 1',
        musclesText: 'peito',
        exercises: const [
          SearchExercise(id: 'a', name: 'A'),
          SearchExercise(id: 'b', name: 'B'),
          SearchExercise(id: 'c', name: 'C'),
        ],
      );

      expect(same.hasChangesFrom(baseline), isFalse);
    });

    test('isValidToSave requires name and at least one exercise', () {
      expect(SessionEditorSnapshot.empty().isValidToSave(), isFalse);

      final valid = SessionEditorSnapshot.fromForm(
        name: 'Push',
        musclesText: '',
        exercises: const [SearchExercise(id: 'x', name: 'X')],
      );
      expect(valid.isValidToSave(), isTrue);
    });
  });
}
