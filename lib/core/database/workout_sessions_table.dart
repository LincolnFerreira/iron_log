import 'package:drift/drift.dart';

class WorkoutSessions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get routineId => text().nullable()();
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get endedAt => dateTime().nullable()();
  BoolColumn get isManual => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  TextColumn get deviceId => text().nullable()();

  // Summary metrics
  RealColumn get totalVolume => real().nullable()();
  IntColumn get topSetsCount => integer().nullable()();
  RealColumn get avgRIR => real().nullable()();

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
    {userId, startedAt},
    {userId, pendingSync},
    {routineId},
  ];
}
