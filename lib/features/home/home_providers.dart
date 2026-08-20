import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/services/http_service.dart';
import 'package:iron_log/features/home/data/datasources/home_remote_datasource.dart';
import 'package:iron_log/features/home/data/repositories/home_repository_impl.dart';
import 'package:iron_log/features/home/domain/repositories/home_repository.dart';

/// Abstract home repository — MUST be overridden at app startup.
final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  throw UnimplementedError(
    'homeRepositoryProvider must be overridden. '
    'Apply homeProvidersOverrides in ProviderScope.',
  );
});

final homeRemoteDataSourceProvider = Provider<HomeRemoteDataSource>((ref) {
  return HomeRemoteDataSource(ref.read(httpServiceProvider));
});

final homeRepositoryProviderImpl = Provider<HomeRepository>((ref) {
  return HomeRepositoryImpl(ref.read(homeRemoteDataSourceProvider));
});

final homeRepositoryOverride = homeRepositoryProvider.overrideWith(
  (ref) => ref.read(homeRepositoryProviderImpl),
);

/// Usage in main.dart: `overrides: [...homeProvidersOverrides]`
final homeProvidersOverrides = [homeRepositoryOverride];
