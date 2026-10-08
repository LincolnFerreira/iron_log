import 'package:iron_log/features/training_place/domain/entities/exercise_station.dart';
import 'package:iron_log/features/training_place/domain/entities/gym.dart';

abstract class TrainingPlaceRepository {
  Future<List<Gym>> listGyms();

  Future<Gym> createGym(String name, {bool attachUnscopedStations = false});

  Future<void> renameGym(String id, String name);

  /// Academia a gravar no treino: a única, ou a mais recente se houver várias.
  Future<String?> gymIdForWorkout();

  Future<void> touchGym(String id);

  Future<List<ExerciseStation>> listStations({
    required String exerciseId,
    String? gymId,
    bool includeUnscoped = false,
    int limit = 3,
  });

  Future<ExerciseStation> createStation({
    required String exerciseId,
    required String nickname,
    String? gymId,
    String? brand,
  });

  Future<ExerciseStation> renameStation(String id, String nickname);

  Future<void> archiveStation(String id);

  /// Marca a estação como a usada agora, para a próxima execução pré-selecionar.
  Future<void> touchStation(String id);
}
