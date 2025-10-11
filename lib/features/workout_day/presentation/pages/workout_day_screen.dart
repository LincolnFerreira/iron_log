import 'package:flutter/material.dart';
import '../molecules/exercise_search_anchor.dart';
import '../organisms/exercise_card.dart';
import '../organisms/footer_actions.dart';
import 'package:iron_log/core/services/auth_service.dart';
import '../../../workout_session/presentation/pages/workout_session_screen.dart';

class WorkoutDayScreen extends StatefulWidget {
  final String? routineId; // rotina atual para salvar/começar treino
  final String? subtitle; // ex: 'Segunda-feira • PPL: Push'
  const WorkoutDayScreen({super.key, this.routineId, this.subtitle});

  @override
  State<WorkoutDayScreen> createState() => _WorkoutDayScreenState();
}

class _WorkoutDayScreenState extends State<WorkoutDayScreen> {
  // Lista de exercícios que pode ser reordenada
  late List<Map<String, dynamic>> exercises;

  @override
  void initState() {
    super.initState();
    exercises = [
      {
        'id': '1',
        'name': 'Supino Reto',
        'tag': 'Multi',
        'tagColor': Colors.blue,
        'muscles': 'Peitoral, Tríceps',
        'variation': 'Traditional',
        'series': 3,
        'reps': '10-12',
        'weight': '80kg',
        'rir': 2,
        'restTime': 120,
      },
      {
        'id': '2',
        'name': 'Desenvolvimento Ombros',
        'tag': 'Iso',
        'tagColor': Colors.green,
        'muscles': 'Deltoides',
        'variation': 'Traditional',
        'series': 4,
        'reps': '8-10',
        'weight': '25kg',
        'rir': 1,
        'restTime': 90,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            const SizedBox(height: 24),
            // Title Section (não é mais um card)
            _buildTitleSection(),
            const SizedBox(height: 16),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Field
                    ExerciseSearchAnchor(onExerciseSelected: _addExercise),
                    const SizedBox(height: 24),
                    // Exercises List with Drag and Drop
                    _buildExercisesList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: FooterActions(
        onSaveRoutine: _saveActiveRoutine,
        onStartWorkout: _startWorkout,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          const Expanded(
            child: Text(
              'Exercícios do Dia',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.subtitle ?? 'Push - Segunda-feira',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '3 exercícios adicionados',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE1BEE7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Ativo',
              style: TextStyle(
                color: const Color(0xFF7B1FA2),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addExercise(Map<String, dynamic> exercise) {
    setState(() {
      // Criar um novo exercício baseado nos dados da API
      final newExercise = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(), // ID único
        'name': exercise['name'] ?? 'Exercício sem nome',
        'tag': _getExerciseTag(exercise['category'] ?? ''),
        'tagColor': _getTagColor(exercise['category'] ?? ''),
        'muscles': exercise['muscles'] ?? '',
        'variation': 'Traditional', // Valor padrão
        'series': 3, // Valores padrão
        'reps': '10-12',
        'weight': '0kg',
        'rir': 2,
        'restTime': 120,
      };
      exercises.add(newExercise);
    });
  }

  String _getExerciseTag(String category) {
    switch (category.toLowerCase()) {
      case 'multi':
        return 'Multi';
      case 'iso':
        return 'Iso';
      case 'cardio':
        return 'Cardio';
      case 'funcional':
        return 'Funcional';
      default:
        return 'Multi';
    }
  }

  Color _getTagColor(String category) {
    switch (category.toLowerCase()) {
      case 'multi':
        return Colors.blue;
      case 'iso':
        return Colors.green;
      case 'cardio':
        return Colors.red;
      case 'funcional':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  // Monta o payload conforme CreateWorkoutDto do backend
  Map<String, dynamic> _buildCreateWorkoutPayload(String routineId) {
    List<Map<String, dynamic>> exPayload = [];
    for (final ex in exercises) {
      final sets = (ex['series'] as int?) ?? 0;
      final repsPattern = (ex['reps'] as String?) ?? '';
      final weightStr = (ex['weight'] as String?) ?? '0';
      final rirSingle = ex['rir'] is int ? ex['rir'] as int : null;
      final rest = ex['restTime'] is int ? ex['restTime'] as int : null;

      final repsArray = _expandReps(repsPattern, sets);
      final weightNum = _parseWeight(weightStr);
      final weightArray = List<double>.filled(sets, weightNum);
      final rirArray = rirSingle != null
          ? List<int>.filled(sets, rirSingle)
          : null;
      final restArray = rest != null ? List<int>.filled(sets, rest) : null;

      exPayload.add({
        'name': ex['name'] ?? 'Exercício',
        'sets': sets,
        'reps': repsArray,
        'weight': weightArray,
        if (rirArray != null) 'rir': rirArray,
        if (restArray != null) 'restSeconds': restArray,
      });
    }

    return {
      'routineId': routineId,
      'date': DateTime.now().toIso8601String(),
      'exercises': exPayload,
    };
  }

  // Expande um padrão de repetições ("8-10" ou "12") em array por número de séries
  List<int> _expandReps(String pattern, int sets) {
    int value;
    if (pattern.contains('-')) {
      final parts = pattern.split('-');
      final a = int.tryParse(parts.first.trim()) ?? 0;
      final b = int.tryParse(parts.last.trim()) ?? a;
      // Usamos a média arredondada para baixo para distribuir por série
      value = ((a + b) / 2).floor();
    } else {
      value = int.tryParse(pattern.trim()) ?? 0;
    }
    return List<int>.filled(sets, value);
  }

  // Converte string de peso como "80kg" para número 80.0
  double _parseWeight(String s) {
    final cleaned = s.toLowerCase().replaceAll('kg', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  Future<void> _saveActiveRoutine() async {
    final routineId = widget.routineId;
    if (routineId == null || routineId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rotina não informada para salvar como ativa.'),
          ),
        );
      }
      return;
    }
    try {
      final auth = AuthService();
      auth.initialize();
      await auth.authenticatedRequest(
        method: 'PATCH',
        path: '/user-profiles/active-routine/$routineId',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rotina definida como ativa.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar rotina ativa.')),
        );
      }
    }
  }

  void _startWorkout() {
    final routineId = widget.routineId;
    if (routineId == null || routineId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rotina não informada para iniciar o treino.'),
        ),
      );
      return;
    }

    // Cria a sessão no backend (exercícios serão registrados durante a execução)
    final auth = AuthService()..initialize();
    final payload = _buildCreateWorkoutPayload(routineId);
    auth
        .authenticatedRequest(method: 'POST', path: '/workout', data: payload)
        .then((res) {
          final workoutId = res.data['workoutId'] as String?;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WorkoutSessionScreen(
                workoutId: workoutId ?? '',
                subtitle: widget.subtitle ?? 'Treino de Hoje',
              ),
            ),
          );
        })
        .catchError((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível iniciar o treino.')),
          );
        });
  }

  Widget _buildExercisesList() {
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final exercise = exercises.removeAt(oldIndex);
          exercises.insert(newIndex, exercise);
        });
      },
      children: exercises.map((exercise) {
        return Container(
          key: ValueKey(exercise['id']),
          margin: const EdgeInsets.only(bottom: 16),
          child: ExerciseCard(
            name: exercise['name'],
            tag: exercise['tag'],
            tagColor: exercise['tagColor'],
            muscles: exercise['muscles'],
            variation: exercise['variation'],
            series: exercise['series'],
            reps: exercise['reps'],
            weight: exercise['weight'],
            rir: exercise['rir'],
            restTime: exercise['restTime'],
          ),
        );
      }).toList(),
    );
  }
}
