/// Nomes e config compartilhados entre resolver e provisioner E2E.
class E2eFixtureConstants {
  static const routineName = 'E2E Workout Routine';
  static const sessionName = 'E2E Session';
  static const division = 'E2E';

  static const exerciseNames = {
    'normal': 'E2E Normal',
    'warmup': 'E2E Warmup',
    'drop': 'E2E Drop',
    'cluster': 'E2E Cluster',
  };

  static const defaultExerciseConfig = {
    'series': 2,
    'reps': 8,
    'weight': 40,
    'weightUnit': 'kg',
    'restTime': 120,
    'rir': 2,
    'tag': 'multi',
    'variation': 'Traditional',
    'muscles': 'Peito',
  };
}
