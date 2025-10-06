// features/onboarding/presentation/pages/frequency_setup_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iron_log/features/onboarding/controller/division_setup_controller.dart';
import '../templates/setup_page_template.dart';
import '../organisms/division_organism.dart';

class FrequencySetupPage extends ConsumerWidget {
  const FrequencySetupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canContinue = ref.watch(
      divisionSetupControllerProvider.select(
        (state) =>
            state.frequency > 0, // ou apenas `true` se não precisa validar
      ),
    );

    return SetupPageTemplate(
      title: 'Configuração Inicial',
      step: 1,
      totalSteps: 3,
      onContinue: () {
        context.push('/home'); // vai para próxima página
      },
      canContinue: canContinue,
      body: const DivisionOrganism(),
      primaryButtonText: "Próximo",
    );
  }
}
