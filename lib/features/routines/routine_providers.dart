import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/services/http_service.dart';
import 'data/repositories/routine_repository_impl.dart';
import 'domain/repositories/routine_repository.dart';
import 'presentation/bloc/routine_provider.dart';

// Provider para o repositório usando HttpService unificado
final routineRepositoryProviderImpl = Provider<RoutineRepository>((ref) {
  final httpService = ref.watch(httpServiceProvider);
  return RoutineRepositoryImpl(httpService.dio);
});

// Override do provider abstrato
final routineRepositoryOverride = routineRepositoryProvider.overrideWith(
  (ref) => ref.watch(routineRepositoryProviderImpl),
);

// Lista de overrides para configurar os providers
final routineProvidersOverrides = [routineRepositoryOverride];
