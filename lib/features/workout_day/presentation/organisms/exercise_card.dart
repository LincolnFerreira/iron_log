import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/extensions/string_extensions.dart';
import 'package:iron_log/features/workout_day/domain/entities/series_entry.dart';
import 'package:iron_log/features/workout_day/presentation/molecules/series_selector.dart';
import '../atoms/custom_badge.dart';
import '../molecules/series_table.dart';
import '../../domain/entities/workout_exercise.dart';
import '../../domain/entities/weight_unit.dart';
import '../providers/workout_day_provider.dart';

class ExerciseCard extends ConsumerStatefulWidget {
  final WorkoutExercise exercise;
  final Function(WorkoutExercise)? onExerciseUpdated;
  final String? sessionId; // ID da sessão para remoção
  final int? index; // Índice para o drag and drop

  const ExerciseCard({
    super.key,
    required this.exercise,
    this.onExerciseUpdated,
    this.sessionId,
    this.index,
  });

  @override
  ConsumerState<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends ConsumerState<ExerciseCard> {
  late int _series;
  late String _reps;
  late String _weight;
  late int _rir;
  late int _restTime;
  late WeightUnit _weightUnit;
  SeriesType? _selectedSeriesType;

  /// Tracks the live per-series data reported by SeriesTable via onEntriesChanged.
  List<SeriesEntry> _currentEntries = const [];

  @override
  void initState() {
    super.initState();
    _series = widget.exercise.series;
    _reps = widget.exercise.reps;
    _weight = widget.exercise.weight;
    _rir = widget.exercise.rir;
    _restTime = widget.exercise.restTime;
    _weightUnit = widget.exercise.weightUnit;
    // Initialise from already-loaded entries (e.g. previous workout view).
    _currentEntries = List<SeriesEntry>.from(widget.exercise.entries);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with name and tag
          Row(
            children: [
              // Drag handle - apenas ativo quando index é fornecido
              if (widget.index != null)
                ReorderableDragStartListener(
                  index: widget.index!,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.drag_indicator,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
              if (widget.index != null) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.exercise.name.toTitleCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              CustomBadge(
                text: widget.exercise.tag.label,
                backgroundColor: widget.exercise.tag.color.withOpacity(0.1),
                textColor: widget.exercise.tag.color,
              ),
              // Menu button
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  if (widget.sessionId != null) ...[
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Remover', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ],
                child: const Icon(Icons.more_vert, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 4),
          //TODO: verificar no back-end pq aqui não está vindo o nome dos musculos e sim um id, pra isso vamos precisar verificar bem provavelmente talvez um log no back-end pra ver o que está passando aqui
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.exercise.muscles,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ),
              _buildWeightUnitToggle(ref),
            ],
          ),
          const SizedBox(height: 8),

          // Variation Dropdown
          // Container(
          //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          //   decoration: BoxDecoration(
          //     color: Colors.grey.shade50,
          //     borderRadius: BorderRadius.circular(8),
          //   ),
          //   child: Row(
          //     children: [
          //       Text(
          //         'Variação: ${widget.exercise.variation}',
          //         style: const TextStyle(fontSize: 14),
          //       ),
          //       const Spacer(),
          //       const Icon(Icons.keyboard_arrow_down),
          //     ],
          //   ),
          // ),
          // const SizedBox(height: 16),

          // Add series button (shows rows when _series > 0)
          SeriesTable(
            count: _series,
            weight: _weight,
            reps: _reps,
            weightUnit: _weightUnit.label,
            initialEntries: _currentEntries.isNotEmpty ? _currentEntries : null,
            onEntriesChanged: (entries) {
              _currentEntries = entries;
              _updateExercise();
            },
            onToggleDone: (index, done) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      done
                          ? 'Série ${index + 1} marcada como feita'
                          : 'Série ${index + 1} desmarcada',
                    ),
                  ),
                );
              }
            },
          ),
          TextButton.icon(
            onPressed: () {
              setState(() => _series = (_series + 1));
              _updateExercise();
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Adicionar série'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightUnitToggle(WidgetRef ref) {
    final unit = _weightUnit;
    return GestureDetector(
      onTap: () {
        final newUnit = unit.next;
        setState(() => _weightUnit = newUnit);
        ref
            .read(workoutDayExercisesProvider.notifier)
            .updateExercise(
              widget.exercise.id,
              widget.exercise.copyWith(weightUnit: newUnit),
            );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: WeightUnit.values.expand((u) {
            return [
              Text(
                u.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      unit == u ? FontWeight.w600 : FontWeight.normal,
                  color: unit == u
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade400,
                ),
              ),
              if (u != WeightUnit.values.last)
                Text(
                  ' / ',
                  style:
                      TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
            ];
          }).toList(),
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _showEditOptions();
        break;
      case 'remove':
        if (widget.sessionId != null) {
          _showRemoveConfirmation();
        }
        break;
    }
  }

  void _showEditOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.edit, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Editar ${widget.exercise.name.toTitleCase()}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Opções de edição
            _buildEditOption(
              icon: Icons.fitness_center,
              title: 'Alterar Séries e Repetições',
              subtitle: 'Ajustar volume do exercício',
              onTap: () {
                Navigator.pop(context);
                _editSeriesAndReps();
              },
            ),
            _buildEditOption(
              icon: Icons.monitor_weight,
              title: 'Alterar Carga',
              subtitle: 'Ajustar peso utilizado',
              onTap: () {
                Navigator.pop(context);
                _editWeight();
              },
            ),
            _buildEditOption(
              icon: Icons.timer,
              title: 'Alterar Descanso',
              subtitle: 'Tempo entre séries',
              onTap: () {
                Navigator.pop(context);
                _editRestTime();
              },
            ),
            _buildEditOption(
              icon: Icons.settings,
              title: 'Configurações Avançadas',
              subtitle: 'RIR, variação e observações',
              onTap: () {
                Navigator.pop(context);
                _editAdvanced();
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEditOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade50,
        child: Icon(icon, color: Colors.blue.shade600, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  // Métodos de edição específicos (placeholders por enquanto)
  void _editSeriesAndReps() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🏋️ Edição de séries e reps em desenvolvimento'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _editWeight() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚖️ Edição de carga em desenvolvimento'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _editRestTime() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏱️ Edição de descanso em desenvolvimento'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _editAdvanced() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚙️ Configurações avançadas em desenvolvimento'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showRemoveConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
            const SizedBox(width: 12),
            const Text('Remover Exercício'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tem certeza que deseja remover "${widget.exercise.name.toTitleCase()}" desta sessão?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.red.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Esta ação não pode ser desfeita.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeExercise();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeExercise() async {
    if (widget.sessionId == null) return;

    try {
      // Mostra loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Removendo exercício...'),
            ],
          ),
        ),
      );

      // Chama o provider para remover do backend
      await ref
          .read(workoutDayExercisesProvider.notifier)
          .removeExerciseFromSession(widget.sessionId!, widget.exercise.id);

      // Mostra sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exercício removido com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Mostra erro
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover exercício: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Atualiza o exercício localmente no provider com os valores actuais.
  // Não persiste no backend aqui — isso acontece apenas ao finalizar o treino.
  void _updateExercise() {
    final updated = widget.exercise.copyWith(
      series: _series,
      reps: _reps,
      weight: _weight,
      rir: _rir,
      restTime: _restTime,
      entries: List<SeriesEntry>.from(_currentEntries),
    );

    ref
        .read(workoutDayExercisesProvider.notifier)
        .updateExercise(widget.exercise.id, updated);
  }

  void _showRirHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('O que é RIR?'),
        content: const Text(
          'RIR (Repetitions In Reserve) é o número de repetições que você acredita que ainda poderia fazer no final de uma série.\n\n'
          'Por exemplo, RIR 0 significa que a série foi feita até a falha; RIR 2 significa que você ainda teria cerca de 2 repetições no tanque.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
