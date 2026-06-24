import 'package:drift/drift.dart';

@DataClassName('WorkoutImportDraftRow')
class WorkoutImportDrafts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get importId => text().nullable()();
  TextColumn get status => text()();
  TextColumn get rawText => text()();
  TextColumn get reviewSnapshotJson => text()();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get indices => [
        {userId, status},
      ];
}
