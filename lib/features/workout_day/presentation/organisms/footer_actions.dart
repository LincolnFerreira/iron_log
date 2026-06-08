import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/app_colors.dart';
import 'package:iron_log/core/extensions/string_extensions.dart';
import '../../domain/entities/series_entry.dart';
import '../../domain/entities/workout_exercise.dart';
import '../providers/exercise_suggestion_provider.dart';
import '../providers/exercise_last_sets_provider.dart';
import 'package:iron_log/features/workout_day/presentation/workout_test_keys.dart';
import '../providers/workout_day_provider.dart';
import '../../domain/enums/workout_screen_mode.dart';

class FooterActions extends ConsumerStatefulWidget {
  final VoidCallback? onStartWorkout;
  final VoidCallback? onFinishWorkout;
  final VoidCallback? onDiscard;
  final VoidCallback? onSaveTrain;

  /// Reordenar / mais opções (ex.: mesmo fluxo do menu do header).
  final VoidCallback? onMoreOptions;

  /// Nome da sessão exibido no topo do rodapé (ex.: `WorkoutDayScreen.subtitle`).
  final String? sessionTitle;
  final bool workoutStarted;
  final bool isLoading;
  final bool isManual;
  final List<WorkoutExercise> exercises;

  const FooterActions({
    super.key,
    this.onStartWorkout,
    this.onFinishWorkout,
    this.onDiscard,
    this.onSaveTrain,
    this.onMoreOptions,
    this.sessionTitle,
    this.workoutStarted = false,
    this.isLoading = false,
    this.isManual = false,
    this.exercises = const [],
  });

  @override
  ConsumerState<FooterActions> createState() => _FooterActionsState();
}

class _FooterActionsState extends ConsumerState<FooterActions> {
  double _selectedWeight = 0;
  int _selectedReps = 0;
  bool _weightInitialized = false;
  String? _lastFooterExerciseId;

  /// Quando true, a faixa de chips + texto de ajuda (e o aviso de bloqueio) ficam ocultos.
  bool _suggestionsMinimized = true;

  /// Última assinatura dos dados da célula focada (peso/reps/done) já aplicada ao estado local.
  String? _lastSyncedEntrySignature;

  /// Evita enfileirar vários syncs para a mesma assinatura antes do post-frame.
  String? _pendingSyncSignature;

  WorkoutExercise? _footerExercise(
    List<WorkoutExercise> list,
    WorkoutFooterFocus focus,
  ) {
    if (list.isEmpty) return null;
    final id = focus.exerciseId;
    if (id != null && id.isNotEmpty) {
      for (final e in list) {
        if (e.id == id) return e;
      }
    }
    return list.first;
  }

  int _footerSeriesIndex(WorkoutExercise ex, WorkoutFooterFocus focus) {
    final planned = ex.series > 0
        ? ex.series
        : (ex.entries.isNotEmpty ? ex.entries.length : 1);
    final cap = planned.clamp(1, 999) - 1;
    return focus.seriesIndex.clamp(0, cap);
  }

  bool _allSeriesDoneFor(WorkoutExercise? ex) {
    if (ex == null) return true;
    if (ex.entries.isEmpty) return false;
    return ex.entries.every((e) => e.done);
  }

  String _entrySyncSignature(WorkoutExercise ex, int idx) {
    final w = idx < ex.entries.length ? ex.entries[idx].weight : ex.weight;
    final r = idx < ex.entries.length ? ex.entries[idx].reps : ex.reps;
    final d = idx < ex.entries.length ? ex.entries[idx].done : false;
    return '${ex.id}|$idx|$w|$r|${ex.entries.length}|$d';
  }

  double _weightFromEntry(WorkoutExercise ex, int idx) {
    final raw = idx < ex.entries.length ? ex.entries[idx].weight : ex.weight;
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  int _repsFromEntry(WorkoutExercise ex, int idx) {
    final raw = idx < ex.entries.length ? ex.entries[idx].reps : ex.reps;
    return int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  void _scheduleSyncFromEntries(
    WorkoutExercise? ex,
    int idx,
    String signature,
  ) {
    if (ex == null) return;
    if (signature == _lastSyncedEntrySignature ||
        signature == _pendingSyncSignature) {
      return;
    }
    _pendingSyncSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final focus = ref.read(workoutFooterFocusProvider);
      final ex2 = _footerExercise(widget.exercises, focus);
      if (ex2 == null) {
        _pendingSyncSignature = null;
        return;
      }
      final idx2 = _footerSeriesIndex(ex2, focus);
      final sig2 = _entrySyncSignature(ex2, idx2);
      if (sig2 != signature) {
        _pendingSyncSignature = null;
        return;
      }
      _pendingSyncSignature = null;
      setState(() {
        _lastSyncedEntrySignature = sig2;
        final rawW = idx2 < ex2.entries.length
            ? ex2.entries[idx2].weight
            : ex2.weight;
        final rawEmpty =
            rawW.isEmpty || rawW == '0' || rawW == '-' || rawW == '0.0';
        final parsed = _weightFromEntry(ex2, idx2);
        if (!(rawEmpty && parsed == 0 && _selectedWeight > 0)) {
          _selectedWeight = parsed;
          _selectedReps = _repsFromEntry(ex2, idx2);
        }
      });
    });
  }

  @override
  void didUpdateWidget(FooterActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.workoutStarted && !oldWidget.workoutStarted) {
      setState(() => _suggestionsMinimized = false);
    } else if (!widget.workoutStarted && oldWidget.workoutStarted) {
      setState(() => _suggestionsMinimized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final focus = ref.watch(workoutFooterFocusProvider);
    final list = widget.exercises;
    final ex = _footerExercise(list, focus);
    final idx = ex == null ? 0 : _footerSeriesIndex(ex, focus);
    final sig = ex == null ? '' : _entrySyncSignature(ex, idx);

    if (ex != null && ex.id != _lastFooterExerciseId) {
      _lastFooterExerciseId = ex.id;
      _weightInitialized = false;
      _suggestionsMinimized = !widget.workoutStarted;
      _lastSyncedEntrySignature = null;
      _pendingSyncSignature = null;
    }

    _scheduleSyncFromEntries(ex, idx, sig);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Center(
                child: Container(
                  width: 36,
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.dark50 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            if (!widget.isManual && widget.exercises.isNotEmpty)
              _buildSessionHeader(theme, isDark),
            if (!widget.isManual && ex != null)
              _buildWeightAssistant(theme, isDark, ex, idx),
            _buildActions(theme, isDark),
          ],
        ),
      ),
    );
  }

  int _estimateSessionMinutes() {
    var total = 0.0;
    for (final ex in widget.exercises) {
      final s = ex.series > 0 ? ex.series : 1;
      final restMin = ex.restTime / 60.0;
      total += s * 1.2 + (s > 1 ? (s - 1) * restMin : 0);
    }
    return total.ceil().clamp(5, 300);
  }

  Widget _buildSessionHeader(ThemeData theme, bool isDark) {
    final title =
        (widget.sessionTitle != null && widget.sessionTitle!.trim().isNotEmpty)
        ? widget.sessionTitle!.trim()
        : 'Treino';
    final n = widget.exercises.length;
    final min = _estimateSessionMinutes();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.25,
              height: 1.2,
              color: isDark ? Colors.white : AppColors.gray90,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '$n exercício${n == 1 ? '' : 's'} • ~$min min estimado',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              height: 1.3,
              color: isDark ? AppColors.gray50 : AppColors.gray60,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Peso / séries (layout próximo ao mock da sessão) ────────────────

  Widget _buildWeightAssistant(
    ThemeData theme,
    bool isDark,
    WorkoutExercise exercise,
    int seriesIdx,
  ) {
    final assistantEnabled = widget.workoutStarted;
    final allDone = _allSeriesDoneFor(exercise);
    final primary = theme.colorScheme.primary;

    final suggestionAsync = ref.watch(exerciseSuggestionProvider(exercise.id));
    final historyAsync = ref.watch(exerciseLastSetsProvider(exercise.id));
    final lastSets = historyAsync.asData?.value;
    final sugg = suggestionAsync.asData?.value;
    final hasAi = sugg != null && sugg.hasData;

    if (!_weightInitialized) {
      double initial = 0;
      int initialReps = 0;

      if (hasAi) {
        initial = sugg.suggestedWeight;
        initialReps = sugg.suggestedReps ?? 0;
      } else if (lastSets != null &&
          lastSets.hasHistory &&
          lastSets.sets.isNotEmpty) {
        initial = lastSets.sets.first.weight ?? 0;
        initialReps = lastSets.sets.first.reps ?? 0;
      } else if (seriesIdx < exercise.entries.length) {
        final wStr = exercise.entries[seriesIdx].weight.replaceAll(
          RegExp(r'[^0-9.]'),
          '',
        );
        initial = double.tryParse(wStr) ?? 0;
        initialReps = int.tryParse(
              exercise.entries[seriesIdx].reps.replaceAll(RegExp(r'[^0-9]'), ''),
            ) ??
            0;
      } else {
        final wStr = exercise.weight.replaceAll(RegExp(r'[^0-9.]'), '');
        initial = double.tryParse(wStr) ?? 0;
        initialReps =
            int.tryParse(exercise.reps.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      }

      if (initial > 0 || (sugg != null && !suggestionAsync.isLoading)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedWeight = initial;
              _selectedReps = initialReps;
              _weightInitialized = true;
            });
          }
        });
      }
    }

    final center = _selectedWeight;
    final leftW = (center - 2.5).clamp(0.0, double.infinity);
    final rightW = center + 2.5;

    final leftLabel = hasAi ? 'Seguro' : '-2.5';
    final midLabel = hasAi ? 'Ideal' : (center > 0 ? 'Atual' : 'Peso');
    final rightLabel = hasAi ? 'Progredir' : '+2.5';

    final serieHuman = allDone
        ? 'Concluído'
        : '${_serieOrdinal(seriesIdx + 1)} série';

    final muted = isDark ? AppColors.gray50 : AppColors.gray60;

    if (allDone) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16, assistantEnabled ? 4 : 2, 16, 8),
        child: Text(
          '${exercise.name.toTitleCase()} • todas as séries deste exercício estão concluídas.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: muted,
            height: 1.4,
            fontSize: 12,
          ),
        ),
      );
    }

    final headerLine = '${exercise.name.toTitleCase()} • $serieHuman';
    final weightSummary = _fmtWeightKg(center);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        assistantEnabled ? 6 : 4,
        16,
        _suggestionsMinimized ? 8 : 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  headerLine,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    height: 1.25,
                    color: isDark ? Colors.white : AppColors.gray90,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_suggestionsMinimized) ...[
                const SizedBox(width: 8),
                Text(
                  weightSummary,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
              ],
              IconButton(
                tooltip: _suggestionsMinimized
                    ? 'Mostrar sugestões de carga'
                    : 'Ocultar sugestões de carga',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(
                    () => _suggestionsMinimized = !_suggestionsMinimized,
                  );
                },
                icon: Icon(
                  _suggestionsMinimized ? Icons.expand_more : Icons.expand_less,
                  color: isDark ? AppColors.gray50 : AppColors.gray60,
                ),
              ),
            ],
          ),
          if (!assistantEnabled && !_suggestionsMinimized) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: muted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Inicie o treino para ativar sugestões de carga e registrar pesos nas séries.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      height: 1.35,
                      color: muted,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (!_suggestionsMinimized) ...[
            const SizedBox(height: 10),
            IgnorePointer(
              ignoring: !assistantEnabled,
              child: Opacity(
                opacity: assistantEnabled ? 1.0 : 0.5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _microBtn(
                          icon: Icons.remove,
                          decrement: true,
                          onTap: () {
                            setState(() {
                              _selectedWeight = (_selectedWeight - 1.25).clamp(
                                0.0,
                                double.infinity,
                              );
                            });
                          },
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _wChip(
                            weight: leftW,
                            sublabel: leftLabel,
                            isMain: false,
                            isDark: isDark,
                            primary: primary,
                            onTap: () {
                              setState(() => _selectedWeight = leftW);
                              _applyWeightToCurrentSeries(
                                exercise,
                                seriesIdx,
                                silent: true,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: _wChip(
                            weight: center,
                            sublabel: midLabel,
                            isMain: true,
                            isDark: isDark,
                            primary: primary,
                            onTap: () {
                              setState(() => _selectedWeight = center);
                              _applyWeightToCurrentSeries(
                                exercise,
                                seriesIdx,
                                silent: true,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _wChip(
                            weight: rightW,
                            sublabel: rightLabel,
                            isMain: false,
                            isDark: isDark,
                            primary: primary,
                            onTap: () {
                              setState(() => _selectedWeight = rightW);
                              _applyWeightToCurrentSeries(
                                exercise,
                                seriesIdx,
                                silent: true,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        _microBtn(
                          icon: Icons.add,
                          decrement: false,
                          onTap: () {
                            setState(() => _selectedWeight += 1.25);
                          },
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Escolha entre carga segura, ideal ou progressão. Use − / + para micro ajustes rápidos.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        height: 1.35,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _serieOrdinal(int n) {
    if (n <= 0) return '$n';
    if (n == 1) return '1º';
    if (n == 2) return '2º';
    if (n == 3) return '3º';
    return '$nº';
  }

  void _applyWeightToCurrentSeries(
    WorkoutExercise exercise,
    int seriesIndex, {
    bool silent = false,
  }) {
    if (!widget.workoutStarted) return;
    if (_allSeriesDoneFor(exercise)) return;
    final weightStr = _selectedWeight % 1 == 0
        ? _selectedWeight.toInt().toString()
        : _selectedWeight.toStringAsFixed(1);
    final repsStr = _selectedReps > 0
        ? _selectedReps.toString()
        : exercise.reps;

    final currentEntries = List<SeriesEntry>.from(exercise.entries);
    while (currentEntries.length <= seriesIndex) {
      currentEntries.add(
        SeriesEntry(index: currentEntries.length, weight: '', reps: ''),
      );
    }

    currentEntries[seriesIndex] = currentEntries[seriesIndex].copyWith(
      weight: weightStr,
      reps: repsStr,
    );

    final updated = exercise.copyWith(
      entries: currentEntries,
      weight: weightStr,
      series: currentEntries.length > exercise.series
          ? currentEntries.length
          : exercise.series,
    );

    final notifier = ref.read(workoutDayExercisesProvider.notifier);
    final mode = ref.read(workoutScreenModeProvider);
    switch (mode) {
      case WorkoutScreenMode.execution:
        notifier.updateExerciseExecution(exercise.id, updated);
        break;
      case WorkoutScreenMode.template:
        notifier.updateExerciseTemplate(exercise.id, updated);
        break;
      case WorkoutScreenMode.editing:
        notifier.updateExerciseLog(exercise.id, updated);
        break;
      default:
        // ignore: deprecated_member_use_from_same_package
        notifier.updateExercise(exercise.id, updated);
    }

    if (!silent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Série ${seriesIndex + 1}: $weightStr kg × $repsStr reps',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Widget _microBtn({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    required bool decrement,
  }) {
    final accent = decrement ? AppColors.error : AppColors.success;
    final bg = accent.withOpacity(isDark ? 0.32 : 0.16);
    final border = accent.withOpacity(isDark ? 0.45 : 0.35);
    final iconColor = isDark ? Colors.white : accent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }

  Widget _wChip({
    required double weight,
    required String sublabel,
    required bool isMain,
    required bool isDark,
    required Color primary,
    required VoidCallback onTap,
  }) {
    final isSelected = _selectedWeight == weight;
    final fillUnselected = isDark ? AppColors.dark50 : Colors.grey.shade100;
    final borderUnselected = isDark ? AppColors.dark50 : Colors.grey.shade300;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(vertical: isMain ? 8 : 7, horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withOpacity(isDark ? 0.22 : 0.14)
              : fillUnselected,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? primary.withOpacity(0.55) : borderUnselected,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _fmtWeightKg(weight),
              style: TextStyle(
                fontSize: isMain ? 15 : 14,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: isSelected
                    ? primary
                    : (isDark ? Colors.white70 : AppColors.gray90),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? primary.withOpacity(0.85)
                    : (isDark ? AppColors.gray50 : AppColors.gray60),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Action buttons ─────────────────────────────────────────────────

  Widget _buildActions(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: widget.isManual
          ? _buildManualAction(theme, isDark)
          : widget.workoutStarted
          ? _buildWorkoutStartedActions(theme, isDark)
          : _buildDefaultActions(theme, isDark),
    );
  }

  Widget _buildManualAction(ThemeData theme, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: widget.isLoading ? null : widget.onFinishWorkout,
        icon: widget.isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_alt, size: 20),
        label: widget.isLoading
            ? const SizedBox.shrink()
            : const Text('Salvar Treino'),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildWorkoutStartedActions(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              key: WorkoutTestKeys.finishWorkout,
              onPressed: widget.isLoading ? null : widget.onFinishWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Finalizar Treino',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 50,
          height: 50,
          child: OutlinedButton(
            onPressed: widget.isLoading ? null : _showDiscardConfirmation,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              side: BorderSide(
                color: isDark
                    ? AppColors.error.withOpacity(0.3)
                    : AppColors.error.withOpacity(0.2),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Icon(Icons.close, size: 20, color: AppColors.error),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultActions(ThemeData theme, bool isDark) {
    final borderColor = isDark ? AppColors.dark40 : Colors.grey.shade300;
    const double h = 48;
    return Row(
      children: [
        Tooltip(
          message: 'Salvar rascunho',
          child: SizedBox(
            width: 44,
            height: h,
            child: OutlinedButton(
              onPressed: widget.isLoading ? null : widget.onSaveTrain,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: BorderSide(color: borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: widget.isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? AppColors.gray50 : AppColors.gray60,
                      ),
                    )
                  : Icon(
                      Icons.bookmark_outline,
                      size: 22,
                      color: isDark ? AppColors.gray40 : AppColors.gray70,
                    ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: h,
            child: ElevatedButton(
              key: WorkoutTestKeys.startWorkout,
              onPressed: widget.isLoading ? null : widget.onStartWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded, size: 22),
                        SizedBox(width: 6),
                        Text(
                          'Iniciar treino',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        if (widget.onMoreOptions != null) ...[
          const SizedBox(width: 8),
          Tooltip(
            message: 'Mais opções',
            child: SizedBox(
              width: 44,
              height: h,
              child: OutlinedButton(
                onPressed: widget.isLoading ? null : widget.onMoreOptions,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Icon(
                  Icons.more_horiz,
                  size: 22,
                  color: isDark ? AppColors.gray40 : AppColors.gray70,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Discard confirmation ───────────────────────────────────────────

  void _showDiscardConfirmation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.gray50 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
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

  String _fmtWeightKg(double w) {
    if (w % 1 == 0) return '${w.toInt()} kg';
    return '${w.toStringAsFixed(1)} kg';
  }
}
