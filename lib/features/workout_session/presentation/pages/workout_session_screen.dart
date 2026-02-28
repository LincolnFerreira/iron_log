import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../atoms/atoms.dart';
import '../molecules/molecules.dart';
import '../providers/session_exercises_provider.dart';

class WorkoutSessionScreen extends ConsumerStatefulWidget {
  final String workoutId;
  final String subtitle;
  const WorkoutSessionScreen({
    super.key,
    required this.workoutId,
    required this.subtitle,
  });

  @override
  ConsumerState<WorkoutSessionScreen> createState() =>
      _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends ConsumerState<WorkoutSessionScreen> {
  late Timer _timer;
  int _elapsedSeconds = 0;

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
              child: Consumer(
                builder: (context, ref, child) {
                  final sessionExercises = ref.watch(
                    sessionExercisesProvider(widget.workoutId),
                  );

                  return sessionExercises.when(
                    data: (exercises) => ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: exercises.length + 2,
                      itemBuilder: (context, index) {
                        if (index < exercises.length) {
                          final ex = exercises[index];
                          return ExerciseRow(
                            name: ex.name,
                            progressText: '${ex.done}/${ex.sets} séries',
                            weightText: ex.weight,
                            repsText: ex.reps,
                            count: ex.done,
                            onIncrement: () {
                              ref
                                  .read(
                                    sessionExercisesProvider(
                                      widget.workoutId,
                                    ).notifier,
                                  )
                                  .markSetAsDone(index);
                            },
                          );
                        }
                        if (index == exercises.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: DottedBorderButton(
                              label: '+ Adicionar Exercício',
                              onTap: () {
                                // TODO: Implementar adição de exercícios durante a sessão
                              },
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
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Erro ao carregar exercícios',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              ref
                                  .read(
                                    sessionExercisesProvider(
                                      widget.workoutId,
                                    ).notifier,
                                  )
                                  .loadSessionExercises();
                            },
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    ),
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

  Future<void> _finish() async {
    try {
      // Salvar progresso da sessão
      await ref
          .read(sessionExercisesProvider(widget.workoutId).notifier)
          .saveSessionProgress();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Treino finalizado com sucesso!'),
            backgroundColor: Color(0xFF1B873E),
          ),
        );

        // Navegar de volta após salvar
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao finalizar treino: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
