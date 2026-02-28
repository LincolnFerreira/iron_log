import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/services/http_service.dart';
import 'domain/repositories/session_repository.dart';
import 'domain/usecases/session_usecases.dart';
import 'data/repositories/session_repository_impl.dart';

// Provider para o repositório usando HttpService unificado
final sessionRepositoryProviderImpl = Provider<SessionRepository>((ref) {
  final httpService = ref.watch(httpServiceProvider);
  return SessionRepositoryImpl(httpService.dio);
});

// Providers para use cases
final createSessionUseCaseProvider = Provider<CreateSessionUseCase>((ref) {
  final repository = ref.watch(sessionRepositoryProviderImpl);
  return CreateSessionUseCase(repository);
});

final updateSessionUseCaseProvider = Provider<UpdateSessionUseCase>((ref) {
  final repository = ref.watch(sessionRepositoryProviderImpl);
  return UpdateSessionUseCase(repository);
});

final deleteSessionUseCaseProvider = Provider<DeleteSessionUseCase>((ref) {
  final repository = ref.watch(sessionRepositoryProviderImpl);
  return DeleteSessionUseCase(repository);
});
