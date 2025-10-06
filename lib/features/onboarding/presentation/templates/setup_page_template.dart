import 'package:flutter/material.dart';
import 'package:iron_log/features/onboarding/presentation/molecules/step_header.dart';
import '../atoms/primary_button.dart';

class SetupPageTemplate extends StatelessWidget {
  final String title;
  final int step;
  final int totalSteps;
  final Widget body;
  final VoidCallback onContinue;
  final bool canContinue;
  final String? primaryButtonText;

  const SetupPageTemplate({
    super.key,
    required this.title,
    required this.step,
    required this.totalSteps,
    required this.body,
    required this.onContinue,
    required this.canContinue,
    this.primaryButtonText,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: StepHeader(title: title, step: step, totalSteps: totalSteps),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20),
        child: body,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(26, 12, 26, 30),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
          ),
        ),
        child: PrimaryButton(
          enabled: canContinue,
          onPressed: canContinue ? onContinue : null,
          text: primaryButtonText ?? "Continuar",
        ),
      ),
    );
  }
}
