import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/database/app_database.dart';
import 'package:iron_log/core/services/http_service.dart';
import 'package:iron_log/core/sync/sync_manager.dart';
import 'package:iron_log/features/routines/data/datasources/routine_local_datasource.dart';
// ============ Drift Database Provider ============

final driftDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// ============ Connectivity Provider ============

final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

// ============ Sync Manager Provider ============

final syncManagerProvider = Provider<SyncManager>((ref) {
  final dio = ref.watch(httpServiceProvider);
  final database = ref.watch(driftDatabaseProvider);
  final connectivity = ref.watch(connectivityProvider);

  return SyncManager(
    dio: dio.dio,
    database: database,
    connectivity: connectivity,
  );
});

// ============ Routine Local DataSource Provider ============

final routineLocalDataSourceProvider = Provider<RoutineLocalDataSource>((ref) {
  final database = ref.watch(driftDatabaseProvider);
  return RoutineLocalDataSourceImpl(database: database);
});

// ============ Sync Status Stream Provider ============

final syncStatusStreamProvider = StreamProvider.autoDispose<SyncStatus>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  return syncManager.syncStatus;
});

// ============ Sync Conflicts Stream Provider ============

final syncConflictsStreamProvider = StreamProvider.autoDispose<SyncConflict>((
  ref,
) {
  final syncManager = ref.watch(syncManagerProvider);
  return syncManager.conflicts;
});

// ============ Sync State Provider (StateNotifier for current state) ============

class SyncStateNotifier extends StateNotifier<SyncStatus> {
  final SyncManager _syncManager;

  SyncStateNotifier(this._syncManager)
    : super(
        SyncStatus(isSyncing: false, lastSyncTime: null, pendingChanges: 0),
      ) {
    _initializeStream();
  }

  void _initializeStream() {
    _syncManager.syncStatus.listen((status) {
      state = status;
    });
  }

  Future<void> triggerSync() async {
    await _syncManager.sync();
  }
}

final syncStateProvider = StateNotifierProvider<SyncStateNotifier, SyncStatus>((
  ref,
) {
  final syncManager = ref.watch(syncManagerProvider);
  return SyncStateNotifier(syncManager);
});

// ============ Pending Changes Count Provider ============

final pendingChangesCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final database = ref.watch(driftDatabaseProvider);

  // Count pending routines from local database
  final pending = await (database.select(
    database.routines,
  )..where((r) => r.pendingSync.equals(true))).get();

  return pending.length;
});

// ============ Exports for main.dart overrides ============

final syncProvidersOverrides = [
  driftDatabaseProvider,
  connectivityProvider,
  syncManagerProvider,
  routineLocalDataSourceProvider,
];
