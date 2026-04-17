import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/home/data/models/active_rest_dto.dart';
import 'package:iron_log/features/home/state/home_provider.dart';

class RestDayCreationSheet extends ConsumerStatefulWidget {
  final String date;
  final Function()? onCreated;

  const RestDayCreationSheet({super.key, required this.date, this.onCreated});

  @override
  ConsumerState<RestDayCreationSheet> createState() =>
      _RestDayCreationSheetState();
}

class _RestDayCreationSheetState extends ConsumerState<RestDayCreationSheet> {
  String _selectedType = 'rest'; // 'rest' or 'active_rest'
  String? _selectedActivityType;
  int? _duration = 30;
  String? _selectedIntensity;
  String? _notes;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Registrar para ${_formatDate(widget.date)}',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Type selection
            Text(
              'Tipo de atividade',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildTypeSelector(),
            const SizedBox(height: 24),

            // Activity type (only if active rest)
            if (_selectedType == 'active_rest') ...[
              Text(
                'Qual atividade?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _buildActivityTypeGrid(),
              const SizedBox(height: 24),

              // Duration
              Text(
                'Duração: ${_duration ?? 30} minutos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Slider(
                value: (_duration ?? 30).toDouble(),
                min: 15,
                max: 180,
                divisions: (180 - 15) ~/ 5,
                label: '${_duration ?? 30} min',
                onChanged: (value) {
                  setState(() => _duration = value.toInt());
                },
              ),
              const SizedBox(height: 24),

              // Intensity
              Text(
                'Intensidade (opcional)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _buildIntensitySelector(),
              const SizedBox(height: 24),
            ],

            // Notes
            TextField(
              decoration: InputDecoration(
                labelText: 'Notas (opcional)',
                hintText: 'Ex: Recuperação ativa...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
              onChanged: (value) => _notes = value,
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleSave,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(_isLoading ? 'Salvando...' : 'Salvar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      children: [
        _buildTypeCard(value: 'rest', label: 'Descanso Passivo', icon: '😴'),
        const SizedBox(height: 12),
        _buildTypeCard(
          value: 'active_rest',
          label: 'Descanso Ativo',
          icon: '✨',
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required String value,
    required String label,
    required String icon,
  }) {
    final isSelected = _selectedType == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Theme.of(context).primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTypeGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: activityTypes.map((activity) {
        final isSelected = _selectedActivityType == activity.id;
        return GestureDetector(
          onTap: () => setState(() => _selectedActivityType = activity.id),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.transparent,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(activity.icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 8),
                Text(
                  activity.label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIntensitySelector() {
    return Wrap(
      spacing: 12,
      children: intensityLevels.map((tuple) {
        final (id, label) = tuple;
        final isSelected = _selectedIntensity == id;
        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            setState(() => _selectedIntensity = selected ? id : null);
          },
        );
      }).toList(),
    );
  }

  Future<void> _handleSave() async {
    if (_selectedType == 'active_rest' && _selectedActivityType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um tipo de atividade'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dto = CreateRestDayDto(
        date: widget.date,
        type: _selectedType,
        activityType: _selectedActivityType,
        duration: _duration,
        intensity: _selectedIntensity,
        note: _notes,
      );

      await ref.read(createRestDayProvider(dto).future);

      if (mounted) {
        Navigator.pop(context);
        widget.onCreated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Descanso registrado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    final months = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    return '${date.day} de ${months[date.month - 1]}';
  }
}
