import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/extensions/string_extensions.dart';
import 'package:iron_log/features/workout_day/domain/entities/series_entry.dart';
import '../atoms/custom_badge.dart';
import '../atoms/exercise_history_chip.dart';
import '../atoms/ai_suggestion_chip.dart';
import '../molecules/series_table.dart';
import '../molecules/exercise_history_modal.dart';
import '../molecules/quick_fill_chips.dart';
import '../../domain/entities/workout_exercise.dart';
import '../../domain/entities/weight_unit.dart';
import '../../domain/entities/suggestion_result.dart';
import '../../domain/enums/workout_screen_mode.dart';
import '../providers/workout_day_provider.dart';
import '../providers/exercise_last_sets_provider.dart';
import '../providers/exercise_suggestion_provider.dart';

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
  late String _notes;

  /// Authoritative list of per-series data. ExerciseCard is the single owner;
  /// SeriesTable is a controlled component that reads from this and reports changes.
  List<SeriesEntry> _currentEntries = const [];

  bool _isSuggestionLoading = false;
  bool _isSuggestionExpanded = false;
  SuggestionResult? _suggestion;

  @override
  void initState() {
    super.initState();
    _series = widget.exercise.series;
    _reps = widget.exercise.reps;
    _weight = widget.exercise.weight;
    _rir = widget.exercise.rir;
    _restTime = widget.exercise.restTime;
    _weightUnit = widget.exercise.weightUnit;
    _notes = widget.exercise.notes ?? '';
    _currentEntries = _buildEntries(widget.exercise.entries);
  }

  /// Builds the authoritative entries list from [source].
  /// If [source] is non-empty, uses it (extending/trimming to [_series]).
  /// Otherwise generates defaults from exercise weight/reps.
  List<SeriesEntry> _buildEntries(List<SeriesEntry> source) {
    if (source.isNotEmpty) {
      final result = List<SeriesEntry>.from(source);
      while (result.length < _series) {
        result.add(
          SeriesEntry(index: result.length, weight: _weight, reps: _reps),
        );
      }
      if (result.length > _series) return result.sublist(0, _series);
      return result;
    }
    final generated = List.generate(
      _series,
      (i) => SeriesEntry(
        index: i,
        weight: _weight,
        reps: _reps,
        // If source was empty, make the first generated row a warm-up
        // so the UI shows 'Aquec.' instead of default 'Trab'.
        type: (i == 0) ? 0 : 2,
      ),
    );

    // Debug: when UI generates default entries, log the assigned types
    if (generated.isNotEmpty) {
      debugPrint(
        '[ExerciseCard._buildEntries] source.empty, generated first.type=${generated[0].type} series=$_series exercise=${widget.exercise.name}',
      );
    }

    return generated;
  }

  @override
  void didUpdateWidget(covariant ExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync all exercise fields when backend updates the exercise
    if (widget.exercise != oldWidget.exercise) {
      setState(() {
        _series = widget.exercise.series;
        _reps = widget.exercise.reps;
        _weight = widget.exercise.weight;
        _rir = widget.exercise.rir;
        _restTime = widget.exercise.restTime;
        _weightUnit = widget.exercise.weightUnit;
        _notes = widget.exercise.notes ?? '';
      });
    }
    final incoming = widget.exercise.entries;
    // Sync when the provider delivers real entries (e.g. after async load)
    // but only if the user hasn’t typed anything unique yet.
    if (incoming.isNotEmpty && incoming != oldWidget.exercise.entries) {
      final userHasEdited = _currentEntries.any(
        (e) => e.weight != '' && e.weight != '0' && e.weight != _weight,
      );
      if (!userHasEdited) {
        setState(() => _currentEntries = _buildEntries(incoming));
      }
    }
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
          const SizedBox(height: 6),
          _buildChipsRow(ref),
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
          // Display notes if present
          if (_notes.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.yellow.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.yellow.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.note, size: 16, color: Colors.yellow.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _notes,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.yellow.shade900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
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
          if (_isSuggestionExpanded &&
              _suggestion != null &&
              _suggestion!.hasData)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: QuickFillChips(
                baseWeight: _suggestion!.suggestedWeight,
                onWeightSelected: _applyWeightToAllPendingSeries,
              ),
            ),
          //TODO: verificar no back-end pq aqui não está vindo o nome dos musculos e sim um id, pra isso vamos precisar verificar bem provavelmente talvez um log no back-end pra ver o que está passando aqui
          SeriesTable(
            count: _series,
            weight: _weight,
            reps: _reps,
            weightUnit: _weightUnit,
            entries: _currentEntries,
            onEntriesChanged: (entries) {
              setState(() => _currentEntries = List<SeriesEntry>.from(entries));
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
              setState(() {
                _series += 1;
                _currentEntries = [
                  ..._currentEntries,
                  SeriesEntry(
                    index: _currentEntries.length,
                    weight: _weight,
                    reps: _reps,
                  ),
                ];
              });
              _updateExercise();
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Adicionar série'),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showObservationsModal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _notes.isEmpty ? 'Adicionar observação' : _notes,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: _notes.isEmpty
                            ? Colors.grey.shade400
                            : Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipsRow(WidgetRef ref) {
    final historyAsync = ref.watch(
      exerciseLastSetsProvider(widget.exercise.id),
    );
    final history = historyAsync.asData?.value;

    return Row(
      children: [
        ExerciseHistoryChip(
          historyAsync: historyAsync,
          onTap: history != null && history.hasHistory
              ? () => showExerciseHistoryModal(
                  context,
                  history: history,
                  exerciseName: widget.exercise.name.toTitleCase(),
                )
              : null,
        ),
        const SizedBox(width: 8),
        AiSuggestionChip(isLoading: _isSuggestionLoading, onTap: _onAiChipTap),
      ],
    );
  }

  Future<void> _onAiChipTap() async {
    setState(() {
      _isSuggestionLoading = true;
      _isSuggestionExpanded = false;
    });
    try {
      final result = await ref.read(
        exerciseSuggestionProvider(widget.exercise.id).future,
      );
      if (mounted) {
        setState(() {
          _suggestion = result;
          _isSuggestionLoading = false;
          _isSuggestionExpanded = result.hasData;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSuggestionLoading = false);
      }
    }
  }

  void _applyWeightToAllPendingSeries(double weight) {
    final weightStr = weight % 1 == 0
        ? weight.toInt().toString()
        : weight.toStringAsFixed(1);

    final baseEntries = _currentEntries.isNotEmpty
        ? _currentEntries
        : List.generate(
            _series,
            (i) => SeriesEntry(index: i, weight: _weight, reps: _reps),
          );

    final updated = baseEntries
        .map((e) => e.done ? e : e.copyWith(weight: weightStr))
        .toList();

    setState(() {
      _currentEntries = updated;
      _weight = weightStr;
      _isSuggestionExpanded = false;
    });
    _updateExercise();
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
                  fontWeight: unit == u ? FontWeight.w600 : FontWeight.normal,
                  color: unit == u
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade400,
                ),
              ),
              if (u != WeightUnit.values.last)
                Text(
                  ' / ',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
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

  void _showObservationsModal() {
    final notesController = TextEditingController(text: _notes);
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
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.edit_note, color: Colors.blue.shade600),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Observações',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Notes TextField
              TextField(
                controller: notesController,
                maxLines: 4,
                minLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'Ex: Exercício dificultoso, tentar peso menor na próxima vez',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelText: 'Observações',
                  labelStyle: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 20),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _notes = notesController.text);
                      _updateExercise();
                      Navigator.pop(context);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Observações salvas!'),
                            duration: Duration(milliseconds: 1500),
                          ),
                        );
                      }
                    },
                    child: const Text('Salvar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editAdvanced() {
    _showObservationsModal();
  }

  void _showRemoveConfirmation() {
    final mode = ref.read(workoutScreenModeProvider);
    String message;
    if (mode == WorkoutScreenMode.template) {
      message =
          'Tem certeza que deseja remover "${widget.exercise.name.toTitleCase()}" do plano deste dia?';
    } else if (mode == WorkoutScreenMode.execution) {
      message =
          'Tem certeza que deseja remover "${widget.exercise.name.toTitleCase()}" desta execução?\n\nObservação: isso remove apenas deste treino. Para remover do planejamento (template), edite a sessão correspondente em "Sessões".';
    } else if (mode == WorkoutScreenMode.editing) {
      message =
          'Tem certeza que deseja remover "${widget.exercise.name.toTitleCase()}" deste treino registrado?\n\nObservação: isso remove apenas deste treino registrado. Para remover do planejamento (template), edite a sessão correspondente em "Sessões".';
    } else {
      message =
          'Tem certeza que deseja remover "${widget.exercise.name.toTitleCase()}"?';
    }

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
            Text(message, style: const TextStyle(fontSize: 16)),
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
    final mode = ref.read(workoutScreenModeProvider);

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

      // Chama o provider para remover do backend / atualizar workout conforme contexto
      await ref
          .read(workoutDayExercisesProvider.notifier)
          .removeExerciseFromSession(widget.sessionId!, widget.exercise.id);

      // Mostra sucesso contextualizado
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        String successMessage;
        if (mode == WorkoutScreenMode.execution) {
          successMessage =
              'Exercício removido deste treino. Para remover do planejamento, edite a sessão correspondente em "Sessões".';
        } else if (mode == WorkoutScreenMode.editing) {
          successMessage =
              'Exercício removido deste treino registrado com sucesso. Para remover do planejamento, edite a sessão correspondente em "Sessões".';
        } else if (mode == WorkoutScreenMode.template) {
          successMessage = 'Exercício removido do plano deste dia.';
        } else {
          successMessage = 'Exercício removido com sucesso.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
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
    debugPrint(
      '[ExerciseCard._updateExercise] called for ${widget.exercise.name}',
    );
    debugPrint(
      '[ExerciseCard._updateExercise] _currentEntries before copyWith: ${_currentEntries.map((e) => "s${e.index}(w=${e.weight} r=${e.reps})").join(", ")}',
    );
    final updated = widget.exercise.copyWith(
      series: _series,
      reps: _reps,
      weight: _weight,
      rir: _rir,
      restTime: _restTime,
      entries: List<SeriesEntry>.from(_currentEntries),
      notes: _notes.isEmpty ? null : _notes,
    );
    debugPrint(
      '[ExerciseCard._updateExercise] updated.entries: ${updated.entries.map((e) => "s${e.index}(w=${e.weight} r=${e.reps})").join(", ")}',
    );

    final mode = ref.read(workoutScreenModeProvider);
    final notifier = ref.read(workoutDayExercisesProvider.notifier);

    // Chama o método de atualização apropriado baseado no modo atual
    try {
      if (mode == WorkoutScreenMode.execution) {
        notifier.updateExerciseExecution(widget.exercise.id, updated);
      } else if (mode == WorkoutScreenMode.template) {
        notifier.updateExerciseTemplate(widget.exercise.id, updated);
      } else if (mode == WorkoutScreenMode.editing) {
        notifier.updateExerciseLog(widget.exercise.id, updated);
      } else {
        // Fallback para compatibilidade se modo não foi definido
        notifier.updateExercise(widget.exercise.id, updated);
      }
    } catch (e) {
      debugPrint(
        '[ExerciseCard._updateExercise] Erro ao atualizar exercício: $e',
      );
      // Mesmo com erro, tenta atualizar com o método legado para não bloquear UI
      notifier.updateExercise(widget.exercise.id, updated);
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
