import 'package:flutter/material.dart';
import '../components/molecules/workout_stats_bar.dart';

class FooterActions extends StatefulWidget {
  final VoidCallback? onStartWorkout;
  final VoidCallback? onFinishWorkout;
  final VoidCallback? onDiscard;
  final VoidCallback? onSaveTrain;
  final bool workoutStarted;
  final bool isLoading;
  final int seriesDone;
  final double volumeKg;
  final int completionPercent;

  const FooterActions({
    super.key,
    this.onStartWorkout,
    this.onFinishWorkout,
    this.onDiscard,
    this.onSaveTrain,
    this.workoutStarted = false,
    this.isLoading = false,
    this.seriesDone = 0,
    this.volumeKg = 0.0,
    this.completionPercent = 0,
  });

  @override
  State<FooterActions> createState() => _FooterActionsState();
}

class _FooterActionsState extends State<FooterActions> {
  void _showDiscardConfirmation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade600,
                ),
                const SizedBox(width: 12),
                Text(
                  'Descartar Treino',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Tem certeza que deseja descartar este treino? Todos os exercícios adicionados serão perdidos.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onDiscard?.call();
                    },
                    child: const Text(
                      'Descartar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.workoutStarted)
            WorkoutStatsBar(
              seriesDone: widget.seriesDone,
              volumeKg: widget.volumeKg,
              completionPercent: widget.completionPercent,
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: widget.workoutStarted
                ? Row(
                    children: [
                      // Botão Finalizar Treino (maior, flex 3)
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          onPressed: widget.onFinishWorkout,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Finalizar Treino'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Botão Descartar (menor, ícone X)
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _showDiscardConfirmation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Icon(Icons.close, size: 24),
                        ),
                      ),
                    ],
                  )
                : Row(
                    spacing: 12,
                    children: [
                      // Botão Adicionar Exercício
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onSaveTrain,
                          icon: const Icon(Icons.save),
                          label: const Text('Salvar Treino'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      // Botão Iniciar Treino (maior)
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: widget.onStartWorkout,
                          icon: const Icon(Icons.play_circle_outline),
                          label: const Text('Iniciar Treino'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
