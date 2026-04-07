import 'package:drift/drift.dart';

class RestDays extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get date => dateTime()(); // UTC midnight
  TextColumn get note => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  // Offline-first sync fields
  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {userId, date},
  ];

  @override
  List<Set<Column>> get indices => [
    {userId, date},
    {pendingSync},
  ];
}
