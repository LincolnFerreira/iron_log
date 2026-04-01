import 'package:flutter/material.dart';

/// Footer com botão de ação - Voltar ao início
class CtaFooter extends StatelessWidget {
  final VoidCallback onBackPressed;

  const CtaFooter({super.key, required this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onBackPressed,
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Voltar ao Início'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ),
    );
  }
}
