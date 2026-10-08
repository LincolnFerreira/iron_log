import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/training_place/domain/entities/gym.dart';
import 'package:iron_log/features/training_place/presentation/widgets/gym_attach_sheet.dart';
import 'package:iron_log/features/training_place/training_place_providers.dart';

class GymContextChip extends ConsumerStatefulWidget {
  const GymContextChip({super.key});

  @override
  ConsumerState<GymContextChip> createState() => _GymContextChipState();
}

class _GymContextChipState extends ConsumerState<GymContextChip> {
  List<Gym> _gyms = const [];
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(trainingPlaceRepositoryProvider);
    final gyms = await repo.listGyms();
    final selected = await repo.gymIdForWorkout();
    if (!mounted) return;
    setState(() {
      _gyms = gyms;
      _selectedId = selected;
    });
  }

  Future<void> _add() async {
    final nameController = TextEditingController();
    final attach = await showDialog<bool>(
      context: context,
      builder: (context) => GymAttachSheet(nameController: nameController),
    );
    final name = nameController.text.trim();
    nameController.dispose();
    if (attach == null || name.isEmpty) return;
    await ref.read(trainingPlaceRepositoryProvider).createGym(
          name,
          attachUnscopedStations: attach && _gyms.isEmpty,
        );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_gyms.length < 2) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: _add,
          child: Text(_gyms.length == 1 ? _gyms.first.name : 'Academia'),
        ),
      );
    }
    final selected = _gyms.where((g) => g.id == _selectedId).firstOrNull;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          ActionChip(
            label: Text(selected?.name ?? 'Academia'),
            onPressed: () async {
              final picked = await showModalBottomSheet<String>(
                context: context,
                builder: (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final gym in _gyms)
                        ListTile(
                          title: Text(gym.name),
                          onTap: () => Navigator.pop(context, gym.id),
                        ),
                      ListTile(
                        leading: const Icon(Icons.add),
                        title: const Text('Nova academia'),
                        onTap: () => Navigator.pop(context, '__new__'),
                      ),
                    ],
                  ),
                ),
              );
              if (picked == '__new__') {
                await _add();
                return;
              }
              if (picked == null) return;
              await ref.read(trainingPlaceRepositoryProvider).touchGym(picked);
              await _load();
            },
          ),
        ],
      ),
    );
  }
}
