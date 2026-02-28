import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../atoms/custom_badge.dart';
// import '../molecules/metrics_row.dart'; // removed: metrics now interactive
import '../molecules/series_selector.dart';
import '../../domain/entities/workout_exercise.dart';
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
  SeriesType? _selectedSeriesType;

  @override
  void initState() {
    super.initState();
    _series = widget.exercise.series;
    _reps = widget.exercise.reps;
    _weight = widget.exercise.weight;
    _rir = widget.exercise.rir;
    _restTime = widget.exercise.restTime;
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
                  widget.exercise.name,
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
          Text(
            widget.exercise.muscles,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 8),

          // Variation Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  'Variação: ${widget.exercise.variation}',
                  style: const TextStyle(fontSize: 14),
                ),
                const Spacer(),
                const Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Interactive metrics: Séries, Reps, Carga
          Row(
            children: [
              // Séries (1..10)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Séries', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: _series,
                      items: List.generate(10, (i) => i + 1)
                          .map(
                            (v) =>
                                DropdownMenuItem(value: v, child: Text('$v')),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _series = v);
                        _updateExercise();
                      },
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Reps (1..100)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reps', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: int.tryParse(_reps) ?? 10,
                      items: List.generate(100, (i) => i + 1)
                          .map(
                            (v) =>
                                DropdownMenuItem(value: v, child: Text('$v')),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _reps = v.toString());
                        _updateExercise();
                      },
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Carga (1..1000)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Carga (kg)', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 44,
                      child: TextField(
                        controller: TextEditingController(
                          text: _weight.replaceAll('kg', ''),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          final num = int.tryParse(val) ?? 1;
                          final clamped = num.clamp(1, 1000);
                          setState(() => _weight = '${clamped}kg');
                          _updateExercise();
                        },
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // RIR selector with help and Rest time display
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('RIR', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: _rir,
                      items: List.generate(11, (i) => i)
                          .map(
                            (v) =>
                                DropdownMenuItem(value: v, child: Text('$v')),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _rir = v);
                        _updateExercise();
                      },
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'O que é RIR?',
                icon: const Icon(Icons.help_outline, size: 20),
                onPressed: _showRirHelp,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Descanso', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 6),
                    Text(
                      '${_restTime}s',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Series Type Selector
          SeriesSelector(
            seriesTypes: const [
              SeriesType.warmUp,
              SeriesType.feeder,
              SeriesType.topSet,
              SeriesType.backOff,
            ],
            selectedType: _selectedSeriesType,
            onTypeSelected: (type) {
              setState(() {
                _selectedSeriesType = type;
              });
            },
          ),
          const SizedBox(height: 16),

          // Notes Field
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Observações...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: 2,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
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
                    'Editar ${widget.exercise.name}',
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
              'Tem certeza que deseja remover "${widget.exercise.name}" desta sessão?',
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

  // Atualiza o exercício localmente e persiste via provider (opcionalmente)
  void _updateExercise() {
    final updated = widget.exercise.copyWith(
      series: _series,
      reps: _reps,
      weight: _weight,
      rir: _rir,
      restTime: _restTime,
    );

    // Atualiza estado local do provider
    ref
        .read(workoutDayExercisesProvider.notifier)
        .updateExercise(widget.exercise.id, updated);

    // Se esta card pertence a uma sessão, tenta salvar no backend
    if (widget.sessionId != null) {
      // Não aguarda aqui para evitar bloquear a UI; o provider faz o trabalho
      ref
          .read(workoutDayExercisesProvider.notifier)
          .saveSessionExercises(widget.sessionId!)
          .catchError((e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro ao salvar exercício: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          });
    }
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
