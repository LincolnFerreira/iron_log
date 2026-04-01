import 'package:flutter/material.dart';
import 'package:iron_log/core/api/endpoints.dart';
import 'package:iron_log/core/app_colors.dart';
import 'package:iron_log/core/services/auth_service.dart';
import '../../domain/entities/exercise_muscle_group.dart';
import '../../domain/entities/search_exercise.dart';

class CreateExerciseModal extends StatefulWidget {
  final String initialName;

  const CreateExerciseModal({super.key, this.initialName = ''});

  @override
  State<CreateExerciseModal> createState() => _CreateExerciseModalState();
}

class _CreateExerciseModalState extends State<CreateExerciseModal> {
  final _nameController = TextEditingController();
  final _equipmentController = TextEditingController();

  List<String> _muscleGroups = [];
  String? _selectedMuscle;
  String? _selectedEquipment;
  bool _loadingMuscles = true;
  bool _submitting = false;
  String? _error;

  static const _equipmentPresets = [
    'Barra',
    'Haltere',
    'Máquina',
    'Cabo',
    'Anilha',
    'Elástico',
    'Bodyweight',
    'Smith',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName;
    _fetchMuscleGroups();
  }

  Future<void> _fetchMuscleGroups() async {
    try {
      final response = await AuthService().get(ApiEndpoints.exerciseBrowse);
      final data = response.data as List<dynamic>;
      final groups = data
          .map((e) => ExerciseMuscleGroup.fromJson(e as Map<String, dynamic>))
          .map((g) => g.muscle)
          .where((m) => m.isNotEmpty)
          .toList();
      if (mounted) {
        setState(() {
          _muscleGroups = groups;
          _loadingMuscles = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingMuscles = false);
      }
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Informe o nome do exercício');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final equipment = _equipmentController.text.trim();
      final response = await AuthService().post(
        ApiEndpoints.exerciseCreate,
        data: {
          'name': name,
          if (_selectedMuscle != null) 'primaryMuscle': _selectedMuscle,
          if (equipment.isNotEmpty) 'equipment': equipment,
        },
      );

      final created = SearchExercise.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (mounted) Navigator.of(context).pop(created);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao criar exercício. Tente novamente.';
          _submitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _equipmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Novo exercício',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Será adicionado à base da comunidade',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),

          // Nome
          TextField(
            controller: _nameController,
            autofocus: widget.initialName.isEmpty,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nome do exercício *',
              hintText: 'Ex: Supino reto',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          // Grupo muscular
          Text(
            'Grupo muscular',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (_loadingMuscles)
            const SizedBox(
              height: 36,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_muscleGroups.isEmpty)
            TextField(
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Ex: Peitoral',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(
                () => _selectedMuscle = v.trim().isEmpty ? null : v.trim(),
              ),
            )
          else
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _muscleGroups.map((muscle) {
                  final selected = _selectedMuscle == muscle;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(muscle),
                      selected: selected,
                      selectedColor: AppColors.primaryLight.withValues(
                        alpha: 0.2,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedMuscle = selected ? null : muscle;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 20),

          // Equipamento
          Text(
            'Equipamento',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _equipmentPresets.map((equipment) {
                final selected = _selectedEquipment == equipment;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(equipment),
                    selected: selected,
                    selectedColor: AppColors.primaryLight.withValues(
                      alpha: 0.2,
                    ),
                    onSelected: (_) {
                      final newValue = selected ? null : equipment;
                      setState(() => _selectedEquipment = newValue);
                      _equipmentController.text = newValue ?? '';
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _equipmentController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Ou descreva o equipamento',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              // Clear preset selection if user types something custom
              if (_selectedEquipment != null && v != _selectedEquipment) {
                setState(() => _selectedEquipment = null);
              }
            },
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
            ),
          ],

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Criar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
