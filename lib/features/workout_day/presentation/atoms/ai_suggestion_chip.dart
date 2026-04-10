import 'package:flutter/material.dart';

class AiSuggestionChip extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onTap;

  const AiSuggestionChip({super.key, this.isLoading = false, this.onTap});

  static const _purple = Color(0xFF7B1FA2);
  static const _lightPurple = Color(0xFFF3E5F5);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _lightPurple,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _purple, width: 1),
        ),
        child: isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(_purple),
                ),
              )
            : const Text(
                '✦ IA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _purple,
                ),
              ),
      ),
    );
  }
}
