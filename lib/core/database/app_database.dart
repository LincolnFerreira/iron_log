import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'routines_table.dart';
import 'sessions_table.dart';
import 'session_exercises_table.dart';
import 'exercises_table.dart';
import 'workout_sessions_table.dart';
import 'serie_logs_table.dart';
import 'technique_blocks_table.dart';
import 'rest_days_table.dart';
import 'workout_outbox_table.dart';
import 'workout_drafts_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Routines,
    Sessions,
    SessionExercises,
    Exercises,
    WorkoutSessions,
    SerieLogs,
    TechniqueBlocks,
    RestDays,
    WorkoutOutbox,
    WorkoutDrafts,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(routines, routines.cachedRoutineJson);
          }
          if (from < 3) {
            await m.createTable(workoutOutbox);
          }
          if (from < 4) {
            await m.createTable(techniqueBlocks);
            await m.addColumn(serieLogs, serieLogs.techniqueBlockId);
            await m.addColumn(serieLogs, serieLogs.miniSetIndex);
            await m.addColumn(serieLogs, serieLogs.setType);
            await m.addColumn(serieLogs, serieLogs.isDerived);
          }
          if (from < 6) {
            await customStatement('DROP TABLE IF EXISTS api_error_logs');
          }
          if (from < 7) {
            await m.createTable(workoutDrafts);
            await customStatement('''
              INSERT INTO workout_drafts (
                id, user_id, status, pending_operation, snapshot_json,
                api_payload_json, started_at, created_at, updated_at
              )
              SELECT
                o.id,
                o.user_id,
                'pendingUpload',
                CASE
                  WHEN json_extract(o.payload_json, '\$.kind') = 'patch' THEN 'patch'
                  ELSE 'create'
                END,
                o.payload_json,
                json_extract(o.payload_json, '\$.payload'),
                COALESCE(o.created_at, datetime('now')),
                COALESCE(o.created_at, datetime('now')),
                COALESCE(o.created_at, datetime('now'))
              FROM workout_outbox o
              WHERE json_extract(o.payload_json, '\$.payload') IS NOT NULL
            ''');
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'iron_log_db',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationDocumentsDirectory,
      ),
    );
  }
}
