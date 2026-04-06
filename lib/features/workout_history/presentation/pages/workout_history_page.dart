import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/home/components/organisms/session_picker_sheet.dart';
import 'package:iron_log/features/home/state/home_provider.dart';
import 'package:iron_log/features/routines/domain/entities/routine.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_summary.dart';
import 'package:iron_log/features/workout_day/presentation/pages/workout_day_screen.dart';
import 'package:iron_log/features/workout_history/presentation/components/atoms/history_month_header.dart';
import 'package:iron_log/features/workout_history/presentation/components/molecules/history_filter_tabs.dart';
import 'package:iron_log/features/workout_history/presentation/components/molecules/workout_history_card.dart';
import 'package:iron_log/features/workout_history/presentation/components/organisms/workout_detail_sheet.dart';
import 'package:iron_log/features/workout_history/presentation/providers/history_filter_provider.dart';
import 'package:iron_log/features/workout_history/presentation/providers/workout_history_provider.dart';
import 'package:iron_log/core/routes/app_router.dart';

// ── Data model for a grouped list section ──────────────────────────────────
class _HistoryGroup {
  final String monthLabel;
  final int workoutCount;
  final double totalVolume;
  final List<WorkoutHistory> items;

  const _HistoryGroup({
    required this.monthLabel,
    required this.workoutCount,
    required this.totalVolume,
    required this.items,
  });
}

// ── Helper ──────────────────────────────────────────────────────────────────
List<WorkoutHistory> _applyFilter(List<WorkoutHistory> all, String filter) {
  final now = DateTime.now();
  return all.where((w) {
    if (filter == 'week') {
      final weekAgo = now.subtract(const Duration(days: 7));
      return w.date.isAfter(weekAgo);
    }
    if (filter == 'month') {
      return w.date.month == now.month && w.date.year == now.year;
    }
    return true;
  }).toList();
}

List<_HistoryGroup> _groupByMonth(List<WorkoutHistory> workouts) {
  const monthNames = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  final Map<String, List<WorkoutHistory>> map = {};
  for (final w in workouts) {
    final key = '${monthNames[w.date.month - 1]} ${w.date.year}';
    map.putIfAbsent(key, () => []).add(w);
  }

  return map.entries.map((entry) {
    final vol = entry.value.fold<double>(0, (acc, w) => acc + w.totalVolume);
    return _HistoryGroup(
      monthLabel: entry.key,
      workoutCount: entry.value.length,
      totalVolume: vol,
      items: entry.value,
    );
  }).toList();
}

// ── Page ────────────────────────────────────────────────────────────────────
class WorkoutHistoryPage extends ConsumerStatefulWidget {
  const WorkoutHistoryPage({super.key});

  @override
  ConsumerState<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends ConsumerState<WorkoutHistoryPage>
    with WidgetsBindingObserver, RouteAware {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.refresh(workoutHistoryProvider);
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modal = ModalRoute.of(context);
    if (modal != null) routeObserver.subscribe(this, modal);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didPopNext() => ref.refresh(workoutHistoryProvider);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed)
      ref.invalidate(workoutHistoryProvider);
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(workoutHistoryProvider);
    final filter = ref.watch(historyFilterProvider);

    return Scaffold(
      body: historyAsync.when(
        loading: () => CustomScrollView(
          slivers: [
            _buildAppBar(context, null, filter),
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
        error: (e, _) => CustomScrollView(
          slivers: [
            _buildAppBar(context, null, filter),
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Não foi possível carregar o histórico.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(workoutHistoryProvider),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        data: (allWorkouts) {
          final filtered = _applyFilter(allWorkouts, filter);
          final groups = _groupByMonth(filtered);

          // Flatten groups into a linear list of items:
          // Each group = 1 header + N cards
          final flatItems = <dynamic>[];
          for (final g in groups) {
            flatItems.add(g); // header
            flatItems.addAll(g.items); // cards
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(workoutHistoryProvider),
            child: CustomScrollView(
              slivers: [
                _buildAppBar(context, filtered.length, filter),
                // Filter tabs (non-sticky — avoids SliverPersistentHeader
                // layout issues with floating SliverAppBar)
                const SliverToBoxAdapter(child: HistoryFilterTabs()),
                if (flatItems.isEmpty)
                  SliverFillRemaining(child: _EmptyState(filter: filter))
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = flatItems[index];
                      if (item is _HistoryGroup) {
                        return HistoryMonthHeader(
                          monthLabel: item.monthLabel,
                          workoutCount: item.workoutCount,
                          totalVolume: item.totalVolume,
                        );
                      }
                      final workout = item as WorkoutHistory;
                      return WorkoutHistoryCard(
                        workout: workout,
                        onTap: () => WorkoutDetailSheet.show(
                          context,
                          workout,
                          onEdit: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => WorkoutDayScreen(
                                workoutId: workout.id,
                                subtitle:
                                    workout.sessionName ?? workout.routineName,
                                manualDate: workout.date,
                              ),
                            ),
                          ),
                        ),
                      );
                    }, childCount: flatItems.length),
                  ),
                // Bottom padding for FAB
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _registerPastWorkout(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Registrar treino passado'),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, int? count, String filter) {
    return SliverAppBar(
      floating: true,
      snap: true,
      title: const Text('Histórico'),
      centerTitle: false,
      actions: [
        if (count != null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$count treino${count != 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _registerPastWorkout(BuildContext context, WidgetRef ref) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().subtract(const Duration(days: 1)),
      helpText: 'Quando foi este treino?',
    );

    if (picked == null || !context.mounted) return;

    final homeState = ref.read(homeProvider);
    final routine = homeState.todaysRoutine;
    final routineId = routine?.id;

    // Quando a rotina tem mais de uma sessão, pede ao usuário escolher qual fez
    Session? selectedSession = homeState.todaysSession;
    if (routine != null && routine.sessions.length > 1) {
      selectedSession = await SessionPickerSheet.show(
        context,
        sessions: routine.sessions,
        currentSession: homeState.todaysSession,
        // noop: neste fluxo a sessão é capturada pelo Future retornado pelo show();
        // não altera o estado global da Home
        onSelectSession: (_) {},
      );
      if (selectedSession == null || !context.mounted) return;
    }

    final sessionId = selectedSession?.id;
    final subtitle =
        selectedSession != null && routine != null
        ? '${selectedSession.name} - ${routine.name}'
        : '${picked.day.toString().padLeft(2, '0')}/'
              '${picked.month.toString().padLeft(2, '0')}/${picked.year}';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkoutDayScreen(
          routineId: routineId,
          sessionId: sessionId,
          subtitle: subtitle,
          manualDate: picked,
        ),
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});

  String get _message {
    if (filter == 'week') return 'Nenhum treino esta semana';
    if (filter == 'month') return 'Nenhum treino este mês';
    return 'Nenhum treino registrado';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(_message, style: Theme.of(context).textTheme.titleMedium),
          if (filter == 'all') ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Use o botão abaixo para registrar um treino passado.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
