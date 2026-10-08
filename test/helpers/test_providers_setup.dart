import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/services/http_service.dart';
import 'package:iron_log/features/home/home_providers.dart';
import 'package:iron_log/features/routines/domain/entities/routine.dart';
import 'package:iron_log/features/routines/domain/entities/routine_update.dart';
import 'package:iron_log/features/routines/domain/entities/session_creation.dart';
import 'package:iron_log/features/routines/domain/repositories/routine_repository.dart';
import 'package:iron_log/features/routines/routine_providers.dart';
import 'package:iron_log/features/training_place/domain/entities/exercise_station.dart';
import 'package:iron_log/features/training_place/domain/entities/gym.dart';
import 'package:iron_log/features/training_place/domain/repositories/training_place_repository.dart';
import 'package:iron_log/features/training_place/training_place_providers.dart';
import 'package:iron_log/features/workout_history/workout_history_providers.dart';

/// Mock RoutineRepository for testing with proper type signatures
class MockRoutineRepository implements RoutineRepository {
  @override
  Future<Routine> createRoutine({
    required String name,
    String? division,
    bool isTemplate = false,
    List<SessionCreation>? sessions,
  }) async {
    throw UnimplementedError(
      'MockRoutineRepository.createRoutine not implemented',
    );
  }

  @override
  Future<void> deleteRoutine(String id) async {
    throw UnimplementedError(
      'MockRoutineRepository.deleteRoutine not implemented',
    );
  }

  @override
  Future<Routine> getRoutine(String id) async {
    throw UnimplementedError(
      'MockRoutineRepository.getRoutine not implemented',
    );
  }

  @override
  Future<List<Routine>> getRoutines() async {
    return [];
  }

  @override
  Future<Routine> updateRoutine(String id, RoutineUpdate updates) async {
    throw UnimplementedError(
      'MockRoutineRepository.updateRoutine not implemented',
    );
  }

  @override
  Future<void> setActiveRoutine(String routineId) async {
    throw UnimplementedError(
      'MockRoutineRepository.setActiveRoutine not implemented',
    );
  }
}

/// Creates a list of provider overrides for testing.
///
/// Paths pós-migração 006: routines providers em
/// `presentation/providers/`; home em `presentation/providers/`.
///
/// Usage:
/// ```dart
/// await tester.pumpWidget(
///   ProviderScope(
///     overrides: getTestProviderOverrides(),
///     child: MaterialApp(home: MyWidget()),
///   ),
/// );
/// ```
class _EmptyTrainingPlaceRepository implements TrainingPlaceRepository {
  @override
  Future<void> archiveStation(String id) async {}

  @override
  Future<Gym> createGym(String name, {bool attachUnscopedStations = false}) async {
    return Gym(id: 'gym-test', name: name, updatedAt: DateTime.now());
  }

  @override
  Future<ExerciseStation> createStation({
    required String exerciseId,
    required String nickname,
    String? gymId,
    String? brand,
  }) async {
    return ExerciseStation(
      id: 'station-test',
      exerciseId: exerciseId,
      nickname: nickname,
      gymId: gymId,
      brand: brand,
    );
  }

  @override
  Future<String?> gymIdForWorkout() async => null;

  @override
  Future<List<Gym>> listGyms() async => const [];

  @override
  Future<List<ExerciseStation>> listStations({
    required String exerciseId,
    String? gymId,
    bool includeUnscoped = false,
    int limit = 3,
  }) async => const [];

  @override
  Future<void> renameGym(String id, String name) async {}

  @override
  Future<ExerciseStation> renameStation(String id, String nickname) async {
    return ExerciseStation(id: id, exerciseId: '', nickname: nickname);
  }

  @override
  Future<void> touchGym(String id) async {}

  @override
  Future<void> touchStation(String id) async {}
}

List<Override> getTestProviderOverrides() {
  // Create a test HttpService that's properly initialized
  final testHttpService = HttpService();
  testHttpService.initialize();

  return [
    // Override httpServiceProvider to return our initialized test instance
    httpServiceProvider.overrideWithValue(testHttpService),

    // Apply home + routine provider overrides
    ...homeProvidersOverrides,
    ...routineProvidersOverrides,
    ...workoutHistoryProvidersOverrides,
    trainingPlaceRepositoryProvider.overrideWithValue(
      _EmptyTrainingPlaceRepository(),
    ),
  ];
}
