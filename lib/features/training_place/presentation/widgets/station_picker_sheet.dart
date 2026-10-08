import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/training_place/domain/entities/exercise_station.dart';
import 'package:iron_log/features/training_place/training_place_providers.dart';

class StationPickerSheet extends ConsumerStatefulWidget {
  const StationPickerSheet({
    super.key,
    required this.exerciseId,
    this.gymId,
    this.includeUnscoped = false,
  });

  final String exerciseId;
  final String? gymId;
  final bool includeUnscoped;

  @override
  ConsumerState<StationPickerSheet> createState() => _StationPickerSheetState();
}

class _StationPickerSheetState extends ConsumerState<StationPickerSheet> {
  final _nickname = TextEditingController();
  final _brand = TextEditingController();
  List<ExerciseStation> _stations = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nickname.dispose();
    _brand.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final stations = await ref.read(trainingPlaceRepositoryProvider).listStations(
          exerciseId: widget.exerciseId,
          gymId: widget.gymId,
          includeUnscoped: widget.includeUnscoped,
          limit: 3,
        );
    if (!mounted) return;
    setState(() {
      _stations = stations;
      _loading = false;
    });
  }

  Future<void> _create() async {
    final nickname = _nickname.text.trim();
    if (nickname.isEmpty || nickname.length > 40) {
      setState(() => _error = 'Apelido de 1 a 40 caracteres');
      return;
    }
    final created = await ref.read(trainingPlaceRepositoryProvider).createStation(
          exerciseId: widget.exerciseId,
          nickname: nickname,
          gymId: widget.gymId,
          brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
        );
    if (!mounted) return;
    Navigator.pop(context, created);
  }

  Future<void> _rename(ExerciseStation station) async {
    final controller = TextEditingController(text: station.nickname);
    final next = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renomear máquina'),
        content: TextField(
          controller: controller,
          maxLength: 40,
          decoration: const InputDecoration(labelText: 'Apelido'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (next == null || next.isEmpty || !mounted) return;
    final renamed = await ref
        .read(trainingPlaceRepositoryProvider)
        .renameStation(station.id, next);
    if (!mounted) return;
    Navigator.pop(context, renamed);
  }

  Future<void> _archive(ExerciseStation station) async {
    await ref.read(trainingPlaceRepositoryProvider).archiveStation(station.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Qual máquina?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const LinearProgressIndicator()
            else
              for (final station in _stations)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(station.nickname),
                  subtitle: station.brand == null ? null : Text(station.brand!),
                  onTap: () => Navigator.pop(context, station),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'rename') _rename(station);
                      if (value == 'hide') _archive(station);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'rename', child: Text('Renomear')),
                      PopupMenuItem(value: 'hide', child: Text('Ocultar')),
                    ],
                  ),
                ),
            TextField(
              controller: _nickname,
              maxLength: 40,
              decoration: const InputDecoration(
                labelText: 'Outra máquina',
                hintText: 'preta da ponta',
              ),
            ),
            TextField(
              controller: _brand,
              maxLength: 60,
              decoration: const InputDecoration(
                labelText: 'Marca (opcional)',
              ),
            ),
            if (_error != null)
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 8),
            FilledButton(onPressed: _create, child: const Text('Usar esta máquina')),
          ],
        ),
      ),
    );
  }
}
