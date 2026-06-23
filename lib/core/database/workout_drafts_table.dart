import 'package:drift/drift.dart';

/// Rascunhos locais de treino (em andamento ou aguardando envio).
@DataClassName('WorkoutDraftRow')
class WorkoutDrafts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get status => text()();
  TextColumn get pendingOperation => text()();
  TextColumn get routineId => text().nullable()();
  TextColumn get sessionId => text().nullable()();
  TextColumn get serverWorkoutId => text().nullable()();
  TextColumn get snapshotJson => text()();
  TextColumn get apiPayloadJson => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  DateTimeColumn get manualDate => dateTime().nullable()();
  DateTimeColumn get timerStartedAt => dateTime().nullable()();
  IntColumn get accumulatedDurationSeconds => integer().nullable()();
  TextColumn get lastErrorType => text().nullable()();
  IntColumn get lastErrorStatusCode => integer().nullable()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get indices => [
        {userId, status},
        {userId, status, updatedAt},
      ];
}
