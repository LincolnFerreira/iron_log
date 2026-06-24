import 'package:flutter_test/flutter_test.dart';
import 'package:iron_log/features/workout_import/domain/entities/effort_type.dart';
import 'package:iron_log/features/workout_import/domain/entities/parsed_workout_import.dart';

void main() {
  test('ParsedWorkoutImport roundtrip json', () {
    const original = ParsedWorkoutImport(
      sessions: [
        ParsedImportSession(
          clientKey: 's0',
          title: 'Upper 1',
          exercises: [
            ParsedImportExercise(
              clientKey: 'e0',
              name: 'Supino',
              sets: [
                ParsedImportSet(
                  clientKey: 'set0',
                  weight: 40,
                  reps: 10,
                  effortType: EffortType.work,
                ),
              ],
            ),
          ],
        ),
      ],
      unmappedFragments: ['nota solta'],
    );

    final decoded = ParsedWorkoutImport.fromJson(original.toJson());
    expect(decoded.sessions.length, 1);
    expect(decoded.sessions.first.exercises.first.name, 'Supino');
    expect(decoded.unmappedFragments, ['nota solta']);
  });
}
