import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/session_creation.dart';
import '../../domain/entities/routine_update.dart';
import '../../domain/repositories/routine_repository.dart';
import '../../domain/usecases/routine_usecases.dart';

export 'routine_controller.dart';
export 'routine_state.dart';

// This provider must be overridden by routineProvidersOverrides in main.dart
final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  throw UnimplementedError(
    'RoutineRepository provider must be overridden in ProviderScope. '
    'Make sure routineProvidersOverrides are applied in main.dart',
  );
});

final getRoutinesUseCaseProvider = Provider<GetRoutinesUseCase>((ref) {
  final repository = ref.read(routineRepositoryProvider);
  return GetRoutinesUseCase(repository);
});

final getRoutineUseCaseProvider = Provider<GetRoutineUseCase>((ref) {
  final repository = ref.read(routineRepositoryProvider);
  return GetRoutineUseCase(repository);
});

final createRoutineUseCaseProvider = Provider<CreateRoutineUseCase>((ref) {
  final repository = ref.read(routineRepositoryProvider);
  return CreateRoutineUseCase(repository);
});

final updateRoutineUseCaseProvider = Provider<UpdateRoutineUseCase>((ref) {
  final repository = ref.read(routineRepositoryProvider);
  return UpdateRoutineUseCase(repository);
});

final deleteRoutineUseCaseProvider = Provider<DeleteRoutineUseCase>((ref) {
  final repository = ref.read(routineRepositoryProvider);
  return DeleteRoutineUseCase(repository);
});
