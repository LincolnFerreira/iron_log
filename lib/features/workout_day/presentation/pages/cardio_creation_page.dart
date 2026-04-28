import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/create_activity_provider.dart';

/// Página para criação rápida de cardio
/// Permite seleção de tipo, duração, intensidade e notas
class CardioCreationPage extends ConsumerStatefulWidget {
  final DateTime? initialDate;

  const CardioCreationPage({super.key, this.initialDate});

  @override
  ConsumerState<CardioCreationPage> createState() => _CardioCreationPageState();
}

class _CardioCreationPageState extends ConsumerState<CardioCreationPage> {
  late DateTime selectedDate;
  String? cardioType = 'running';
  int durationMinutes = 30;
  String intensity = 'moderate';
  final TextEditingController notesController = TextEditingController();
  bool isLoading = false;

  final List<String> cardioTypes = [
    'running',
    'cycling',
    'walking',
    'swimming',
    'elliptical',
    'rowing',
    'climbing',
  ];

  final List<String> intensities = ['low', 'moderate', 'high'];

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  Future<void> _saveCardio() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final dateStr = selectedDate.toIso8601String().split('T')[0];

      // Criar DTO para enviar ao backend
      final dto = CreateActivityDto(
        type: 'cardio',
        cardioType: cardioType,
        intensity: intensity,
        duration: durationMinutes * 60, // converter para segundos
        notes: notesController.text.isEmpty ? null : notesController.text,
        date: dateStr,
      );

      // Chamar backend via provider
      final result = await ref.read(createActivityProvider(dto).future);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Cardio ($cardioType) registrado com sucesso! Duration: ${durationMinutes}min',
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Voltar para home
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) context.pop();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro ao salvar cardio: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Cardio'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data
            _buildDateSection(),
            const SizedBox(height: 24),

            // Tipo de Cardio
            _buildCardioTypeSection(),
            const SizedBox(height: 24),

            // Duração
            _buildDurationSection(),
            const SizedBox(height: 24),

            // Intensidade
            _buildIntensitySection(),
            const SizedBox(height: 24),

            // Notas
            _buildNotesSection(),
            const SizedBox(height: 32),

            // Botão Salvar
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : _saveCardio,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar Cardio'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Data', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now(),
            );
            if (picked != null && mounted) {
              setState(() => selectedDate = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 12),
                Text(
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardioTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tipo de Cardio', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: cardioType,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          items: cardioTypes
              .map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(_formatCardioType(type)),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() => cardioType = value);
          },
        ),
      ],
    );
  }

  Widget _buildDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Duração', style: Theme.of(context).textTheme.labelLarge),
            Text(
              '$durationMinutes min',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: durationMinutes.toDouble(),
          min: 5,
          max: 180,
          divisions: 35,
          label: '$durationMinutes min',
          onChanged: (value) {
            setState(() => durationMinutes = value.toInt());
          },
        ),
      ],
    );
  }

  Widget _buildIntensitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Intensidade', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _IntensityButton(
              label: 'Leve',
              value: 'low',
              selected: intensity == 'low',
              color: Colors.green,
              onTap: () => setState(() => intensity = 'low'),
            ),
            _IntensityButton(
              label: 'Moderada',
              value: 'moderate',
              selected: intensity == 'moderate',
              color: Colors.orange,
              onTap: () => setState(() => intensity = 'moderate'),
            ),
            _IntensityButton(
              label: 'Alta',
              value: 'high',
              selected: intensity == 'high',
              color: Colors.red,
              onTap: () => setState(() => intensity = 'high'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notas (opcional)', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        TextField(
          controller: notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Adicionar notas sobre a atividade...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  String _formatCardioType(String type) {
    final labels = {
      'running': '🏃 Corrida',
      'cycling': '🚴 Bicicleta',
      'walking': '🚶 Caminhada',
      'swimming': '🏊 Natação',
      'elliptical': '⏳ Elíptica',
      'rowing': '🚣 Remo',
      'climbing': '🧗 Escalada',
    };
    return labels[type] ?? type;
  }
}

/// Botão de intensidade customizado
class _IntensityButton extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _IntensityButton({
    required this.label,
    required this.value,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.2) : Colors.grey[100],
          border: Border.all(
            color: selected ? color : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected ? color : Colors.grey[600],
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
