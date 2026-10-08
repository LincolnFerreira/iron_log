import 'package:drift/drift.dart';

class ExerciseStations extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get exerciseId => text()();
  TextColumn get gymId => text().nullable()();
  TextColumn get nickname => text()();
  TextColumn get nicknameKey => text()();
  TextColumn get brand => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get archivedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(true))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
