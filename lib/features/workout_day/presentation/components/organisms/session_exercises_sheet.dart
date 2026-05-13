import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/app_colors.dart';
import 'package:iron_log/core/extensions/string_extensions.dart';
import '../../../domain/entities/workout_exercise.dart';
import '../../../domain/entities/suggestion_result.dart';
import '../../organisms/exercise_card.dart';
import '../../providers/exercise_suggestion_provider.dart';
import '../../providers/exercise_last_sets_provider.dart';

class SessionExercisesSheet extends ConsumerStatefulWidget {
  final List<WorkoutExercise> exercises;
  final String? sessionId;
  final String? sessionName;
  final Function(int oldIndex, int newIndex) onReorder;
  final VoidCallback onStartWorkout;
  final VoidCallback? onSaveDraft;
  final bool workoutStarted;
  final bool isLoading;

  const SessionExercisesSheet({
    super.key,
    required this.exercises,
    required this.onReorder,
    required this.onStartWorkout,
    this.onSaveDraft,
    this.sessionId,
    this.sessionName,
    this.workoutStarted = false,
    this.isLoading = false,
  });

  static Future<void> show(
    BuildContext context, {
    required List<WorkoutExercise> exercises,
    required Function(int oldIndex, int newIndex) onReorder,
    required VoidCallback onStartWorkout,
    VoidCallback? onSaveDraft,
    String? sessionId,
    String? sessionName,
    bool workoutStarted = false,
    bool isLoading = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SessionExercisesSheet(
        exercises: exercises,
        onReorder: onReorder,
        onStartWorkout: onStartWorkout,
        onSaveDraft: onSaveDraft,
        sessionId: sessionId,
        sessionName: sessionName,
        workoutStarted: workoutStarted,
        isLoading: isLoading,
      ),
    );
  }

  @override
  ConsumerState<SessionExercisesSheet> createState() =>
      _SessionExercisesSheetState();
}

class _SessionExercisesSheetState extends ConsumerState<SessionExercisesSheet> {
  static const double _sheetMin = 0.34;
  static const double _sheetMax = 0.92;

  late final DraggableScrollableController _sheetCtrl;

  double _selectedWeight = 0;
  bool _showExerciseList = false;

  WorkoutExercise? get _nextExercise =>
      widget.exercises.isNotEmpty ? widget.exercises.first : null;

  @override
  void initState() {
    super.initState();
    _sheetCtrl = DraggableScrollableController();
  }

  @override
  void dispose() {
    _sheetCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SessionExercisesSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.workoutStarted &&
        !oldWidget.workoutStarted &&
        _sheetCtrl.isAttached) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _sheetCtrl.isAttached) {
          _sheetCtrl.animateTo(
            _sheetMax,
            duration: const Duration(milliseconds: 340),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  void _toggleSheetExtent() {
    if (!_sheetCtrl.isAttached) return;
    final s = _sheetCtrl.size;
    final mid = (_sheetMin + _sheetMax) / 2;
    final target = s < mid ? _sheetMax : _sheetMin;
    _sheetCtrl.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _setShowExerciseList(bool value) {
    setState(() => _showExerciseList = value);
    if (value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _sheetCtrl.isAttached) {
          _sheetCtrl.animateTo(
            _sheetMax,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final initial =
        widget.workoutStarted ? _sheetMax : _sheetMin;

    return DraggableScrollableSheet(
      controller: _sheetCtrl,
      initialChildSize: initial,
      minChildSize: _sheetMin,
      maxChildSize: _sheetMax,
      snap: true,
      snapSizes: const [_sheetMin, _sheetMax],
      expand: true,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.5 : 0.08),
                blurRadius: 32,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleSheetExtent,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildHandle(isDark),
                ),
              ),
              _buildHeader(theme, isDark),
              const SizedBox(height: 4),
              Expanded(
                child: _showExerciseList
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildShowListToggle(theme, isDark),
                          const SizedBox(height: 8),
                          Expanded(
                            child: _buildExerciseList(
                              isDark,
                              scrollController,
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        controller: scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildSessionStats(theme, isDark),
                              const SizedBox(height: 16),
                              if (_nextExercise != null) ...[
                                _buildNextExerciseCard(theme, isDark),
                                const SizedBox(height: 16),
                                _buildAiSuggestion(theme, isDark),
                              ],
                              const SizedBox(height: 24),
                              _buildShowListToggle(theme, isDark),
                            ],
                          ),
                        ),
                      ),
              ),
              _buildFooter(theme, isDark),
            ],
          ),
        );
      },
    );
  }

  // ─── Handle ─────────────────────────────────────────────────────────

  Widget _buildHandle(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: isDark ? AppColors.dark50 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────

  Widget _buildHeader(ThemeData theme, bool isDark) {
    final name = widget.sessionName ?? 'Sua sessão';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.exercises.length} exercício${widget.exercises.length != 1 ? 's' : ''} · ${_estimateTime()} min',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.gray50 : AppColors.gray60,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_horiz,
              color: isDark ? AppColors.gray40 : AppColors.gray60,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'save') widget.onSaveDraft?.call();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'save',
                child: Row(
                  children: [
                    Icon(Icons.save_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Salvar rascunho'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Session quick stats ────────────────────────────────────────────

  Widget _buildSessionStats(ThemeData theme, bool isDark) {
    final totalSeries = widget.exercises.fold<int>(
      0,
      (sum, ex) => sum + ex.series,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _statChip(
            icon: Icons.fitness_center,
            label: '${widget.exercises.length}',
            sub: 'exercícios',
            color: AppColors.blue60,
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(width: 10),
          _statChip(
            icon: Icons.layers_outlined,
            label: '$totalSeries',
            sub: 'séries',
            color: AppColors.success,
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(width: 10),
          _statChip(
            icon: Icons.timer_outlined,
            label: '~${_estimateTime()}',
            sub: 'min',
            color: AppColors.warning,
            isDark: isDark,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _statChip({
    required IconData icon,
    required String label,
    required String sub,
    required Color color,
    required bool isDark,
    required ThemeData theme,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark
              ? color.withOpacity(0.08)
              : color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withOpacity(isDark ? 0.15 : 0.12),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.gray90,
                    ),
                  ),
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.gray50 : AppColors.gray60,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Next exercise card ─────────────────────────────────────────────

  Widget _buildNextExerciseCard(ThemeData theme, bool isDark) {
    final exercise = _nextExercise!;
    final historyAsync = ref.watch(exerciseLastSetsProvider(exercise.id));
    final lastSets = historyAsync.asData?.value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.dark40 : AppColors.gray10,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? AppColors.dark50.withOpacity(0.5)
                : Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'PRÓXIMO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: exercise.tag.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    exercise.tag.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: exercise.tag.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              exercise.name.toTitleCase(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              exercise.muscles,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.gray50 : AppColors.gray60,
              ),
            ),
            if (lastSets != null && lastSets.hasHistory) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.dark30.withOpacity(0.6)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.dark50 : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      size: 14,
                      color: isDark ? AppColors.gray50 : AppColors.gray60,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Último treino: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.gray50 : AppColors.gray60,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        lastSets.sets
                            .take(3)
                            .map((s) => s.displayText)
                            .join(' · '),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : AppColors.gray80,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── AI suggestion with weight picker ───────────────────────────────

  Widget _buildAiSuggestion(ThemeData theme, bool isDark) {
    final exercise = _nextExercise!;
    final suggestionAsync = ref.watch(
      exerciseSuggestionProvider(exercise.id),
    );

    return suggestionAsync.when(
      data: (suggestion) {
        if (!suggestion.hasData) return const SizedBox.shrink();

        final base = suggestion.suggestedWeight;
        if (_selectedWeight == 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedWeight = base);
          });
        }

        final conservative = (base - 2.5).clamp(0.0, double.infinity);
        final aggressive = base + 2.5;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        AppColors.primaryDark.withOpacity(0.06),
                        AppColors.primaryDark.withOpacity(0.02),
                      ]
                    : [
                        AppColors.blue10.withOpacity(0.5),
                        AppColors.blue10.withOpacity(0.2),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? AppColors.primaryDark.withOpacity(0.12)
                    : AppColors.blue20,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sugestão para Série 1',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (suggestion.explanation.isNotEmpty)
                            Text(
                              suggestion.explanation,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.gray50
                                    : AppColors.gray60,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    _buildActionBadge(suggestion.action, isDark),
                  ],
                ),
                const SizedBox(height: 16),
                // Weight suggestion row
                Row(
                  children: [
                    _microAdjustButton(
                      icon: Icons.remove,
                      onTap: () {
                        setState(() {
                          _selectedWeight = (_selectedWeight - 1.25)
                              .clamp(0.0, double.infinity);
                        });
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          _weightChip(
                            weight: conservative,
                            label: 'Seguro',
                            isSelected: _selectedWeight == conservative,
                            color: AppColors.success,
                            isDark: isDark,
                            theme: theme,
                          ),
                          const SizedBox(width: 6),
                          _weightChip(
                            weight: base,
                            label: 'Ideal',
                            isSelected: _selectedWeight == base,
                            color: theme.colorScheme.primary,
                            isDark: isDark,
                            theme: theme,
                            isMain: true,
                          ),
                          const SizedBox(width: 6),
                          _weightChip(
                            weight: aggressive,
                            label: 'Progredir',
                            isSelected: _selectedWeight == aggressive,
                            color: AppColors.warning,
                            isDark: isDark,
                            theme: theme,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _microAdjustButton(
                      icon: Icons.add,
                      onTap: () {
                        setState(() => _selectedWeight += 1.25);
                      },
                      isDark: isDark,
                    ),
                  ],
                ),
                if (suggestion.suggestedReps != null) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      '${suggestion.suggestedReps} reps recomendadas',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.gray50 : AppColors.gray60,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.dark40 : AppColors.gray10,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Analisando seu histórico...',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.gray50 : AppColors.gray60,
                ),
              ),
            ],
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _microAdjustButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? AppColors.dark50 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isDark ? AppColors.gray40 : AppColors.gray60,
        ),
      ),
    );
  }

  Widget _weightChip({
    required double weight,
    required String label,
    required bool isSelected,
    required Color color,
    required bool isDark,
    required ThemeData theme,
    bool isMain = false,
  }) {
    return Expanded(
      flex: isMain ? 3 : 2,
      child: GestureDetector(
        onTap: () => setState(() => _selectedWeight = weight),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            vertical: isMain ? 10 : 8,
            horizontal: 4,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(isDark ? 0.2 : 0.12)
                : isDark
                    ? AppColors.dark50.withOpacity(0.5)
                    : Colors.white,
            borderRadius: BorderRadius.circular(12),
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
                _formatWeight(weight),
                style: TextStyle(
                  fontSize: isMain ? 16 : 14,
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
                  fontSize: 9,
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

  // ─── Toggle exercise list ───────────────────────────────────────────

  Widget _buildShowListToggle(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () => _setShowExerciseList(!_showExerciseList),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.dark40 : AppColors.gray10,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _showExerciseList
                    ? Icons.auto_awesome
                    : Icons.list_alt_rounded,
                size: 16,
                color: isDark ? AppColors.gray50 : AppColors.gray60,
              ),
              const SizedBox(width: 8),
              Text(
                _showExerciseList
                    ? 'Ver sugestões'
                    : 'Ver todos os exercícios (${widget.exercises.length})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.gray40 : AppColors.gray70,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _showExerciseList
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 18,
                color: isDark ? AppColors.gray50 : AppColors.gray60,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Exercise list ──────────────────────────────────────────────────

  Widget _buildExerciseList(bool isDark, ScrollController scrollController) {
    if (widget.exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 48,
              color: isDark ? AppColors.gray50 : Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhum exercício adicionado',
              style: TextStyle(
                color: isDark ? AppColors.gray50 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      scrollController: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onReorder: (oldIndex, newIndex) {
        if (oldIndex >= widget.exercises.length) return;
        var targetIndex = newIndex;
        if (targetIndex > widget.exercises.length) {
          targetIndex = widget.exercises.length;
        }
        if (targetIndex > oldIndex) targetIndex -= 1;
        if (targetIndex == oldIndex) return;
        widget.onReorder(oldIndex, targetIndex);
      },
      itemCount: widget.exercises.length,
      itemBuilder: (context, index) {
        final exercise = widget.exercises[index];
        return Container(
          key: ValueKey(exercise.id),
          margin: const EdgeInsets.only(bottom: 16),
          child: ExerciseCard(
            exercise: exercise,
            index: index,
            sessionId: widget.sessionId,
          ),
        );
      },
    );
  }

  // ─── Footer with CTAs ──────────────────────────────────────────────

  Widget _buildFooter(ThemeData theme, bool isDark) {
    final primaryLabel = widget.workoutStarted
        ? 'Finalizar treino'
        : 'Iniciar treino';
    final primaryIcon = widget.workoutStarted
        ? Icons.check_circle_outline
        : Icons.play_arrow_rounded;
    final primaryColor = widget.workoutStarted
        ? AppColors.success
        : theme.colorScheme.primary;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.dark40.withOpacity(0.5)
                : Colors.grey.shade100,
          ),
        ),
      ),
      child: Row(
        children: [
          if (widget.onSaveDraft != null) ...[
            SizedBox(
              height: 52,
              width: 52,
              child: OutlinedButton(
                onPressed: widget.isLoading ? null : widget.onSaveDraft,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  side: BorderSide(
                    color: isDark ? AppColors.dark40 : Colors.grey.shade300,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Icon(
                  Icons.bookmark_outline,
                  size: 20,
                  color: isDark ? AppColors.gray40 : AppColors.gray60,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: widget.isLoading ? null : widget.onStartWorkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
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
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(primaryIcon, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            primaryLabel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  int _estimateTime() {
    final totalSeries = widget.exercises.fold<int>(
      0,
      (sum, ex) => sum + (ex.series > 0 ? ex.series : 3),
    );
    return (totalSeries * 2.5).round();
  }

  String _formatWeight(double weight) {
    if (weight % 1 == 0) return '${weight.toInt()}kg';
    return '${weight.toStringAsFixed(1)}kg';
  }
}
