import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iron_log/features/home/presentation/components/atoms/continue_workout_button.dart';

void main() {
  testWidgets('ContinueWorkoutButton shows CONTINUAR TREINO label', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ContinueWorkoutButton(
            sessionName: 'Peito A',
            exerciseCount: 4,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('CONTINUAR TREINO'), findsOneWidget);
    expect(find.textContaining('4 exercícios'), findsOneWidget);

    await tester.tap(find.byType(ContinueWorkoutButton));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('ContinueWorkoutButton disables tap while loading', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ContinueWorkoutButton(
            sessionName: 'Peito A',
            exerciseCount: 1,
            isLoading: true,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ContinueWorkoutButton));
    await tester.pump();

    expect(tapped, isFalse);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
