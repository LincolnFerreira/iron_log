import 'dart:async';
import 'package:flutter/material.dart';
import '../atoms/atoms.dart';
import '../molecules/molecules.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final String workoutId;
  final String subtitle;
  const WorkoutSessionScreen({
    super.key,
    required this.workoutId,
    required this.subtitle,
  });

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  late Timer _timer;
  int _elapsedSeconds = 0;

  // Mock exercises for the session
  final List<Map<String, dynamic>> _sessionExercises = [
    {
      'name': 'Desenvolvimento Halteres',
      'sets': 4,
      'done': 0,
      'weight': '30kg',
      'reps': '8-10',
    },
    {
      'name': 'Elevação Lateral',
      'sets': 3,
      'done': 0,
      'weight': '10kg',
      'reps': '12-15',
    },
    {
      'name': 'Tríceps Corda',
      'sets': 3,
      'done': 0,
      'weight': '25kg',
      'reps': '10-12',
    },
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(1, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress => (_elapsedSeconds % 600) / 600; // mock progress

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Column(
          children: [
            WorkoutHeader(subtitle: widget.subtitle),
            TopTimerCard(
              timeText: _formatTime(_elapsedSeconds),
              progress: _progress,
              onAddSet: () {
                // optional: quick add set action
              },
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: _sessionExercises.length + 2,
                itemBuilder: (context, index) {
                  if (index < _sessionExercises.length) {
                    final ex = _sessionExercises[index];
                    return ExerciseRow(
                      name: ex['name'],
                      progressText: '${ex['done']}/${ex['sets']} séries',
                      weightText: ex['weight'],
                      repsText: ex['reps'],
                      count: ex['done'],
                      onIncrement: () {
                        setState(() {
                          if (ex['done'] < ex['sets']) ex['done']++;
                        });
                      },
                    );
                  }
                  if (index == _sessionExercises.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: DottedBorderButton(
                        label: '+ Adicionar Exercício',
                        onTap: () {},
                      ),
                    );
                  }
                  return const WorkoutSummaryCard(
                    totalVolume: '1,240kg',
                    topSets: '1',
                    avgRir: '2.0',
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: SecondaryButton(
                text: 'Pausar',
                icon: Icons.pause,
                onPressed: _pauseResume,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                text: 'Finalizar',
                icon: Icons.check,
                backgroundColor: const Color(0xFF1B873E),
                onPressed: _finish,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pauseResume() {
    if (_timer.isActive) {
      _timer.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _elapsedSeconds++);
      });
    }
    setState(() {});
  }

  void _finish() {
    // mock finalize
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Treino finalizado (mock)')));
  }
}

class DottedBorderButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const DottedBorderButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.grey.shade400,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
