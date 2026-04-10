import 'package:drift/drift.dart';

class SerieLogs extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()();
  TextColumn get sessionExerciseSessionId => text().nullable()();
  TextColumn get sessionExerciseExerciseId => text().nullable()();
  TextColumn get exerciseId => text().nullable()();

  IntColumn get setIndex => integer()();
  TextColumn get label =>
      text().nullable()(); // Warm-up / Top Set / Back-Off / AMRAP
  IntColumn get reps => integer().nullable()();
  RealColumn get weight => real().nullable()();
  TextColumn get weightUnit =>
      text().withDefault(const Constant('kg'))(); // 'kg' or 'lbs'
  IntColumn get rir => integer().nullable()();
  TextColumn get rirNote => text().nullable()();
  IntColumn get restTime => integer().nullable()();
  TextColumn get cadence => text().nullable()(); // "2-0-2"
  BoolColumn get isFailure => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  // Offline-first sync fields
  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get indices => [
    {sessionId},
    {exerciseId},
    {sessionExerciseSessionId, sessionExerciseExerciseId},
    {pendingSync},
  ];
}
