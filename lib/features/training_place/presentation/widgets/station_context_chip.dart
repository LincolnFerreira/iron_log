import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/training_place/domain/entities/exercise_station.dart';
import 'package:iron_log/features/training_place/presentation/widgets/station_picker_sheet.dart';
import 'package:iron_log/features/training_place/training_place_providers.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_exercise.dart';

class StationContextChip extends ConsumerStatefulWidget {
  const StationContextChip({
    super.key,
    required this.exercise,
    required this.onStation,
  });

  final WorkoutExercise exercise;
  final void Function(String? stationId, String? stationNickname) onStation;

  @override
  ConsumerState<StationContextChip> createState() => _StationContextChipState();
}

class _StationContextChipState extends ConsumerState<StationContextChip> {
  var _preselected = false;

  @override
  void initState() {
    super.initState();
    if (widget.exercise.stationId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _preselect());
    }
  }

  Future<void> _preselect() async {
    if (_preselected || widget.exercise.stationId != null) return;
    _preselected = true;
    final repo = ref.read(trainingPlaceRepositoryProvider);
    final gyms = await repo.listGyms();
    final gymId = gyms.length == 1
        ? gyms.first.id
        : gyms.length > 1
            ? await repo.gymIdForWorkout()
            : null;
    final stations = await repo.listStations(
      exerciseId: widget.exercise.movementId,
      gymId: gymId,
      includeUnscoped: gyms.length <= 1,
      limit: 1,
    );
    if (!mounted || stations.isEmpty || widget.exercise.stationId != null) {
      return;
    }
    final station = stations.first;
    widget.onStation(station.id, station.nickname);
  }

  Future<void> _open() async {
    final repo = ref.read(trainingPlaceRepositoryProvider);
    final gyms = await repo.listGyms();
    final gymId = gyms.length == 1
        ? gyms.first.id
        : gyms.length > 1
            ? await repo.gymIdForWorkout()
            : null;
    if (!mounted) return;
    final picked = await showModalBottomSheet<ExerciseStation?>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StationPickerSheet(
        exerciseId: widget.exercise.movementId,
        gymId: gymId,
        includeUnscoped: gyms.length <= 1,
      ),
    );
    if (picked == null) return;
    await repo.touchStation(picked.id);
    widget.onStation(picked.id, picked.nickname);
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.exercise.stationNickname ??
        (widget.exercise.stationId == null ? 'Escolher máquina' : 'Máquina');
    return GestureDetector(
      onTap: _open,
      onLongPress: widget.exercise.stationId == null
          ? null
          : () => widget.onStation(null, null),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
