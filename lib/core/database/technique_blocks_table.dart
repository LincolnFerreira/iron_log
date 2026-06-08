import 'package:drift/drift.dart';

class TechniqueBlocks extends Table {
  TextColumn get id => text()();
  TextColumn get sessionExerciseId => text()();
  TextColumn get workoutSessionId => text()();
  TextColumn get type => text()();
  IntColumn get order => integer()();
  TextColumn get label => text().nullable()();
  IntColumn get restBetweenMiniSets => integer().nullable()();

  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get indices => [
        {sessionExerciseId},
        {workoutSessionId},
        {pendingSync},
      ];
}
