import 'package:flutter_test/flutter_test.dart';
import 'package:iron_log/features/workout_day/data/parsers/voice_to_workout_parser.dart';

void main() {
  test('Parses supino example', () {
    final input =
        'Supino reto fiz 20kg 15 repetições, depois 40 10, 60 4, senti dor no ombro';
    final parsed = VoiceToWorkoutParser.parse(input);

    expect(parsed, isNotEmpty);
    final ex = parsed.first;
    expect(ex.name.toLowerCase(), contains('supino'));
    expect(ex.weights, equals([20.0, 40.0, 60.0]));
    expect(ex.reps, equals([15, 10, 4]));
    expect(ex.notes, contains('senti dor'));
  });
}
