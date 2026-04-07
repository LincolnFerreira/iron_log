import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/routines/domain/repositories/routine_repository.dart';
import 'package:iron_log/features/routines/domain/entities/routine.dart';
import 'package:iron_log/features/routines/domain/entities/session_creation.dart';
import 'package:iron_log/features/routines/domain/entities/routine_update.dart';
import 'package:iron_log/features/routines/routine_providers.dart';
import 'package:iron_log/core/services/http_service.dart';

/// Mock RoutineRepository for testing with proper type signatures
class MockRoutineRepository implements RoutineRepository {
  @override
  Future<Routine> createRoutine({
    required String name,
    String? division,
    bool isTemplate = false,
    List<SessionCreation>? sessions,
  }) async {
    throw UnimplementedError('MockRoutineRepository.createRoutine not implemented');
  }

  @override
  Future<void> deleteRoutine(String id) async {
    throw UnimplementedError('MockRoutineRepository.deleteRoutine not implemented');
  }

  @override
  Future<Routine> getRoutine(String id) async {
    throw UnimplementedError('MockRoutineRepository.getRoutine not implemented');
  }

  @override
  Future<List<Routine>> getRoutines() async {
    return [];
  }

  @override
  Future<Routine> updateRoutine(String id, RoutineUpdate updates) async {
    throw UnimplementedError('MockRoutineRepository.updateRoutine not implemented');
  }
}

/// Creates a list of provider overrides for testing
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
List<Override> getTestProviderOverrides() {
  // Create a test HttpService that's properly initialized
  final testHttpService = HttpService();
  testHttpService.initialize();
  
  return [
    // Override httpServiceProvider to return our initialized test instance
    httpServiceProvider.overrideWithValue(testHttpService),
    
    // Override routineRepositoryProvider to use the proper implementation chain
    routineRepositoryOverride,
    
    // Apply all routine provider overrides
    ...routineProvidersOverrides,
  ];
}
