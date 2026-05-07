import 'package:drift/drift.dart';

/// Fila de POST /workout a enviar quando a rede voltar (corpo idêntico ao [WorkoutLogService]).
class WorkoutOutbox extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get indices => [
        {userId},
      ];
}
