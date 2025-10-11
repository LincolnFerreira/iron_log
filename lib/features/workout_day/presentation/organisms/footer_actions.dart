import 'package:flutter/material.dart';
import '../atoms/custom_button.dart';

class FooterActions extends StatelessWidget {
  final VoidCallback? onSaveRoutine;
  final VoidCallback? onStartWorkout;
  final bool isLoading;

  const FooterActions({
    super.key,
    this.onSaveRoutine,
    this.onStartWorkout,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'Salvar Rotina',
              icon: Icons.save,
              backgroundColor: Colors.grey.shade800,
              onPressed: onSaveRoutine,
              isLoading: isLoading,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CustomButton(
              text: 'Dia de Treino',
              icon: Icons.play_arrow,
              backgroundColor: Colors.blue,
              onPressed: onStartWorkout,
              isLoading: isLoading,
            ),
          ),
        ],
      ),
    );
  }
}
