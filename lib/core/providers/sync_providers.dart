import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:iron_log/core/database/app_database.dart';
import 'package:iron_log/core/services/http_service.dart';
import 'package:iron_log/core/sync/sync_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_providers.g.dart';

final driftDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

final syncManagerProvider = Provider<SyncManager>((ref) {
  final dio = ref.read(httpServiceProvider);
  final database = ref.read(driftDatabaseProvider);
  final connectivity = ref.read(connectivityProvider);

  return SyncManager(
    dio: dio.dio,
    database: database,
    connectivity: connectivity,
  );
});

final syncStatusStreamProvider = StreamProvider.autoDispose<SyncStatus>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  return syncManager.syncStatus;
});

final syncConflictsStreamProvider = StreamProvider.autoDispose<SyncConflict>((
  ref,
) {
  final syncManager = ref.watch(syncManagerProvider);
  return syncManager.conflicts;
});

@Riverpod(keepAlive: true)
class SyncState extends _$SyncState {
  @override
  SyncStatus build() {
    final syncManager = ref.watch(syncManagerProvider);
    final subscription = syncManager.syncStatus.listen((status) {
      state = status;
    });
    ref.onDispose(subscription.cancel);
    return SyncStatus(
      isSyncing: false,
      lastSyncTime: null,
      pendingChanges: 0,
    );
  }

  Future<void> triggerSync() async {
    await ref.read(syncManagerProvider).sync();
  }
}

final pendingChangesCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final database = ref.read(driftDatabaseProvider);

  final pending = await (database.select(
    database.routines,
  )..where((r) => r.pendingSync.equals(true))).get();

  return pending.length;
});

final syncProvidersOverrides = [
  driftDatabaseProvider,
  connectivityProvider,
  syncManagerProvider,
];
