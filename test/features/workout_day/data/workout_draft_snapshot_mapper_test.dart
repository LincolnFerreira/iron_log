import 'package:flutter_test/flutter_test.dart';
import 'package:iron_log/features/workout_day/data/mappers/workout_draft_snapshot_mapper.dart';
import 'package:iron_log/features/workout_day/domain/entities/exercise_tag.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_exercise.dart';
import 'package:iron_log/features/workout_day/domain/enums/workout_screen_mode.dart';

void main() {
  test('DraftSnapshotV1 round-trip preserves exercises', () {
    final mapper = WorkoutDraftSnapshotMapper();
    final exercises = [
      const WorkoutExercise(
        id: 'ex1',
        name: 'Supino',
        tag: ExerciseTag.multi,
        muscles: 'Peito',
        variation: 'Traditional',
        series: 3,
        reps: '10',
        weight: '60',
        rir: 2,
        restTime: 90,
        entries: [],
      ),
    ];

    final snapshot = mapper.fromExecutionState(
      exercises: exercises,
      screenMode: WorkoutScreenMode.execution,
      workoutStarted: true,
      subtitle: 'Peito A',
      sessionId: 'sess-1',
    );

    final encoded = mapper.encode(snapshot);
    final decoded = mapper.decode(encoded);

    expect(decoded.exercises.length, 1);
    expect(decoded.exercises.first.name, 'Supino');
    expect(decoded.workoutStarted, isTrue);
    expect(decoded.subtitle, 'Peito A');
  });

  test('decode throws on corrupt JSON', () {
    final mapper = WorkoutDraftSnapshotMapper();
    expect(() => mapper.decode('not-json'), throwsA(isA<FormatException>()));
  });
}
