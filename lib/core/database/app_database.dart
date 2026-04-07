import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'routines_table.dart';
import 'sessions_table.dart';
import 'session_exercises_table.dart';
import 'exercises_table.dart';
import 'workout_sessions_table.dart';
import 'serie_logs_table.dart';
import 'rest_days_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Routines,
    Sessions,
    SessionExercises,
    Exercises,
    WorkoutSessions,
    SerieLogs,
    RestDays,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'iron_log_db',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationDocumentsDirectory,
      ),
    );
  }
}
