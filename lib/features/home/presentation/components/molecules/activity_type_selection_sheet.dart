import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iron_log/features/workout_day/data/providers/create_activity_provider.dart';

/// Modal que oferece três opções de atividade: Treino, Cardio e Descanso
/// Apresentado quando usuário clica em um dia vazio do calendário
class ActivityTypeSelectionSheet extends ConsumerWidget {
  final DateTime selectedDate;

  const ActivityTypeSelectionSheet({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título
          Text(
            'O que deseja fazer?',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Botão: Treino (Musculação)
          _ActivityButton(
            icon: Icons.fitness_center,
            iconColor: Colors.green,
            title: 'Treino',
            subtitle: 'Musculação com séries e exercícios',
            onPressed: () {
              Navigator.pop(context);
              // Navegar para workout creation
              context.push(
                '/workout-day',
                extra: {'date': selectedDate, 'type': 'training'},
              );
            },
          ),
          const SizedBox(height: 12),

          // Botão: Cardio
          _ActivityButton(
            icon: Icons.directions_run,
            iconColor: Colors.orange,
            title: 'Cardio',
            subtitle: 'Corrida, bicicleta, natação...',
            onPressed: () {
              Navigator.pop(context);
              // Navegar para cardio creation
              context.push('/cardio-creation', extra: {'date': selectedDate});
            },
          ),
          const SizedBox(height: 12),

          // Botão: Descanso
          _ActivityButton(
            icon: Icons.hotel,
            iconColor: Colors.blue,
            title: 'Descanso',
            subtitle: 'Marcar como dia de recuperação',
            onPressed: () {
              Navigator.pop(context);
              _confirmRest(context, ref, selectedDate);
            },
            isOutlined: true,
          ),
          const SizedBox(height: 16),

          // Botão Cancelar
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Confirma marcação de descanso e synca com backend
  void _confirmRest(BuildContext context, WidgetRef ref, DateTime date) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marcar como Descanso?'),
        content: Text(
          'Você deseja marcar ${_formatDate(date)} como dia de descanso?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Fecha dialog

              try {
                final dateStr = date.toIso8601String().split('T')[0];

                // Criar DTO para rest
                final dto = CreateActivityDto(type: 'rest', date: dateStr);

                // Chamar backend
                final result = await ref.read(
                  createActivityProvider(dto).future,
                );

                if (context.mounted) {
                  Navigator.pop(context); // Fecha modal
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '✅ Descanso marcado para ${_formatDate(date)}',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Erro ao marcar descanso: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final monthNames = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    final dayName = [
      'seg',
      'ter',
      'qua',
      'qui',
      'sex',
      'sab',
      'dom',
    ][date.weekday - 1];
    return '$dayName, ${date.day} de ${monthNames[date.month - 1]}';
  }
}

/// Botão customizado para cada tipo de atividade
class _ActivityButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;
  final bool isOutlined;

  const _ActivityButton({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _buildContent(),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: Colors.grey[100],
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
