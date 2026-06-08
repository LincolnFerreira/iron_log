import 'package:flutter/material.dart';
import 'package:iron_log/features/workout_day/presentation/exercise_card_styles.dart';
import 'package:iron_log/features/workout_day/presentation/workout_test_keys.dart';

/// Configuração inicial de cluster set antes de aplicar a técnica.
class ClusterConfig {
  final int miniSetCount;
  final int repsPerMiniSet;
  final int restBetweenMiniSets;

  const ClusterConfig({
    required this.miniSetCount,
    required this.repsPerMiniSet,
    required this.restBetweenMiniSets,
  });

  String preview(String weight) {
    final reps = List.filled(miniSetCount, repsPerMiniSet).join('+');
    final load = weight.isNotEmpty ? '$weight · ' : '';
    return '$load$reps';
  }
}

/// Bottom sheet para definir mini-séries, reps e descanso intra-set.
Future<ClusterConfig?> showClusterConfigSheet(
  BuildContext context, {
  required String weight,
  required String reps,
}) {
  return showModalBottomSheet<ClusterConfig>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _ClusterConfigSheet(
      weight: weight,
      reps: reps,
    ),
  );
}

class _ClusterConfigSheet extends StatefulWidget {
  final String weight;
  final String reps;

  const _ClusterConfigSheet({
    required this.weight,
    required this.reps,
  });

  @override
  State<_ClusterConfigSheet> createState() => _ClusterConfigSheetState();
}

class _ClusterConfigSheetState extends State<_ClusterConfigSheet> {
  static const _restOptions = [15, 20, 30, 45];

  late int _miniSetCount;
  late int _repsPerMiniSet;
  late int _restSeconds;

  @override
  void initState() {
    super.initState();
    final parsedReps = int.tryParse(
          RegExp(r'\d+').firstMatch(widget.reps)?.group(0) ?? '',
        ) ??
        2;
    _repsPerMiniSet = parsedReps <= 3 ? parsedReps.clamp(1, 5) : 2;
    _miniSetCount = 3;
    _restSeconds = 20;
  }

  void _confirm() {
    Navigator.pop(
      context,
      ClusterConfig(
        miniSetCount: _miniSetCount,
        repsPerMiniSet: _repsPerMiniSet,
        restBetweenMiniSets: _restSeconds,
      ),
    );
  }

  Widget _stepperRow({
    required String label,
    required String subtitle,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ExerciseCardStyles.labelMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: ExerciseCardStyles.accent,
          ),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline),
            color: ExerciseCardStyles.accent,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = ClusterConfig(
      miniSetCount: _miniSetCount,
      repsPerMiniSet: _repsPerMiniSet,
      restBetweenMiniSets: _restSeconds,
    );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Cluster Set',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Text(
                'Uma série dividida em mini-séries com descanso curto entre elas '
                '(ex.: 2+2+2 com ~20s).',
                style: TextStyle(
                  fontSize: 13,
                  color: ExerciseCardStyles.labelMuted,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _stepperRow(
              label: 'Mini-séries',
              subtitle: 'Quantos clusters nesta série',
              value: _miniSetCount,
              min: 2,
              max: 6,
              onChanged: (v) => setState(() => _miniSetCount = v),
            ),
            _stepperRow(
              label: 'Reps por cluster',
              subtitle: 'Repetições em cada mini-série',
              value: _repsPerMiniSet,
              min: 1,
              max: 5,
              onChanged: (v) => setState(() => _repsPerMiniSet = v),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Descanso entre clusters',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _restOptions.map((seconds) {
                      final selected = _restSeconds == seconds;
                      return ChoiceChip(
                        label: Text('${seconds}s'),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _restSeconds = seconds),
                        selectedColor: ExerciseCardStyles.accentChipBg,
                        labelStyle: TextStyle(
                          color: selected
                              ? ExerciseCardStyles.accent
                              : ExerciseCardStyles.textPrimary,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: ExerciseCardStyles.techniqueBlockDecoration(),
                child: Text(
                  config.preview(widget.weight),
                  textAlign: TextAlign.center,
                  style: ExerciseCardStyles.techniqueHeaderStyle.copyWith(
                    fontSize: 13,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: FilledButton(
                key: WorkoutTestKeys.clusterApply,
                onPressed: _confirm,
                style: FilledButton.styleFrom(
                  backgroundColor: ExerciseCardStyles.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Aplicar cluster set'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
