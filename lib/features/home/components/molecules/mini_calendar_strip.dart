import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/app_colors.dart';
import 'package:iron_log/features/home/state/rest_day_toggle_provider.dart';
import 'package:iron_log/features/home/state/workout_calendar_provider.dart';

/// Mini calendário horizontal dos últimos 14 dias com scroll.
/// - Verde   → dia com treino registrado
/// - Azul    → hoje
/// - Laranja → dia de descanso intencional (marcado pelo usuário)
/// - Cinza   → dia sem registro (toque para marcar como descanso)
class MiniCalendarStrip extends ConsumerStatefulWidget {
  const MiniCalendarStrip({super.key});

  @override
  ConsumerState<MiniCalendarStrip> createState() => _MiniCalendarStripState();
}

class _MiniCalendarStripState extends ConsumerState<MiniCalendarStrip> {
  static const int _days = 14;
  // ~42px per item → ~8 visible on a 360px screen, rest scrollable
  static const double _itemWidth = 42.0;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Scroll to the end (today) after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _onDayTap(DateTime date, bool hasWorkout, bool isRestDay) async {
    // Only allow toggling rest on past/today days without a workout
    if (hasWorkout) return;
    final isoDate = _isoDate(date);
    final label = isRestDay ? 'Remover descanso?' : 'Marcar como descanso?';
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _RestDaySheet(date: date, label: label),
    );
    if (confirm == true && mounted) {
      ref.read(restDayToggleProvider(isoDate).future);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutDates = ref.watch(workoutCalendarDatesProvider);
    final restDates = ref.watch(restDaysProvider);
    final theme = Theme.of(context);
    final today = DateTime.now();
    // weekday: 1=Mon..7=Sun  →  Sunday is 7, mapped to index 0 below
    const dayLabels = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

    return SizedBox(
      height: 64,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _days,
        itemExtent: _itemWidth,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, i) {
          final dayOffset = (_days - 1) - i;
          final date = today.subtract(Duration(days: dayOffset));
          final isoDate = _isoDate(date);
          final isToday = dayOffset == 0;
          final hasWorkout = workoutDates.contains(isoDate);
          final isRest = restDates.contains(isoDate);

          final Color circleColor = isToday
              ? AppColors.primaryLight
              : hasWorkout
              ? AppColors.success
              : isRest
              ? AppColors.warning
              : Colors.transparent;

          final Color labelColor = isToday
              ? AppColors.primaryLight
              : theme.colorScheme.onSurface.withValues(alpha: 0.45);

          final Color numColor = (isToday || hasWorkout || isRest)
              ? Colors.white
              : theme.colorScheme.onSurface.withValues(alpha: 0.75);

          return GestureDetector(
            onTap: () => _onDayTap(date, hasWorkout, isRest),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayLabels[date.weekday % 7],
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                    border: !isToday && !hasWorkout && !isRest
                        ? Border.all(
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.15,
                            ),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: numColor,
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RestDaySheet extends StatelessWidget {
  final DateTime date;
  final String label;

  const _RestDaySheet({required this.date, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const months = [
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
    final dateStr = '${date.day} de ${months[date.month - 1]}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(dateStr, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
