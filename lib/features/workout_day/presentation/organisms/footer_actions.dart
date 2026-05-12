import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/app_colors.dart';
import 'package:iron_log/core/extensions/string_extensions.dart';
import '../../domain/entities/series_entry.dart';
import '../../domain/entities/workout_exercise.dart';
import '../../domain/entities/suggestion_result.dart';
import '../providers/exercise_suggestion_provider.dart';
import '../providers/exercise_last_sets_provider.dart';
import '../providers/workout_day_provider.dart';
import '../../domain/enums/workout_screen_mode.dart';

class FooterActions extends ConsumerStatefulWidget {
  final VoidCallback? onStartWorkout;
  final VoidCallback? onFinishWorkout;
  final VoidCallback? onDiscard;
  final VoidCallback? onSaveTrain;
  final bool workoutStarted;
  final bool isLoading;
  final bool isManual;
  final int seriesDone;
  final double volumeKg;
  final int completionPercent;
  final List<WorkoutExercise> exercises;

  const FooterActions({
    super.key,
    this.onStartWorkout,
    this.onFinishWorkout,
    this.onDiscard,
    this.onSaveTrain,
    this.workoutStarted = false,
    this.isLoading = false,
    this.isManual = false,
    this.seriesDone = 0,
    this.volumeKg = 0.0,
    this.completionPercent = 0,
    this.exercises = const [],
  });

  @override
  ConsumerState<FooterActions> createState() => _FooterActionsState();
}

class _FooterActionsState extends ConsumerState<FooterActions> {
  double _selectedWeight = 0;
  int _selectedReps = 0;
  bool _weightInitialized = false;
  String? _lastExerciseId;

  WorkoutExercise? get _nextExercise =>
      widget.exercises.isNotEmpty ? widget.exercises.first : null;

  int get _currentSeriesIndex {
    final ex = _nextExercise;
    if (ex == null) return 0;
    final entries = ex.entries;
    if (entries.isEmpty) return 0;
    final idx = entries.indexWhere((e) => !e.done);
    return idx >= 0 ? idx : entries.length;
  }

  int get _totalSeries {
    final ex = _nextExercise;
    if (ex == null) return 0;
    return ex.series > 0 ? ex.series : ex.entries.length;
  }

  bool get _allSeriesDone {
    final ex = _nextExercise;
    if (ex == null) return true;
    if (ex.entries.isEmpty) return false;
    return ex.entries.every((e) => e.done);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Reset weight when exercise changes
    if (_nextExercise != null && _nextExercise!.id != _lastExerciseId) {
      _lastExerciseId = _nextExercise!.id;
      _weightInitialized = false;
      _selectedWeight = 0;
      _selectedReps = 0;
    }

    if (kDebugMode) {
      print('[FooterActions] build() exercises=${widget.exercises.length}, isManual=${widget.isManual}, nextEx=${_nextExercise?.name}');
    }

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
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Container(
                width: 32,
                height: 3.5,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.dark50 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (widget.workoutStarted && !widget.isManual)
              _buildInlineStats(theme, isDark),
            if (!widget.isManual && _nextExercise != null)
              _buildNextExercisePreview(theme, isDark),
            _buildActions(theme, isDark),
          ],
        ),
      ),
    );
  }

  // ─── Inline stats (during workout) ──────────────────────────────────

  Widget _buildInlineStats(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          _miniStat(
            icon: Icons.layers_outlined,
            value: '${widget.seriesDone}',
            label: 'séries',
            color: AppColors.success,
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(width: 8),
          _miniStat(
            icon: Icons.fitness_center,
            value: '${widget.volumeKg.toStringAsFixed(0)}kg',
            label: 'volume',
            color: AppColors.blue60,
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(width: 8),
          _miniStat(
            icon: Icons.pie_chart_outline,
            value: '${widget.completionPercent}%',
            label: 'feito',
            color: AppColors.warning,
            isDark: isDark,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _miniStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
    required ThemeData theme,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.08 : 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.gray90,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: isDark ? AppColors.gray50 : AppColors.gray60,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Next exercise preview + weight picker (always visible) ──────────

  Widget _buildNextExercisePreview(ThemeData theme, bool isDark) {
    final exercise = _nextExercise!;
    final seriesIdx = _currentSeriesIndex;
    final total = _totalSeries;
    final allDone = _allSeriesDone;

    final suggestionAsync = ref.watch(exerciseSuggestionProvider(exercise.id));
    final historyAsync = ref.watch(exerciseLastSetsProvider(exercise.id));
    final lastSets = historyAsync.asData?.value;
    final suggestion = suggestionAsync.asData?.value;

    // Initialize weight from: AI suggestion > last history > exercise weight > 0
    if (!_weightInitialized) {
      double initial = 0;
      int initialReps = 0;

      if (suggestion != null && suggestion.hasData) {
        initial = suggestion.suggestedWeight;
        initialReps = suggestion.suggestedReps ?? 0;
      } else if (lastSets != null &&
          lastSets.hasHistory &&
          lastSets.sets.isNotEmpty) {
        initial = lastSets.sets.first.weight ?? 0;
        initialReps = lastSets.sets.first.reps ?? 0;
      } else {
        final wStr = exercise.weight.replaceAll(RegExp(r'[^0-9.]'), '');
        initial = double.tryParse(wStr) ?? 0;
        initialReps = int.tryParse(exercise.reps.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      }

      if (initial > 0 || (suggestion != null && !suggestionAsync.isLoading)) {
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.dark40 : AppColors.gray10,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppColors.dark50.withOpacity(0.5)
                : Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Exercise header row ──
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: exercise.tag.color.withOpacity(isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      exercise.name.isNotEmpty
                          ? exercise.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: exercise.tag.color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: allDone
                                  ? AppColors.success.withOpacity(0.1)
                                  : theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              allDone ? 'CONCLUÍDO' : 'PRÓXIMO',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: allDone
                                    ? AppColors.success
                                    : theme.colorScheme.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: exercise.tag.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              exercise.tag.label,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: exercise.tag.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        exercise.name.toTitleCase(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (lastSets != null && lastSets.hasHistory)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.dark30 : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? AppColors.dark50 : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history,
                          size: 12,
                          color: isDark ? AppColors.gray50 : AppColors.gray60,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          lastSets.sets.isNotEmpty
                              ? lastSets.sets.first.displayText
                              : '—',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : AppColors.gray80,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Series indicator dots + AI badge ──
            Row(
              children: [
                ...List.generate(total > 0 ? total : 1, (i) {
                  final isDone = exercise.entries.length > i &&
                      exercise.entries[i].done;
                  final isCurrent = i == seriesIdx && !allDone;
                  return Container(
                    width: isCurrent ? 22 : 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.success
                          : isCurrent
                              ? theme.colorScheme.primary
                              : isDark
                                  ? AppColors.dark50
                                  : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
                const SizedBox(width: 6),
                Text(
                  allDone
                      ? 'Todas as séries feitas'
                      : 'Série ${seriesIdx + 1} de ${total > 0 ? total : '?'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.gray80,
                  ),
                ),
                const Spacer(),
                if (suggestion != null && suggestion.hasData)
                  _buildActionBadge(suggestion.action, isDark)
                else if (suggestionAsync.isLoading)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Weight picker row (always visible) ──
            Row(
              children: [
                _microBtn(
                  icon: Icons.remove,
                  onTap: () {
                    setState(() {
                      _selectedWeight =
                          (_selectedWeight - 1.25).clamp(0.0, double.infinity);
                    });
                  },
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                if (suggestion != null && suggestion.hasData) ...[
                  _wChip(
                    weight: (suggestion.suggestedWeight - 2.5)
                        .clamp(0.0, double.infinity),
                    label: 'Seguro',
                    color: AppColors.success,
                    isDark: isDark,
                    theme: theme,
                  ),
                  const SizedBox(width: 5),
                  _wChip(
                    weight: suggestion.suggestedWeight,
                    label: 'Ideal',
                    color: theme.colorScheme.primary,
                    isDark: isDark,
                    theme: theme,
                    isMain: true,
                  ),
                  const SizedBox(width: 5),
                  _wChip(
                    weight: suggestion.suggestedWeight + 2.5,
                    label: 'Progredir',
                    color: AppColors.warning,
                    isDark: isDark,
                    theme: theme,
                  ),
                ] else ...[
                  _wChip(
                    weight: (_selectedWeight - 2.5).clamp(0.0, double.infinity),
                    label: '-2.5',
                    color: AppColors.success,
                    isDark: isDark,
                    theme: theme,
                  ),
                  const SizedBox(width: 5),
                  _wChip(
                    weight: _selectedWeight,
                    label: _selectedWeight > 0 ? 'Atual' : 'Peso',
                    color: theme.colorScheme.primary,
                    isDark: isDark,
                    theme: theme,
                    isMain: true,
                  ),
                  const SizedBox(width: 5),
                  _wChip(
                    weight: _selectedWeight + 2.5,
                    label: '+2.5',
                    color: AppColors.warning,
                    isDark: isDark,
                    theme: theme,
                  ),
                ],
                const SizedBox(width: 6),
                _microBtn(
                  icon: Icons.add,
                  onTap: () {
                    setState(() => _selectedWeight += 1.25);
                  },
                  isDark: isDark,
                ),
              ],
            ),

            // ── Apply button ──
            if (!allDone) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 34,
                child: OutlinedButton(
                  onPressed: () => _applyWeightToCurrentSeries(exercise),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Aplicar ${_fmtWeight(_selectedWeight)} na série ${seriesIdx + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _applyWeightToCurrentSeries(WorkoutExercise exercise) {
    final seriesIdx = _currentSeriesIndex;
    final weightStr = _selectedWeight % 1 == 0
        ? _selectedWeight.toInt().toString()
        : _selectedWeight.toStringAsFixed(1);
    final repsStr =
        _selectedReps > 0 ? _selectedReps.toString() : exercise.reps;

    final currentEntries = List<SeriesEntry>.from(exercise.entries);
    while (currentEntries.length <= seriesIdx) {
      currentEntries.add(
        SeriesEntry(
          index: currentEntries.length,
          weight: '',
          reps: '',
        ),
      );
    }

    currentEntries[seriesIdx] = currentEntries[seriesIdx].copyWith(
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
      case WorkoutScreenMode.template:
        notifier.updateExerciseTemplate(exercise.id, updated);
      case WorkoutScreenMode.editing:
        notifier.updateExerciseLog(exercise.id, updated);
      default:
        // ignore: deprecated_member_use_from_same_package
        notifier.updateExercise(exercise.id, updated);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Série ${seriesIdx + 1}: $weightStr kg × $repsStr reps',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.success,
        ),
      );
    }

    if (kDebugMode) {
      print('[FooterActions] Applied $weightStr kg to series ${seriesIdx + 1} of ${exercise.name}');
    }
  }

  Widget _buildActionBadge(SuggestionAction action, bool isDark) {
    final (icon, label, color) = switch (action) {
      SuggestionAction.increase => (
        Icons.trending_up,
        'Subir',
        AppColors.success,
      ),
      SuggestionAction.decrease => (
        Icons.trending_down,
        'Reduzir',
        AppColors.error,
      ),
      SuggestionAction.maintain => (
        Icons.trending_flat,
        'Manter',
        AppColors.blue60,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _microBtn({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isDark ? AppColors.dark50 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isDark ? AppColors.gray40 : AppColors.gray60,
        ),
      ),
    );
  }

  Widget _wChip({
    required double weight,
    required String label,
    required Color color,
    required bool isDark,
    required ThemeData theme,
    bool isMain = false,
  }) {
    final isSelected = _selectedWeight == weight;
    return Expanded(
      flex: isMain ? 3 : 2,
      child: GestureDetector(
        onTap: () => setState(() => _selectedWeight = weight),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            vertical: isMain ? 8 : 6,
            horizontal: 2,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(isDark ? 0.18 : 0.1)
                : isDark
                    ? AppColors.dark50.withOpacity(0.4)
                    : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? color.withOpacity(0.5)
                  : isDark
                      ? AppColors.dark50
                      : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                _fmtWeight(weight),
                style: TextStyle(
                  fontSize: isMain ? 14 : 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? color
                      : isDark
                          ? Colors.white70
                          : AppColors.gray80,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? color.withOpacity(0.8)
                      : isDark
                          ? AppColors.gray50
                          : AppColors.gray60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Action buttons ─────────────────────────────────────────────────

  Widget _buildActions(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
    return Row(
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: OutlinedButton(
            onPressed: widget.isLoading ? null : widget.onSaveTrain,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              side: BorderSide(
                color: isDark ? AppColors.dark40 : Colors.grey.shade300,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: widget.isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDark ? AppColors.gray50 : AppColors.gray60,
                    ),
                  )
                : Icon(
                    Icons.bookmark_outline,
                    size: 20,
                    color: isDark ? AppColors.gray40 : AppColors.gray60,
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : widget.onStartWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
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
                        Icon(Icons.play_arrow_rounded, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Iniciar Treino',
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
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
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

  String _fmtWeight(double w) {
    if (w % 1 == 0) return '${w.toInt()}kg';
    return '${w.toStringAsFixed(1)}kg';
  }
}
