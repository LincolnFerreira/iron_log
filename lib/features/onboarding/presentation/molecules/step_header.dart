import 'package:flutter/material.dart';

class StepHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final int step;
  final int totalSteps;

  const StepHeader({
    super.key,
    required this.title,
    required this.step,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(32),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        ),
      ),
    );
  }

  @override
  // TODO: implement preferredSize
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 32);
}
