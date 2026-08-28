import 'package:flutter/material.dart';
import 'package:iron_log/features/onboarding/presentation/atoms/circular_icon.dart';
import 'package:iron_log/features/onboarding/presentation/atoms/primary_text.dart';
import 'package:iron_log/features/onboarding/presentation/atoms/section_description_text.dart';
import 'package:iron_log/features/onboarding/presentation/organisms/metodology_list.dart';

class MethodologySetupContent extends StatelessWidget {
  final int? selectedMethod;
  final ValueChanged<int?> onMethodChanged;

  const MethodologySetupContent({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const CircularIcon(icon: Icons.add_home_sharp),
          const SizedBox(height: 8),
          const PrimaryText('Método de treino', isTitle: true),
          const SizedBox(height: 8),
          const SectionDescriptionText(
            'Escolha o método de progressão que melhor se adapta ao seu estilo de treino',
          ),
          const SizedBox(height: 16),
          MetodologyList(
            groupValue: selectedMethod,
            onChanged: onMethodChanged,
          ),
        ],
      ),
    );
  }
}
