import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/routines/domain/entities/routine.dart';
import 'package:iron_log/features/routines/domain/entities/routine_update.dart';
import 'package:iron_log/features/routines/domain/entities/session_creation.dart';
import 'package:iron_log/features/routines/domain/repositories/routine_repository.dart';
import 'package:iron_log/features/routines/presentation/pages/routine_sessions_page.dart';
import 'package:iron_log/features/routines/presentation/providers/routine_last_workout_provider.dart';
import 'package:iron_log/features/routines/presentation/providers/routine_provider.dart';

class _TestRoutineRepository implements RoutineRepository {
  _TestRoutineRepository(this.routine);

  final Routine routine;

  @override
  Future<Routine> getRoutine(String id) async => routine;

  @override
  Future<List<Routine>> getRoutines() async => [routine];

  @override
  Future<Routine> createRoutine({
    required String name,
    String? division,
    bool isTemplate = false,
    List<SessionCreation>? sessions,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> deleteRoutine(String id) => throw UnimplementedError();

  @override
  Future<Routine> updateRoutine(String id, RoutineUpdate updates) =>
      throw UnimplementedError();
}

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
        overrides: [
          routineRepositoryProvider.overrideWithValue(
            _TestRoutineRepository(routine),
          ),
          routineLastWorkoutProvider.overrideWith(
            (ref, routineId) async => null,
          ),
        ],
        child: MaterialApp(home: RoutineSessionsPage(routine: routine)),
      ),
    );

    expect(find.text('SESSÕES'), findsOneWidget);
    expect(find.text('MINHA ROTINA'), findsOneWidget);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Nenhum treino registrado ainda'), findsOneWidget);
  });
}
