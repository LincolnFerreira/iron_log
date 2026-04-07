import 'package:drift/drift.dart';

class SessionExercises extends Table {
  TextColumn get sessionId => text()();
  TextColumn get exerciseId => text()();
  TextColumn get customName => text().nullable()();
  IntColumn get order => integer()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get config => text()(); // JSON config stored as text

  TextColumn get presetId => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  // Offline-first sync fields
  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {sessionId, exerciseId};

  @override
  List<Set<Column>> get indices => [
    {sessionId},
    {exerciseId},
    {pendingSync},
  ];
}
