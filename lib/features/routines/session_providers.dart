import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/services/http_service.dart';
import 'package:iron_log/features/routines/data/repositories/session_repository_impl.dart';
import 'package:iron_log/features/routines/domain/repositories/session_repository.dart';
import 'package:iron_log/features/routines/domain/usecases/session_usecases.dart';

final sessionRepositoryProviderImpl = Provider<SessionRepository>((ref) {
  final httpService = ref.read(httpServiceProvider);
  return SessionRepositoryImpl(httpService.dio);
});

final createSessionUseCaseProvider = Provider<CreateSessionUseCase>((ref) {
  return CreateSessionUseCase(ref.read(sessionRepositoryProviderImpl));
});

final updateSessionUseCaseProvider = Provider<UpdateSessionUseCase>((ref) {
  return UpdateSessionUseCase(ref.read(sessionRepositoryProviderImpl));
});

final deleteSessionUseCaseProvider = Provider<DeleteSessionUseCase>((ref) {
  return DeleteSessionUseCase(ref.read(sessionRepositoryProviderImpl));
});

final updateSessionExercisesUseCaseProvider =
    Provider<UpdateSessionExercisesUseCase>((ref) {
      return UpdateSessionExercisesUseCase(
        ref.read(sessionRepositoryProviderImpl),
      );
    });

final removeExerciseFromSessionUseCaseProvider =
    Provider<RemoveExerciseFromSessionUseCase>((ref) {
      return RemoveExerciseFromSessionUseCase(
        ref.read(sessionRepositoryProviderImpl),
      );
    });
