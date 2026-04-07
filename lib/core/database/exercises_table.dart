import 'package:drift/drift.dart';

class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get primaryMuscleId => text().nullable()();
  TextColumn get equipmentId => text().nullable()();
  TextColumn get tags =>
      text().withDefault(const Constant('[]'))(); // JSON array as text

  // Additional fields
  TextColumn get force => text().nullable()();
  TextColumn get level => text().nullable()();
  TextColumn get mechanic => text().nullable()();
  TextColumn get instructions => text().nullable()(); // JSON array
  TextColumn get category => text().nullable()();
  TextColumn get images => text().nullable()(); // JSON array
  TextColumn get secondaryMuscles => text().nullable()(); // JSON array

  TextColumn get defaultConfig => text().nullable()(); // JSON
  IntColumn get useCount => integer().withDefault(const Constant(0))();

  TextColumn get source =>
      text().withDefault(const Constant('system'))(); // 'system' | 'user'
  TextColumn get status => text().withDefault(
    const Constant('active'),
  )(); // 'active' | 'merged' | 'deprecated'
  TextColumn get canonicalExerciseId => text().nullable()();

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
    {source},
    {status},
    {pendingSync},
  ];
}
