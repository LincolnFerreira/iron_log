import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/routines/presentation/pages/session_edit_page.dart';
import 'package:iron_log/features/routines/domain/entities/routine.dart';
import '../../helpers/test_providers_setup.dart';

void main() {
  testWidgets('SessionEditPage shows routine title and history', (
    tester,
  ) async {
    final routine = Routine(
      id: 'r1',
      userId: 'test-user',
      name: 'Minha Rotina',
      division: null,
      isTemplate: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      sessions: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: getTestProviderOverrides(),
        child: MaterialApp(home: SessionEditPage(routine: routine)),
      ),
    );

    // Title must contain routine name
    expect(find.text('Rotina ${routine.name}'), findsOneWidget);

    // Initially shows a CircularProgressIndicator from the FutureProvider
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Let the provider complete (provider mock has a small delay)
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // After data loads, history area should show either cards or the 'Nenhum histórico' text
    expect(find.text('Nenhum histórico disponível'), findsNothing);
  });
}
