import 'package:flutter/material.dart';
import 'package:iron_log/core/app_colors.dart';

class SessionSectionTitle extends StatelessWidget {
  final String text;
  const SessionSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondaryLight,
      ),
    );
  }
}
