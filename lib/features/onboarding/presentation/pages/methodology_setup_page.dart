// features/onboarding/presentation/pages/division_setup_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/features/onboarding/presentation/controllers/division_setup_controller.dart';
import 'package:iron_log/features/onboarding/presentation/organisms/methodology_setup_content.dart';
import 'package:iron_log/features/onboarding/presentation/templates/setup_page_template.dart';

class MethodologySetupPage extends ConsumerWidget {
  const MethodologySetupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(divisionSetupControllerProvider);
    final controller = ref.read(divisionSetupControllerProvider.notifier);

    return SetupPageTemplate(
      title: 'Metodologia padrão',
      step: 1,
      totalSteps: 3,
      canContinue: state.canContinueMethod,
      onContinue: () {
        // ação de continuar
      },
      body: MethodologySetupContent(
        selectedMethod: state.selectedMethod,
        onMethodChanged: controller.selectMethod,
      ),
    );
  }
}
