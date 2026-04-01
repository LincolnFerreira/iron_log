import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/onboarding/controller/division_setup_controller.dart';
import 'package:iron_log/features/onboarding/model/division_type.dart';
import 'package:iron_log/features/onboarding/presentation/atoms/primary_text.dart';
import 'package:iron_log/features/onboarding/presentation/molecules/division_card.dart';

class DivisionOrganism extends ConsumerWidget {
  const DivisionOrganism({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(divisionSetupControllerProvider);
    final controller = ref.read(divisionSetupControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const PrimaryText('Escolha sua Divisão', isTitle: true),
          const SizedBox(height: 16),
          ...DivisionType.values.map(
            (type) => DivisionCard(
              type: type,
              selected: state.selectedDivision == type,
              onTap: () {
                controller.selectDivision(type);
              },
            ),
          ),
          const SizedBox(height: 24),
          const PrimaryText('Frequência Semanal', isTitle: true),
          Slider(
            overlayColor: WidgetStateProperty.all<Color>(
              Colors.grey.withOpacity(0.2),
            ),
            thumbColor: Colors.blue,
            secondaryActiveColor: Colors.blue,
            inactiveColor: Colors.grey,
            value: state.frequency.toDouble(),
            min: 1,
            max: 7,
            divisions: 7,
            label: state.frequency.toString(),
            onChanged: (value) {
              controller.setFrequency(value.round());
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [1, 3, 5, 7].map((num) => Text('$num')).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
