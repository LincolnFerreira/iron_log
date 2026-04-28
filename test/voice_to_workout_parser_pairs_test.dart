import 'package:flutter_test/flutter_test.dart';
import 'package:iron_log/features/workout_day/data/parsers/voice_to_workout_parser.dart';

void main() {
  test('Fallback pairing extracts weights 20,40,60,80 and reps 15,10,6,5', () {
    final input =
        'supino reto comecei com 20 quilos fiz 15 repetições de aquecimento depois fui pra 40 fiz 10 depois 60 fiz 6 e finalizei com 80 fiz 5 senti um leve desconforto no ombro';

    final parsed = VoiceToWorkoutParser.parse(input);

    // Also inspect regex matches directly to debug tokenization
    final numRegex = RegExp(r'\d+(?:[.,]\d+)?');
    final numsDirect = numRegex
        .allMatches(input)
        .map((m) => m.group(0))
        .toList();
    print('DEBUG TEST: regex numsDirect=$numsDirect');

    expect(parsed, isNotEmpty);
    final ex = parsed.first;

    // Print to help debug during development
    print('DEBUG TEST: parsed name="${ex.name}"');
    print(
      'DEBUG TEST: weights=${ex.weights} reps=${ex.reps} notes=${ex.notes}',
    );

    expect(ex.weights, equals([20.0, 40.0, 60.0, 80.0]));
    expect(ex.reps, equals([15, 10, 6, 5]));
  });
}
