import 'package:flutter/material.dart';

class WorkoutNameField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;

  const WorkoutNameField({
    super.key,
    required this.controller,
    this.label = 'Nome do treino',
    this.hintText = 'Ex: Push A, Pull B, Legs...',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor, insira um nome para o treino';
            }
            return null;
          },
        ),
      ],
    );
  }
}
