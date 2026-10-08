import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/providers/sync_providers.dart';
import 'package:iron_log/core/services/http_service.dart';
import 'package:iron_log/features/auth/auth.dart';
import 'package:iron_log/features/training_place/data/datasources/training_place_local_datasource.dart';
import 'package:iron_log/features/training_place/data/datasources/training_place_remote_datasource.dart';
import 'package:iron_log/features/training_place/data/repositories/training_place_repository_impl.dart';
import 'package:iron_log/features/training_place/domain/repositories/training_place_repository.dart';

final trainingPlaceRepositoryProvider = Provider<TrainingPlaceRepository>((ref) {
  throw UnimplementedError(
    'TrainingPlaceRepository provider must be overridden in ProviderScope. '
    'Make sure trainingPlaceProvidersOverrides are applied in main.dart',
  );
});

final trainingPlaceRepositoryProviderImpl = Provider<TrainingPlaceRepository>((
  ref,
) {
  final userId = ref.watch(authStateProvider.select((s) => s.user?.uid ?? ''));
  final database = ref.read(driftDatabaseProvider);
  final dio = ref.read(httpServiceProvider).dio;
  return TrainingPlaceRepositoryImpl(
    local: TrainingPlaceLocalDataSource(database),
    remote: TrainingPlaceRemoteDataSource(dio),
    userId: userId,
  );
});

final trainingPlaceRepositoryOverride =
    trainingPlaceRepositoryProvider.overrideWith(
  (ref) => ref.watch(trainingPlaceRepositoryProviderImpl),
);

final trainingPlaceProvidersOverrides = [trainingPlaceRepositoryOverride];
